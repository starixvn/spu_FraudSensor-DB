SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER PROCEDURE [dbo].[FS_FraudCase_FlaggedAccount_Rule] 
		@MatchIds				VARCHAR(MAX) = NULL
	,	@FlaggedAccountsXML		VARCHAR(MAX)
AS
/*
	Created: 20180308@LONG
	Task : Rule for Flagged Account fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20180321@LONG: Support ViolatiONCounter & TicketCounter [Redmine ID: 92293]
		- 20180406@LONG: Get flagged accounts list directly from FPS's api
		- 20180312@CaseyHuynh: Correct Code Syntax
		- 20181114@Long: Split data in SuspiciousInfo by Currency [Redmine ID: #104707]
		- 20190219@Long: Store more info (Currency & Username) for table SuspiciousCutomers [Redmine ID: 107858]
		- 20190319@Casey.Huynh: Enhance Performance table #tmpFraudTickets [110060]
		- 20190320@Casey.Huynh: Enhance Performance, define PRIMARY KEY in table [110060]
		- 20190410@Casey.Huynh: Implement, update hasscanned = 1 for deleted Matches [111454]

	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	

	DECLARE @CurrentFraudCaseId TINYINT;
	SET @CurrentFraudCaseId = 6; -- Flagged Account	
	DECLARE @idoc INT;
	
	IF OBJECT_ID('tempdb..#tmpFlaggedAccounts') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFlaggedAccounts;
	END
	
	CREATE TABLE #tmpFlaggedAccounts(
			CustId				INT
		,	EvidenceCode		NVARCHAR(50)
		,	EvidenceName		NVARCHAR(50)
	);

	CREATE CLUSTERED INDEX	#CIX_tmpFlaggedAccountsIdx ON #tmpFlaggedAccounts (
			CustId				ASC
	);

	IF OBJECT_ID('tempdb..#tmpFraudTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTickets;
	END
	
	CREATE TABLE #tmpFraudTickets(
			CustId				INT		NOT NULL
		,	MatchId				INT		NOT NULL
		,	TransId				BIGINT	NOT NULL
		,	Username			NVARCHAR(50)
		,	CurrencyId			TINYINT
		,	CurrencyName		NVARCHAR(50)		
		,	EventDate			DATETIME
		,	PRIMARY KEY CLUSTERED (
				CustId				ASC
			,	MatchId				ASC
			,	TransId				ASC
		)		
	);

	IF OBJECT_ID('tempdb..#tmpFraudTicketsCustInfo') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTicketsCustInfo;
	END
	
	CREATE TABLE #tmpFraudTicketsCustInfo(
			CustId				INT	NOT	NULL PRIMARY KEY CLUSTERED
		,	Username			NVARCHAR(50)
		,	CurrencyId			TINYINT
		,	CurrencyName		NVARCHAR(50)
	);

	IF OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatches;
	END;

	CREATE TABLE #tmpMatches
	(
		MatchId INT	NOT	NULL PRIMARY KEY CLUSTERED
	);

	-- Insert flagged accounts	
	EXEC sp_xml_preparedocument @idoc OUTPUT, @FlaggedAccountsXML;

	INSERT INTO #tmpFlaggedAccounts(CustId)
	SELECT Data.CustId
	FROM	OPENXML (@idoc, '/Root/CustomerEvidence', 1)
			WITH (CustId INT, EvidenceCode NVARCHAR(50), EvidenceName NVARCHAR(50)) AS Data;

	INSERT INTO #tmpMatches(MatchId)
	SELECT val FROM SPU_StrSplit(@MatchIds, ',');

	INSERT INTO #tmpFraudTickets(CustId, Username, CurrencyId, CurrencyName, MatchId, EventDate, TransId)
	SELECT	DISTINCT [CustId]	= ans.custid
		,	[Username]			= ans.Username
		,	[CurrencyId]		= ans.currency
		,	[CurrencyName]		= ans.CurrencyName
		,	[MatchId]			= ans.matchid
		,	[EventDate]			= fms.EventDate
		,	[TransId]			= ans.transid
	FROM	dbo.FlagAccountMatchScanning fms WITH (NOLOCK)
	INNER JOIN bodb02.dbo.bettrans ans WITH (NOLOCK) ON fms.matchid = ans.matchid
	INNER JOIN #tmpFlaggedAccounts fa WITH (NOLOCK) ON fa.custid = ans.custid
	WHERE fms.matchid IN (SELECT m.MatchId FROM #tmpMatches m WITH (NOLOCK))
		AND ans.bettype IN (
			SELECT DISTINCT spb.BetType
			FROM bodb02.dbo.SportBettypeMatrix spb WITH (NOLOCK)
			WHERE spb.ProductID = 1
		)
		AND ans.custid NOT IN (SELECT dga.CustId FROM dbo.DelayGoalAccount dga WITH (NOLOCK))
		AND ans.currency <> 20;

	-- UPDATE match info for ScannedMatch table
	DELETE FROM dbo.ScannedMatch WITH (ROWLOCK)
	WHERE FraudCaseId = @CurrentFraudCaseId
		AND MatchId IN (SELECT MatchId FROM #tmpMatches WITH (NOLOCK));

	INSERT INTO dbo.ScannedMatch(MatchId, FraudCaseId, ScannedDate, SuspiciousTicketsCount)
	SELECT	[MatchId]					= m.MatchId
		,	[FraudCaseId]				= @CurrentFraudCaseId
		,	[ScannedDate]				= GETDATE()
		,	[SuspiciousTicketsCount]	= COUNT(ft.TransId)
	FROM #tmpMatches m WITH (NOLOCK)
	LEFT JOIN #tmpFraudTickets ft WITH (NOLOCK) ON m.MatchId = ft.MatchId
	GROUP BY m.MatchId, ft.MatchId;

	-- Check the results and store/return data
	IF(SELECT COUNT(1) FROM #tmpFraudTickets WITH (NOLOCK)) > 0
	BEGIN
		INSERT INTO #tmpFraudTicketsCustInfo (CustId, Username, CurrencyId, CurrencyName)
		SELECT DISTINCT ft.Custid, ft.Username, ft.CurrencyId, ft.CurrencyName
		FROM #tmpFraudTickets ft WITH (NOLOCK);

		UPDATE sc WITH (ROWLOCK, UPDLOCK)
		SET sc.IsVerified = 0, sc.Username = t.Username
		FROM dbo.SuspiciousCustomer sc 
			INNER JOIN #tmpFraudTicketsCustInfo t ON sc.Custid = t.CustId;
	
		INSERT INTO dbo.SuspiciousCustomer(Custid, Username, CurrencyId, CurrencyName, IsDelinquent, IsHedge, IsDirty, IsVerified)
		SELECT ft.CustId, ft.Username, ft.CurrencyId, ft.CurrencyName, 0, 0, 0, 0
		FROM #tmpFraudTicketsCustInfo ft WITH (NOLOCK)
		WHERE ft.CustId NOT IN (SELECT sc.CustId 
								FROM dbo.SuspiciousCustomer sc WITH (NOLOCK));
					
		DELETE FROM dbo.SuspiciousInfo WITH (ROWLOCK)
		WHERE FraudCaseId = @CurrentFraudCaseId
			AND MatchId IN (SELECT MatchId FROM #tmpMatches WITH (NOLOCK));

		INSERT INTO dbo.SuspiciousInfo(CustId, MatchId, EventDate, FraudCaseId, SuspiciousDate, TransIds, ViolationCounter, TicketCounter)
		SELECT [CustId]			= ft.CustId
			,	[MatchId]			= ft.MatchId
			,	[EventDate]			= ft.EventDate
			,	[FraudCaseId]		= @CurrentFraudCaseId
			,	[SuspiciousDate]	= GETDATE()
			,	[TransIds]			= STUFF((SELECT ',', CONVERT(VARCHAR(15), t1.TransId) 
										 FROM #tmpFraudTickets AS t1 WITH (NOLOCK)
										 WHERE t1.CustId = ft.CustId AND t1.MatchId = ft.MatchId 
										 FOR XML PATH('')), 1, 1, '')
			,	[ViolationCounter]	= 1
			,	[TicketCounter]		= COUNT(ft.TransId)
		FROM #tmpFraudTickets ft WITH (NOLOCK)
		GROUP BY ft.CustId, ft.MatchId, ft.EventDate;		

	END;
	
	------------------------------------------------------------------
	--===10. UPDATE: TABLE DelayGoalMatchScanning (fromTransId= (the last scanned Transid + 1)
	UPDATE		d 
	SET			d.IsScanCompleted = (CASE WHEN d.EventStatus = 'Completed' THEN 1 ELSE 0 END)
	FROM		dbo.FlagAccountMatchScanning d WITH (ROWLOCK, UPDLOCK)
	INNER JOIN	#tmpMatches mi WITH (NOLOCK)
				ON mi.MatchId = d.MatchId
	WHERE		d.IsScanCompleted = 0;

	EXEC sp_xml_removedocument @idoc;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/