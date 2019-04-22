GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE dbo.FS_FraudCase_OfficeIP_Rule
	@MatchIds VARCHAR(MAX) = NULL
AS
/*
	Created: 20180605@CaseyHuynh
	Task : Task IP Office Precondition
	DB: bodb_FraudSensor

	Original:

	Revisions: 
		- 20180726@Casey.Huynh: Change IP Part Number data type from TinyINT to SMALLINT. Due to IP in Bettrans has Invalid Range '345'
		- 20190219@Long.Luu:	Store more info (Currency & Username) for table SuspiciousCutomers [Redmine ID: 107858]
		- 20190319@Casey.Huynh: Enhance Performance table #tmpFraudTickets [110060]
		- 20190320@Casey.Huynh: Enhance Performance, define PRIMARY KEY in table [110060]
		- 20190322@Long.Luu:	Exclude Internal Accounts from Office IP Scanning [Redmine ID: 107865]

	Param's Explanation (filtered by):

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @fraudCaseID INT = 2;

	--===1. INITIAL TEMP #TABLEs===========
	--#tmpMatchInput: Store Scanned Matches with Max(transid) will be scanned
	IF OBJECT_ID('tempdb..#tmpMatchInput') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatchInput;
	END;

	CREATE TABLE #tmpMatchInput
	(
		MatchId		INT NOT NULL PRIMARY KEY CLUSTERED
		, EventDate	DATETIME
	);
	
	--#tmpBettype Bettype will be scanned
	IF OBJECT_ID('tempdb..#tmpBettype') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpBettype;
	END;

	CREATE TABLE #tmpBettype
	(
		Bettype INT NOT NULL PRIMARY KEY CLUSTERED
	);
	
	
	--#tmpFraudTickets: Store Fraud Ticket
	IF OBJECT_ID('tempdb..#tmpFraudTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTickets;
	END;

	CREATE TABLE #tmpFraudTickets
	(
			CustId				INT NOT NULL
		, 	MatchId				INT NOT NULL
		, 	TransId				BIGINT NOT NULL		
		,	Username			NVARCHAR(50)
		,	CurrencyId			TINYINT
		,	CurrencyName		NVARCHAR(50)		
		, 	EventDate			DATE NULL
		, 	ARecommend			INT	NULL
		, 	MRecommend			INT	NULL
		, 	SRecommend			INT	NULL
		,	PRIMARY KEY CLUSTERED (
				CustId				ASC
			,	MatchId				ASC
			,	TransId				ASC
		)
	);

	CREATE NONCLUSTERED INDEX	#NIX_tmpFraudTickets_Recommend ON #tmpFraudTickets (
			ARecommend			ASC
		,	MRecommend			ASC
		,	SRecommend			ASC
	);

	IF OBJECT_ID('tempdb..#tmpFraudTicketsCustInfo') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTicketsCustInfo;
	END
	
	CREATE TABLE #tmpFraudTicketsCustInfo(
			CustId				INT NOT NULL PRIMARY KEY CLUSTERED
		,	Username			NVARCHAR(50)
		,	CurrencyId			TINYINT
		,	CurrencyName		NVARCHAR(50)
	);

	--===2. INSERT DATA TO #tmpMatchInput===========
	INSERT INTO #tmpMatchInput(MatchId)
	SELECT val FROM dbo.SPU_StrSplit(@MatchIds, ', ');
	
	UPDATE mi 
	SET		mi.EventDate = m.eventdate
	FROM	#tmpMatchInput AS mi WITH(ROWLOCK, UPDLOCK)
			INNER JOIN bodb02.dbo.Match m WITH (NOLOCK) ON mi.MatchId = m.matchid;
	
	--===3. INSERT DATA TO #tmpBettype===========
	INSERT INTO #tmpBettype(Bettype)
	SELECT DISTINCT Bettype FROM bodb02.dbo.SportBettypeMatrix  AS sm WITH(NOLOCK) WHERE sm.ProductID = 1;	

	--===4. INSERT DATE TO #tmpFraudTickets
	INSERT INTO #tmpFraudTickets(CustId, Username, CurrencyId, CurrencyName, MatchId, TransId, EventDate, ARecommend, MRecommend, SRecommend)
	SELECT	b.custid
		,	b.Username
		,	b.currency
		,	b.CurrencyName
		,	b.matchid
		,	b.transid
		,	mi.EventDate
		,	b.recommend
		,	b.mrecommend
		,	b.srecommend
	FROM	bodb02.dbo.bettrans AS b WITH (NOLOCK)
			INNER JOIN #tmpMatchInput AS mi WITH (NOLOCK) ON mi.matchid = b.MatchId
			INNER JOIN #tmpBettype AS bt WITH (NOLOCK) ON b.bettype = bt.Bettype
			INNER JOIN dbo.OfficeIP AS oi WITH (NOLOCK) ON b.ip LIKE ''+ oi.IPRange +'.%' AND (CAST(PARSENAME(b.ip, 1) AS SMALLINT) BETWEEN oi.FromNumber AND oi.ToNumber)
	WHERE	b.currency NOT IN (20, 27, 28);

	--===4-plus. REMOVE INTERNAL ACCOUNT FROM #tmpFraudTickets
	DELETE tr FROM #tmpFraudTickets AS tr
			INNER JOIN dbo.OfficeIPInternalAccount AS a WITH(NOLOCK) ON (tr.ARecommend = a.CustId OR tr.MRecommend = a.CustId OR tr.SRecommend = a.CustId OR tr.CustId = a.CustId)
			WHERE a.IsActive = 1;

	--===5. INSERT SCANNED MATCH: TABLE "ScannedMatch" (ScannedDate, SuspiciousTicketsCount)===========		
	INSERT INTO dbo.ScannedMatch (Matchid, FraudCaseId, ScannedDate, SuspiciousTicketsCount) 
	SELECT [MatchId] = mi.matchid 
		, [FraudCaseId] = @fraudCaseID
		, [ScannedDate] = GETDATE() 
		, [SuspiciousTicketsCount] = (ISNULL((SELECT COUNT(1) 
											FROM #tmpFraudTickets t1 WITH (NOLOCK)
											WHERE t1.MatchId = mi.MatchId 
											GROUP BY t1.MatchId ), 0)) 
	FROM #tmpMatchInput AS mi WITH (NOLOCK) 
		LEFT JOIN dbo.ScannedMatch AS sm WITH (NOLOCK)ON mi.matchid = sm.matchid AND sm.FraudCaseId = @fraudCaseID
	WHERE sm.Matchid IS NULL AND sm.FraudCaseId IS NULL ; 
	
	IF EXISTS (SELECT TOP(1) 1 FROM #tmpFraudTickets WITH(NOLOCK))
	BEGIN							
		--===6. INSERT: TABLE "SuspiciousInfo" if (Match, Custid, FrauseCase) is Exitsing
		INSERT INTO	dbo.SuspiciousInfo(CustId, MatchId, EventDate, FraudCaseId, SuspiciousDate, TransIds, ViolatiONCounter, TicketCounter)
		SELECT	[CustId]			= ft.CustId
			, 	[MatchId]			= ft.MatchId
			, 	[EventDate]			= ft.EventDate
			, 	[FraudCaseId]		= @fraudCaseID
			, 	[SuspiciousDate]	= GETDATE()
			, 	[TransIds]			= STUFF((SELECT ', ', CONVERT(VARCHAR(15), t1.TransId) 
									 FROM #tmpFraudTickets AS t1 WITH(NOLOCK)
									 WHERE t1.CustId = ft.CustId AND t1.MatchId = ft.MatchId 
									 FOR XML PATH('')), 1, 1, '')
			, 	[ViolatiONCounter]	= 1
			, 	[TicketCounter]		= COUNT(1)
		FROM	#tmpFraudTickets AS ft WITH (NOLOCK)
				LEFT JOIN dbo.SuspiciousInfo AS si WITH (NOLOCK) 
					ON si.MatchId = ft.MatchId AND si.FraudCaseId = @fraudCaseID AND si.CustId = ft.CustId 
		WHERE	si.MatchID IS NULL AND si.FraudCaseId IS NULL AND si.CustId IS NULL
		GROUP BY ft.CustId, ft.MatchId, ft.EventDate;
			
		--===8. UPDATE: TABLE "SuspiciousCustomer" IsVerified=0 if has new Fraud Tickets)
		INSERT INTO #tmpFraudTicketsCustInfo (CustId, Username, CurrencyId, CurrencyName)
		SELECT DISTINCT ft.Custid, ft.Username, ft.CurrencyId, ft.CurrencyName
		FROM #tmpFraudTickets ft WITH (NOLOCK);

		UPDATE sc WITH (ROWLOCK, UPDLOCK)
		SET sc.IsVerified = 0, sc.Username = t.Username
		FROM dbo.SuspiciousCustomer sc 
			INNER JOIN #tmpFraudTicketsCustInfo t ON sc.Custid = t.CustId;

		--===9. INSERT: TABLE "SuspiciousCustomer" if NOT Exitsing Custid
		INSERT INTO dbo.SuspiciousCustomer(Custid, Username, CurrencyId, CurrencyName, IsDelinquent, IsHedge, IsDirty, IsVerified)
		SELECT ft.CustId, ft.Username, ft.CurrencyId, ft.CurrencyName, 0, 0, 0, 0
		FROM #tmpFraudTicketsCustInfo ft WITH (NOLOCK)
		WHERE ft.CustId NOT IN (SELECT sc.CustId 
								FROM dbo.SuspiciousCustomer sc WITH (NOLOCK));
	END;		
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/