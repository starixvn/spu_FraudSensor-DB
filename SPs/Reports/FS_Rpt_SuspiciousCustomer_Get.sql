ALTER PROCEDURE [dbo].[FS_Rpt_SuspiciousCustomer_Get] 
		@FromDate					DATETIME
	,	@ToDate						DATETIME
	,	@Username					NVARCHAR(50) = NULL	
	,	@FraudCaseId				TINYINT = 0
	,	@IsVerified					BIT = NULL
	,	@IsDelinquent				BIT = NULL
	,	@IsDirty					BIT = NULL
	,	@IsHedge					BIT = NULL
	,	@AssigneeId					INT = NULL
	,	@Environment				INT = 3
	,	@IsShowSpecialCurrencies	BIT = 0
	,	@PageSize					INT	= 50
	,	@PageIndex					INT = 1
	,	@IsExportExcel				BIT	= 0
	,	@TotalItems					INT = 0 OUTPUT
AS
/*
	Created: 20180320@Long
	Task : Suspicious Customers report
	DB: bodb_FraudSensor
	Original:

	Revisions:
		-	20180326@CaseyHuynh: 
			+ Remove "Having Condition on IsVerified value"
			+ Update @AssingeeId = 0 If filter By "All"
			+ Return Assignee Username Instead Of AssigneeId
		- 20181114@Long: Adding View Permission on Special Currencies [Redmine ID: #104707]
		- 20190114@John: Exclude Internal Fraud on Suspicious Customer report and support paging [Redmine ID:#107858]
		- 20190219@John: Update logic Special Currencies, seperate Arbitrage [Redmine ID: #99753]

	Param's Explanation:    
			+ Add Condition for Customer Log GET: cl.LogType = 1
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @RowCount INT, @RowStart INT, @RowEnd INT
	DECLARE @IsInternal BIT = 0;

	IF OBJECT_ID('tempdb..#tmpFraudCases') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudCases;
	END

	CREATE TABLE #tmpFraudCases (
			FraudCaseId			INT
		PRIMARY KEY CLUSTERED (FraudCaseId)
	);

	IF OBJECT_ID('tempdb..#tmpCustomerSuspiciousInfo') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomerSuspiciousInfo;
	END

	CREATE TABLE #tmpCustomerSuspiciousInfo (
			[CustId]			INT
		,	[HasNote]			BIT
		,	[TotalViolation]	INT
		,	[ViolatedCases]		INT
		,	[BetCount]			INT		
		,	[IsDelinquent]		BIT
		,	[IsDirty]			BIT
		,	[IsHedge]			BIT
		,	[IsVerified]		BIT
	);

	CREATE CLUSTERED INDEX #CIX_tmpCustomerSuspiciousInfo_CustId ON #tmpCustomerSuspiciousInfo (
			CustId			ASC
	);

	IF OBJECT_ID('tempdb..#tmpCustomerSuspiciousInfoPaging') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomerSuspiciousInfoPaging;
	END

	CREATE TABLE #tmpCustomerSuspiciousInfoPaging (
			[RowIdx]			INT
		,	[CustId]			INT
		,	[Username]			NVARCHAR(50)
		,	[HasNote]			BIT
		,	[IsDelinquent]		BIT
		,	[IsDirty]			BIT
		,	[IsHedge]			BIT
		,	[IsVerified]		BIT
		,	[TotalViolation]	INT
		,	[ViolatedCases]		INT
		,	[BetCount]			INT
		,	[Assignee]			NVARCHAR(50) 
	);

	CREATE CLUSTERED INDEX #CIX_tmpCustomerSuspiciousInfoPaging_RowIdx ON #tmpCustomerSuspiciousInfoPaging (
			RowIdx			ASC
	);

	IF OBJECT_ID('tempdb..#tmpSuspiciousInfo') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSuspiciousInfo;
	END

	CREATE TABLE #tmpSuspiciousInfo (
			[CustId]			INT
		,	[HasNote]			BIT
		,	[TotalViolation]	INT
		,	[ViolatedCases]		INT
		,	[BetCount]			INT
	);

	CREATE CLUSTERED INDEX #CIX_tmpSuspiciousInfo_CustId ON #tmpSuspiciousInfo (
			CustId			ASC
	);

	IF OBJECT_ID('tempdb..#tmpSuspiciousCustomer') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSuspiciousCustomer;
	END

	CREATE TABLE #tmpSuspiciousCustomer (
			[CustId]			INT
		,	[IsDelinquent]		BIT
		,	[IsDirty]			BIT
		,	[IsHedge]			BIT
		,	[IsVerified]		BIT
	);

	CREATE CLUSTERED INDEX #CIX_tmpSuspiciousCustomer_CustId ON #tmpSuspiciousCustomer (
			CustId			ASC
	);

	IF @FraudCaseId = 0
		BEGIN
			INSERT INTO #tmpFraudCases(FraudCaseId)
			SELECT fc.FraudCaseId
			FROM dbo.FraudCase AS fc WITH(NOLOCK)
			WHERE fc.IsTest = (CASE WHEN @Environment = 3 THEN 0 ELSE fc.IsTest END) AND fc.IsInternal = @IsInternal
		END;
	ELSE
		BEGIN
			INSERT INTO #tmpFraudCases(FraudCaseId)
			SELECT fc.FraudCaseId
			FROM dbo.FraudCase AS fc WITH(NOLOCK)
			WHERE fc.FraudCaseId = @FraudCaseId AND fc.IsTest = (CASE WHEN @Environment = 3 THEN 0 ELSE fc.IsTest END) AND fc.IsInternal = @IsInternal
		END;

	INSERT INTO #tmpSuspiciousInfo ([CustId], [HasNote], [TotalViolation], [ViolatedCases], [BetCount])
	SELECT	[CustId]	= si.custid
		,	[HasNote]			= (CASE WHEN (
												SELECT COUNT(DISTINCT cl.CustId)
												FROM dbo.CustomerLog AS cl WITH (NOLOCK)
												WHERE cl.CustId = si.CustId AND cl.CustLogType = 1
											) > 0
										THEN 1
									ELSE 0
									END)
		,	[TotalViolation]	= SUM(si.ViolationCounter)
		,	[ViolatedCases]		= COUNT(DISTINCT si.FraudCaseId)
		,	[BetCount]			= SUM(si.TicketCounter)
	FROM dbo.SuspiciousInfo si WITH(NOLOCK)
		INNER JOIN #tmpFraudCases fc WITH(NOLOCK) ON fc.FraudCaseId = si.FraudCaseId
	WHERE (si.EventDate BETWEEN @FromDate AND @ToDate)
	GROUP BY si.custid;

	INSERT INTO #tmpSuspiciousCustomer ([CustId], [IsDelinquent] ,[IsDirty], [IsHedge], [IsVerified])
	SELECT	[CustId]	= sc.custid
		,	[IsDelinquent]		= sc.IsDelinquent
		,	[IsDirty]			= sc.IsDirty
		,	[IsHedge]			= sc.IsHedge
		,	[IsVerified]		= sc.IsVerified
	FROM dbo.SuspiciousCustomer sc WITH(NOLOCK)
	WHERE (@IsDelinquent IS NULL OR sc.IsDelinquent = @IsDelinquent)
		AND (@IsHedge IS NULL OR sc.IsHedge = @IsHedge)
		AND (@IsDirty IS NULL OR sc.IsDirty = @IsDirty)
		AND (@IsVerified IS NULL OR sc.IsVerified = @IsVerified)

	INSERT INTO #tmpCustomerSuspiciousInfo ([CustId], [HasNote], [IsDelinquent] ,[IsDirty], [IsHedge], [IsVerified], [TotalViolation], [ViolatedCases], [BetCount])
	SELECT	[CustId]	= si.custid
		,	[HasNote]			= si.HasNote
		,	[IsDelinquent]		= sc.IsDelinquent
		,	[IsDirty]			= sc.IsDirty
		,	[IsHedge]			= sc.IsHedge
		,	[IsVerified]		= sc.IsVerified
		,	[TotalViolation]	= si.[TotalViolation]
		,	[ViolatedCases]		= si.[ViolatedCases]
		,	[BetCount]			= si.[BetCount]
	FROM #tmpSuspiciousCustomer sc WITH(NOLOCK)
		INNER JOIN #tmpSuspiciousInfo si WITH(NOLOCK) ON si.CustId = sc.Custid
	
	INSERT INTO #tmpCustomerSuspiciousInfoPaging ([RowIdx], [CustId], [Username], [HasNote], [IsDelinquent], [IsDirty], [IsHedge], [IsVerified], [TotalViolation], [ViolatedCases], [BetCount], [Assignee])
	SELECT	[RowIdx]			= ROW_NUMBER() OVER (ORDER BY si.IsDirty DESC,	si.TotalViolation DESC,	si.ViolatedCases DESC, si.BetCount DESC, c.username	DESC)
		,	[CustId]			= si.custid
		,	[Username]			= c.username
		,	[HasNote]			= si.HasNote
		,	[IsDelinquent]		= si.IsDelinquent
		,	[IsDirty]			= si.IsDirty
		,	[IsHedge]			= si.IsHedge
		,	[IsVerified]		= si.IsVerified
		,	[TotalViolation]	= si.TotalViolation
		,	[ViolatedCases]		= si.ViolatedCases
		,	[BetCount]			= si.BetCount
		,	[Assignee]			= (SELECT TOP 1 username FROM bodb02.dbo.Customer c WITH(NOLOCK) WHERE c.custid = cma.AssigneeId)
	FROM #tmpCustomerSuspiciousInfo si WITH(NOLOCK)
		INNER JOIN dbo.SuspiciousCustomer c WITH(NOLOCK) ON si.CustId = c.CustId
		LEFT JOIN dbo.CustomerMonitorAssignment AS cma WITH (NOLOCK) ON cma.CustId = si.CustId
	WHERE (ISNULL(cma.AssigneeId,0) = CASE WHEN @AssigneeId IS NULL THEN ISNULL(cma.AssigneeId,0)
									WHEN @AssigneeId = - 1 THEN 0
									WHEN @AssigneeId >=0 THEN @AssigneeId
									END
			)
		AND (@Username IS NULL OR c.username = @Username)		
		AND (@IsShowSpecialCurrencies = 1 OR c.CurrencyId NOT IN (SELECT CurrencyId FROM dbo.SpecialCurrency WITH(NOLOCK)));
	
	SELECT @TotalItems = @@ROWCOUNT
	
	IF @IsExportExcel = 0
	BEGIN
		SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1,
				@RowEnd = @RowStart + @PageSize - 1
	END
	ELSE
	BEGIN
		SELECT  @RowStart = 1,
				@RowEnd = @TotalItems
	END

	SELECT	[CustId]
		,	[Username]
		,	[HasNote]
		,	[IsDelinquent]
		,	[IsDirty]
		,	[IsHedge]
		,	[IsVerified]
		,	[TotalViolation]
		,	[ViolatedCases]
		,	[BetCount]
		,	[Assignee]
	FROM #tmpCustomerSuspiciousInfoPaging WHERE RowIdx BETWEEN @RowStart AND @RowEnd

END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/