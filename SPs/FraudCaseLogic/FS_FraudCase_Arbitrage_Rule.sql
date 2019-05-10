SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[FS_FraudCase_Arbitrage_Rule] 
		@Matches			VARCHAR(MAX) = NULL -- xml format
	,	@Associations		VARCHAR(MAX) = NULL -- xml format
AS
/*
	Created: 20180816@Long.Luu
	Task : Rule for Arbitrage fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20180815@Long.Luu: Implement Rule for Arbitrage fraud case
		- 20180924@Long.Luu: Remove the XML Documents after usage
		- 20180926@Long.Luu: Remove redundant fraud tickets [Redmine ID: 99753]
		- 20180926@Long.Luu: Fix issue of livehomescore [Redmine ID: 000000]
		- 20180926@Long.Luu: Performance tunning [Redmine ID: 000000]
		- 20180926@CASEY:Implement IP Rule [Redmine ID: 109092]
		- 20190316@CaseyHuynh: Enhance Performance, Update SuspiciousCustomer [Redmine ID: 110060]
		- 20190320@Casey.Huynh: Enhance Performance, define PRIMARY KEY in table [Redmine ID: 110060]
		- 20190314@Casey.Huynh: Implement, scan for completed Match [Redmine ID: 110566]
		- 20190326@Casey.Huynh: Fix Data NUll [Redmine ID: 110914]
		- 20190403@Long.Luu: Adding LiveHomeScore, LiveAwayScore for ArbitrageTicketDetails table [Redmine ID: 111069]
		- 20190503@Long.Luu:	Fix the buffer issue with "big" Fraud Cases [Redmine ID: 112706]
		- 20190509@Casey.Huynh:	Trace Log Info [Redmine ID: 110672]
		- 20190509@Casey.Huynh:	Fix Issue Performance when Update/Insert Scanned Match [Redmine ID: 110672]
	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	
	---=======Trace Log Info: Start=========================
	DECLARE @LogInfo			NVARCHAR(200)
			, @TraceGroup		INT
			, @StepStartTime	DATETIME
			, @StepEndTime		DATETIME
			, @SPName			VARCHAR(200) = 'FS_FraudCase_Arbitrage_Rule'
			, @StepDesc			NVARCHAR(200)
			, @StepID			INT
			, @MatchCount		INT
			, @MatchesHDPCount	INT
			, @TraceMatchID		INT
			, @RowCount			INT;

	SET @TraceGroup = ISNULL((SELECT MAX(TraceGroup) FROM dbo.Trace_Log WITH(NOLOCK)),0) + 1;

	---=======Trace Log Info: End=========================

	--=========ARRANGE================================
	DECLARE @CurrentFraudCaseId		TINYINT
		,	@MaxStakeToBeChecked	MONEY;
	SET		@CurrentFraudCaseId		= 10; -- Arbitrage
	SET		@MaxStakeToBeChecked	= 500;
	
	DECLARE @ScannedDate		DATETIME;
	SET	@ScannedDate			= GETDATE();
	
	IF OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatches;
	END

	CREATE TABLE #tmpMatches
	(
			MatchId				INT
		,	CustId				INT
		,	BetType				INT
		,	Handicap			SMALLMONEY
		,	LiveHomeScore		SMALLINT
		,	LiveAwayScore		SMALLINT
		,	PRIMARY KEY CLUSTERED (
				MatchId				ASC
			,	CustId				ASC
			,	BetType				ASC
			,	Handicap			ASC	
			,	LiveHomeScore		ASC
			,	LiveAwayScore		ASC
			) 
	);

	IF	OBJECT_ID('tempdb..#tmpAssociation') IS NOT NULL
	BEGIN;
		DROP TABLE #tmpAssociation;
	END;

	CREATE TABLE	#tmpAssociation (
			[CustId]		INT NOT NULL PRIMARY KEY CLUSTERED
		,	GroupID			INT NOT NULL
	);

	CREATE NONCLUSTERED INDEX	#NIX_tmpAssociation_GroupID ON #tmpAssociation (
			GroupID			ASC
	);

	IF	OBJECT_ID('tempdb..#tmpFraudIP') IS NOT NULL
	BEGIN;
		DROP TABLE #tmpFraudIP;
	END;

	CREATE TABLE	#tmpFraudIP (
			[MatchId]			INT NOT NULL
		,	[LiveHomeScore]		SMALLINT NOT NULL
		,	[LiveAwayScore]		SMALLINT NOT NULL
		,	[Bettype]			INT NOT NULL
		,	[Handicap]			SMALLMONEY NOT NULL
		,	[IP]				BIGINT NOT NULL
		PRIMARY KEY CLUSTERED(
				MatchId			ASC
			,	LiveHomeScore	ASC
			,	LiveAwayScore	ASC
			,	Bettype			ASC
			,	Handicap		ASC
			,	IP				ASC
		)
	);

	IF	OBJECT_ID('tempdb..#tmpMatchListbk') IS NOT NULL
	BEGIN;
		DROP TABLE #tmpMatchListbk;
	END;
	CREATE TABLE #tmpMatchListbk (
		MatchId INT NOT NULL PRIMARY KEY CLUSTERED
	);

	IF	OBJECT_ID('tempdb..#tmpMatchList') IS NOT NULL
	BEGIN;
		DROP TABLE #tmpMatchList;
	END;
	CREATE TABLE #tmpMatchList (
		MatchId INT NOT NULL PRIMARY KEY CLUSTERED
	);


	IF OBJECT_ID('tempdb..#tmpBettrans') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpBettrans;
	END

	CREATE TABLE #tmpBettrans
	(
			MatchId				INT	
		,	LiveHomeScore		SMALLINT
		,	LiveAwayScore		SMALLINT
		,	Bettype				INT
		,	Handicap			SMALLMONEY
		,	CustId				INT
		,	Username			NVARCHAR(50)
		,	CurrencyId			TINYINT
		,	CurrencyName		NVARCHAR(50)
		,	TransId				BIGINT	NOT NULL PRIMARY KEY CLUSTERED
		,	Betteam				NVARCHAR(50)		
		,	Stake				MONEY
		,	EventDate			DATETIME
		,	IP					BIGINT
	);

	CREATE NONCLUSTERED INDEX	#NIX_tmpBettrans_CustId ON #tmpBettrans (
			CustId				ASC
	);

	IF OBJECT_ID('tempdb..#tmpBettransAssociation') IS NOT NULL
    BEGIN
        DROP TABLE  #tmpBettransAssociation;
    END

	CREATE TABLE #tmpBettransAssociation
	(
			MatchId				INT NOT NULL
		,	LiveHomeScore		SMALLINT NOT NULL
		,	LiveAwayScore		SMALLINT NOT NULL
		,	Bettype				INT NOT NULL
		,	Handicap			SMALLMONEY NOT NULL
		,	CustId				INT NOT NULL
		,	GraphDBGroupId		INT NOT NULL
		,	GroupId				INT NOT NULL
		,	Username			NVARCHAR(50)
		,	CurrencyId			TINYINT
		,	CurrencyName		NVARCHAR(50)
		,	TransId				BIGINT	
		,	Betteam				NVARCHAR(50) NOT NULL		
		,	Stake				MONEY
		,	EventDate			DATETIME
		,	Ip					BIGINT NOT NULL
		,	IsIPFraud			BIT		
	);

	CREATE CLUSTERED INDEX	#NIX_tmpBettransAssociation ON #tmpBettransAssociation(			
			MatchId				ASC
		,	LiveHomeScore		ASC		
		,	LiveAwayScore		ASC		
		,	Bettype				ASC
		,	Handicap			ASC
		,	IP					ASC
		,	GroupId				ASC
		,   CustId				ASC		
		,	Betteam				ASC
		
	);

	IF OBJECT_ID('tempdb..#tmpIPGroup') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpIPGroup;
	END

	CREATE TABLE #tmpIPGroup
	(		
			MatchId				INT	NOT NULL
		,	LiveHomeScore		SMALLINT NOT NULL
		,	LiveAwayScore		SMALLINT NOT NULL
		,	Bettype				INT NOT NULL
		,	Handicap			SMALLMONEY NOT NULL
		,	IP					BIGINT NOT NULL
		,	GroupId				INT
		,	MinGroupId			INT	
	);
	
	CREATE CLUSTERED INDEX	#IX_#tmpIPGroup_MatchIdScoreBettype ON #tmpIPGroup (
			MatchId				ASC
		,	LiveHomeScore		ASC
		,	LiveAwayScore		ASC
		,	BetType				ASC		
		,	Handicap			ASC
		,	IP					ASC
	);

	IF OBJECT_ID('tempdb..#tmpFraudTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTickets;
	END
	
	CREATE TABLE #tmpFraudTickets(
			MatchId				INT
		,	LiveHomeScore		SMALLINT
		,	LiveAwayScore		SMALLINT
		,	Handicap			SMALLMONEY
		,	GroupId				INT
		,	GraphDBGroupId		INT
		,	CustId				INT
		,	IsIPFraud			BIT
		,	Username			NVARCHAR(50)
		,	CurrencyId			TINYINT
		,	CurrencyName		NVARCHAR(50)		
		,	Bettype				INT
		,	EventDate			DATETIME
		,	TransId				BIGINT	
		,   Ip					BIGINT		
	);

	CREATE CLUSTERED INDEX	#IX_tmpFraudTicketsIdx ON #tmpFraudTickets (
			MatchId				ASC
		,	CustId				ASC	
		,	LiveHomeScore		ASC
		,	LiveAwayScore		ASC
		,	Bettype				ASC
		,	Handicap			ASC
		,	GroupId				ASC			
	);

	IF OBJECT_ID('tempdb..#tmpMatchBettypeBetteamSumStake') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatchBettypeBetteamSumStake;
	END
	
	CREATE TABLE #tmpMatchBettypeBetteamSumStake(
			
			MatchId				INT
		,	LiveHomeScore		SMALLINT
		,	LiveAwayScore		SMALLINT
		,	Bettype				INT
		,	Handicap			SMALLMONEY	
		,	GroupId				INT			
		,	TotalStakeH			MONEY
		,	TotalStakeA			MONEY
		,	PRIMARY KEY CLUSTERED (			
				MatchId			ASC
			,	LiveHomeScore	ASC
			,	LiveAwayScore	ASC
			,	Bettype			ASC
			,	Handicap		ASC
			,	GroupId			ASC
			)
	);	

	-- INIT	
	DECLARE @idocMatch INT
		,	@idocAssociation INT;

	---=======Trace Log Info: Start STEP 1=========================
	SET @StepStartTime = GETDATE()
	SET @StepID = 1
	SET @StepDesc = 'INSERT INTO #tmpMatches'
	---=======Trace Log Info: End  =========================

	--Create an internal representation of the XML document
	EXEC sp_xml_preparedocument @idocMatch OUTPUT, @Matches;
	
	-- Execute a SELECT statement that uses the OPENXML rowset provider
	
	INSERT INTO #tmpMatches (MatchId, CustId, BetType, Handicap, LiveHomeScore, LiveAwayScore)
	SELECT	Data.MatchId
		,	Data.CustId
		,	Data.BetType
		,	Data.Handicap
		,	Data.LiveHomeScore
		,	Data.LiveAwayScore
	FROM OPENXML(@idocMatch, '/Root/Match', 2) WITH (
			MatchId INT '@MatchId'
		,	BetType INT	'@BetType'
		,	CustId INT '@CustId'
		,	Handicap MONEY '@Handicap'
		,	LiveHomeScore INT '@LiveHomeScore'
		,	LiveAwayScore INT '@LiveAwayScore'
	) AS Data;

	---=======Trace Log Info: Start=========================
	SET @StepEndTime = GETDATE()

	SET @MatchesHDPCount = (SELECT COUNT(1) FROM #tmpMatches WITH(NOLOCK))
	SET @TraceMatchID = (SELECT TOP(1) MatchID FROM #tmpMatches WITH(NOLOCK))
	SET @MatchCount = (SELECT COUNT(DISTINCT MatchID) FROM #tmpMatches WITH(NOLOCK))

	SET @LogInfo = '@MatchID = ' + CONVERT(VARCHAR(10), @TraceMatchID)
					+  '; @MatchCount = ' + CONVERT(VARCHAR(10), @MatchCount)
					+  '; @MatchesHDPCount = ' + CONVERT(VARCHAR(10), @MatchesHDPCount)

	INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
	VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)

	---=======Trace Log Info: End STEP 1 =========================

	---=======Trace Log Info: Start STEP 2=========================
	SET @StepStartTime = GETDATE()
	SET @StepID = 2
	SET @StepDesc = 'INSERT INTO #tmpAssociation'
	---=======Trace Log Info: End  =========================

	EXEC sp_xml_preparedocument @idocAssociation OUTPUT, @Associations;



	-- Execute a SELECT statement that uses the OPENXML rowset provider
	INSERT INTO #tmpAssociation (CustId, GroupId)
	SELECT	Data.CustId
		,	Data.GroupId
	FROM OPENXML(@idocAssociation, '/Root/Association', 2) WITH (
			CustId INT '@CustId'	
		,	GroupId INT '@GroupId'
	) AS Data;
	
	
	---=======Trace Log Info: Start=========================
	SET @RowCount = @@ROWCOUNT

	SET @StepEndTime = GETDATE()

	SET @LogInfo = '#tmpAssociation COUNT = ' + CONVERT(VARCHAR(10), @RowCount)
	INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
	VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)

	---=======Trace Log Info: End STEP 2 =========================


	
	---=======Trace Log Info: Start STEP 3=========================	
	SET @StepID = 3
	SET @StepDesc = 'INSERT INTO #tmpBettrans'
	SET @StepStartTime = GETDATE()
	---=======Trace Log Info: End  =========================

	--================GET: BETTRANS TICKET
	INSERT INTO #tmpBettrans(CustId, Username, CurrencyId, CurrencyName, MatchId, TransId, Bettype, LiveHomeScore, LiveAwayScore, Betteam, Handicap, Stake, EventDate, IP)
	SELECT	DISTINCT [CustId]	= b.custid
		,	[Username]			= b.Username
		,	[CurrencyId]		= b.currency
		,	[CurrencyName]		= b.CurrencyName
		,	[MatchId]			= b.matchid
		,	[TransId]			= b.transid
		,	[Bettype]			= b.bettype
		,	[LiveHomeScore]		= b.livehomescore
		,	[LiveAwayScore]		= b.liveawayscore
		,	[Betteam]			= b.betteam
		,	[Handicap]			= (b.hdp1 - b.hdp2)
		,	[stake]				= (b.stake * b.actualrate)
		,	[EventDate]			= b.winlostdate
		,	[IP]				= ISNULL(dbo.f_IPAddressToInteger(b.IP),0)
	FROM	bodb02.dbo.bettrans AS b WITH(NOLOCK)
			INNER JOIN #tmpMatches AS m WITH(NOLOCK) ON b.matchid = m.MatchId AND b.bettype = m.BetType	AND b.custid = m.CustId
					AND (b.hdp1 - b.hdp2) = m.Handicap AND b.livehomescore = m.LiveHomeScore AND b.liveawayscore = m.LiveAwayScore
	WHERE	b.matchId > 0
			AND b.bettype IN (1, 3, 7, 8)
			AND b.Currency NOT IN (20, 27, 28);	
	
	---=======Trace Log Info: Start=========================
	SET @RowCount = @@ROWCOUNT
	SET @StepEndTime = GETDATE()

	SET @LogInfo = '#tmpBettrans COUNT = ' + CONVERT(VARCHAR(10), @RowCount)
	INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
	VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)

	---=======Trace Log Info: End STEP 3 =========================


	---=======Trace Log Info: Start STEP 4=========================	
	SET @StepID = 4
	SET @StepDesc = 'INSERT INTO #tmpBettransAssociation'
	SET @StepStartTime = GETDATE()
	---=======Trace Log Info: End  =========================

	---===========GET: ASSOCIATION TICKETS
	INSERT INTO #tmpBettransAssociation(CustId, Username, CurrencyId, CurrencyName, MatchId, TransId, Bettype, LiveHomeScore, LiveAwayScore, Betteam, Handicap, Stake, EventDate, Ip, GraphDBGroupID, GroupId, IsIPFraud)
	SELECT	DISTINCT b.CustId
		,	b.Username
		,	b.CurrencyId
		,	b.CurrencyName
		,	b.MatchId
		,	b.TransId
		,	b.Bettype
		,	b.LiveHomeScore
		,	b.LiveAwayScore
		,	b.Betteam
		,	b.Handicap
		,	b.Stake
		,	b.EventDate
		,	b.Ip
		,	a.GroupID AS GraphDBGroupID
		,	a.GroupID AS GroupID
		,	0	AS IsIPFraud
	FROM	#tmpBettrans AS b WITH(NOLOCK)
		INNER JOIN #tmpAssociation AS a WITH(NOLOCK) ON b.CustId = a.CustId;
	
	SET @RowCount = @@ROWCOUNT
	---=======Trace Log Info: Start=========================
	SET @StepEndTime = GETDATE()

	SET @LogInfo = '#tmpBettransAssociation COUNT = ' + CONVERT(VARCHAR(10), @RowCount)

	INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
	VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)

	---=======Trace Log Info: End STEP 4 =========================


	---- Merge Group By IP
	-----Find IP has more than one groupId
	DECLARE @Matchid INT;

	INSERT INTO #tmpMatchList(MatchId)
	SELECT DISTINCT MatchId
	FROM #tmpMatches WITH(NOLOCK);
	
	
	INSERT INTO #tmpMatchListbk(MatchId)
	SELECT MatchId
	FROM #tmpMatchList WITH(NOLOCK);


	SELECT @Matchid = (SELECT TOP(1) Matchid FROM #tmpMatchList WITH(NOLOCK));

	---=======Trace Log Info: Start STEP 5=========================	
	SET @StepID = 5
	SET @StepDesc = 'INSERT INTO #tmpIPGroup'
	SET @StepStartTime = GETDATE()

	---=======Trace Log Info: End  =========================
	WHILE (@Matchid IS NOT NULL)
	BEGIN
			
		TRUNCATE TABLE #tmpIPGroup;
		
		INSERT INTO #tmpIPGroup(MatchId, LiveHomeScore, LiveAwayScore, bettype, handicap, IP, GroupId, MinGroupId)
		SELECT	DISTINCT a.MatchId, a.LiveHomeScore, a.LiveAwayScore, a.bettype, a.handicap, a.IP, a.GroupId, a.MinGroupId	
		FROM	(SELECT		t.matchid
							, t.LiveHomeScore
							, t.LiveAwayScore
							, t.Bettype
							, t.Handicap
							, t.Ip
							, t.GroupId
							, MIN(t.GroupId) OVER (PARTITION BY t.MatchID, t.LiveHomeScore, t.LiveAwayScore, t.Bettype, t.Handicap, t.IP ) AS MinGroupId
				FROM		#tmpBettransAssociation t WITH(NOLOCK)
				WHERE		t.Matchid = @Matchid
				GROUP BY	t.MatchID, t.Bettype, t.LiveHomeScore, t.LiveAwayScore, t.Handicap, t.IP, t.GroupId) a
		WHERE	a.GroupId <> a.MinGroupId ;

		IF EXISTS (SELECT TOP(1) (1) FROM #tmpIPGroup WITH(NOLOCK))
		BEGIN		
			UPDATE	t
			SET		t.GroupId = g.MinGroupId
			FROM	#tmpBettransAssociation t WITH(ROWLOCK)
			INNER JOIN	#tmpIPGroup g WITH(NOLOCK)
						ON	g.MatchId = t.MatchId
						AND g.LiveHomeScore = t.LiveHomeScore
						AND g.LiveAwayScore = t.LiveAwayScore
						AND	g.Bettype = t.Bettype
						AND g.Handicap = t.Handicap
						AND g.IP = t.IP
			WHERE	t.Matchid = @Matchid;
		END;

		DELETE #tmpMatchList
		WHERE MatchId = @Matchid

		SELECT @Matchid = (SELECT TOP(1) Matchid FROM #tmpMatchList WITH(NOLOCK))
	END;

	---=======Trace Log Info: Start=========================
	SET @StepEndTime = GETDATE()

	SET @LogInfo = '#tmpIPGroup COUNT = ' + CONVERT(VARCHAR(10),(SELECT COUNT(1) FROM #tmpIPGroup WITH(NOLOCK)))

	INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
	VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)

	---=======Trace Log Info: End STEP 5 =========================


		
	---=======Trace Log Info: Start STEP 6=========================	
	SET @StepID = 6
	SET @StepDesc = 'INSERT INTO	#tmpMatchBettypeBetteamSumStake'
	SET @StepStartTime = GETDATE()
	---=======Trace Log Info: End  =========================

	--=================================================================================================	
	INSERT INTO	#tmpMatchBettypeBetteamSumStake(MatchId, LiveHomeScore, LiveAwayScore, Bettype, Handicap, GroupId, TotalStakeH, TotalStakeA)
	SELECT DISTINCT
				[Matchid]			= ba.MatchId
			,	[LiveHomeScore]		= ba.LiveHomeScore
			,	[LiveAwayScore]		= ba.LiveAwayScore
			,	[Bettype]			= ba.Bettype
			,	[Handicap]			= ba.Handicap
			,	[GroupId]			= ba.GroupId	
			,	[TotalStakeH]		= SUM(CASE WHEN ba.Betteam = 'h' then ba.stake ELSE 0 END)
			,	[TotalStakeA]		= SUM(CASE WHEN ba.Betteam = 'a' then ba.stake ELSE 0 END)
	FROM		#tmpBettransAssociation ba WITH(NOLOCK)
	GROUP BY	ba.GroupId, ba.MatchId, ba.Bettype, ba.LiveHomeScore, ba.LiveAwayScore, ba.Handicap
	HAVING		COUNT(DISTINCT ba.Betteam) > 1;
	
	---=======Trace Log Info: Start=========================
	SET @RowCount = @@ROWCOUNT

	SET @StepEndTime = GETDATE()

	SET @LogInfo = '#tmpMatchBettypeBetteamSumStake COUNT = ' + CONVERT(VARCHAR(10), @RowCount)

	INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
	VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)
	---=======Trace Log Info: End STEP 6 =========================


	---=======Trace Log Info: Start STEP 7=========================	
	SET @StepID = 7
	SET @StepDesc = 'INSERT INTO #tmpFraudTickets'
	SET @StepStartTime = GETDATE()
	---=======Trace Log Info: End  =========================

	-- Get fraud tickets
	INSERT INTO #tmpFraudTickets (CustId, Username, CurrencyId, CurrencyName, MatchId, GroupId, Bettype, EventDate, TransId, LiveHomeScore, LiveAwayScore, Handicap, IsIPFraud, IP, GraphDBGroupId )
	SELECT DISTINCT 
				[CustId]			= bb.CustId
			,	[Username]			= bb.Username
			,	[CurrencyId]		= bb.CurrencyId
			,	[CurrencyName]		= bb.CurrencyName
			,	[MatchId]			= r.matchid
			,	[GroupId]			= bb.GroupId
			,	[Bettype]			= bb.Bettype
			,	[EventDate]			= bb.EventDate
			,	[TransId]			= bb.TransId
			,	[LiveHomeScore]		= r.LiveHomeScore
			,	[LiveAwayScore]		= r.LiveAwayScore
			,	[Handicap]			= r.Handicap
			,	[IsIPFraud]			= bb.IsIPFraud
			,	[IP]				= bb.Ip
			,	[GraphDBGroupId]	= bb.GraphDBGroupId
	FROM		#tmpMatchBettypeBetteamSumStake AS r WITH(NOLOCK)
				INNER JOIN #tmpBettransAssociation bb WITH(NOLOCK) ON  r.MatchId = bb.MatchId AND r.GroupId = bb.GroupId AND r.Bettype = bb.Bettype 
				AND r.LiveHomeScore = bb.LiveHomeScore AND r.LiveAwayScore = bb.LiveAwayScore AND r.Handicap = bb.Handicap
	WHERE		r.TotalStakeH > @MaxStakeToBeChecked AND r.TotalStakeA > @MaxStakeToBeChecked
	ORDER BY	MatchId, LiveHomeScore, LiveAwayScore, Bettype, Handicap, transid
	OPTION (MAXDOP 1);
	
	---=======Trace Log Info: Start=========================
	SET @RowCount = @@ROWCOUNT
	SET @StepEndTime = GETDATE()

	SET @LogInfo = '#tmpFraudTickets COUNT = ' + CONVERT(VARCHAR(10), @RowCount)

	INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
	VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)

	---=======Trace Log Info: End STEP 7 =========================

	---=======Trace Log Info: Start STEP 8=========================	
	SET @StepID = 8
	SET @StepDesc = 'INSERT INTO #tmpFraudIP'
	SET @StepStartTime = GETDATE()

	---=======Trace Log Info: End  =========================
	--=======UPDATE: ISFraud by Match, totallivesoscore, bettype, Handicap
	INSERT INTO #tmpFraudIP(MatchId, LiveHomeScore, LiveAwayScore, Bettype, Handicap, IP)
	SELECT		t.matchid, LiveHomeScore, LiveAwayScore, Bettype, Handicap, IP 
	FROM		#tmpFraudTickets t WITH(NOLOCK)
	WHERE		t.GraphDBGroupId <> t.GroupId
	GROUP BY	t.matchid, LiveHomeScore, LiveAwayScore, Bettype, Handicap, IP;

	---=======Trace Log Info: Start=========================
	SET @RowCount = @@ROWCOUNT
	SET @StepEndTime = GETDATE()

	SET @LogInfo = '#tmpFraudIP COUNT = ' + CONVERT(VARCHAR(10), @RowCount)

	INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
	VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)

	---=======Trace Log Info: End STEP 8 =========================

	UPDATE	ft
	SET		ft.IsIPFraud = 1
	FROM	#tmpFraudTickets ft WITH(ROWLOCK)
			INNER JOIN #tmpFraudIP fi WITH(NOLOCK) ON ft.MatchId = fi.MatchId AND ft.LiveHomeScore = ft.LiveHomeScore AND ft.LiveAwayScore = ft.LiveAwayScore 
				AND ft.Bettype = fi.Bettype AND ft.Handicap = fi.Handicap AND ft.IP = fi.IP;

	-- Check the results and store/return data
	IF EXISTS (SELECT TOP(1) 1 FROM #tmpFraudTickets WITH (NOLOCK))
	BEGIN
		---=======Trace Log Info: Start STEP 9=========================	
		SET @StepID = 9
		SET @StepDesc = 'DELETE/INSERT INTO dbo.ArbitrageTicketDetails'
		SET @StepStartTime = GETDATE()
		---=======Trace Log Info: End  =========================
		
		DELETE		si
		FROM		dbo.ArbitrageTicketDetails si WITH(ROWLOCK)
					INNER JOIN #tmpFraudTickets ft WITH(NOLOCK) ON si.MatchId = ft.MatchId AND si.LiveHomeScore = ft.LiveHomeScore 
					 AND si.LiveAwayScore = ft.LiveAwayScore AND si.BetType = ft.BetType AND si.Handicap = ft.Handicap AND si.CustId = ft.CustId;
		
		-- Insert new records for table ArbitrageTicketDetails
		INSERT INTO dbo.ArbitrageTicketDetails(CustId, MatchId, EventDate, GroupId, BetType, Handicap, LiveHomeScore, LiveAwayScore, TransIds, TicketCounter, IsIPFraud, GraphDBGroupId)
		SELECT	[CustId]			= ft.CustId
			,	[MatchId]			= ft.MatchId
			,	[EventDate]			= ft.EventDate
			,	[GroupId]			= ft.GroupId
			,	[Bettype]			= ft.Bettype
			,	[Handicap]			= ft.Handicap
			,	[LiveHomeScore]		= ft.LiveHomeScore
			,	[LiveAwayScore]		= ft.LiveAwayScore
			,	[TransIds]			= STUFF((SELECT ',', CONVERT(VARCHAR(15), t1.TransId) 
											FROM #tmpFraudTickets AS t1 WITH(NOLOCK)
											WHERE t1.MatchId = ft.MatchId AND t1.BetType = ft.BetType AND t1.Handicap = ft.Handicap 
												AND t1.LiveHomeScore = ft.LiveHomeScore AND t1.LiveAwayScore = ft.LiveAwayScore 
												AND t1.CustId = ft.CustId AND t1.GroupId = ft.GroupId  AND t1.IsIPFraud = ft.IsIPFraud												
											FOR XML PATH('')), 1, 1, '')
			,	[TicketCounter]		= COUNT(ft.transId)
			,	[IsIPFraud]			= ft.IsIPFraud
			,	[GraphDBGroupId]	= MIN(ft.GroupId)
		FROM		#tmpFraudTickets ft WITH (NOLOCK)
		GROUP BY	ft.CustId, ft.MatchId, ft.EventDate, ft.GroupId, ft.Bettype, ft.Handicap, ft.LiveHomeScore, ft.LiveAwayScore, ft.IsIPFraud;		

		SET @RowCount = @@ROWCOUNT	
		

		---=======Trace Log Info: Start=========================
		SET @StepEndTime = GETDATE()

		SET @LogInfo = 'dbo.ArbitrageTicketDetails = ' + CONVERT(VARCHAR(10), @RowCount)

		INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
		VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)
		---=======Trace Log Info: End STEP 9 =========================

		---=======Trace Log Info: Start STEP 10=========================	
		SET @StepID = 10
		SET @StepDesc = 'UPDATE/INSERT INTO dbo.ArbitrageSuspiciousInfo'
		SET @StepStartTime = GETDATE()
		---=======Trace Log Info: End  =========================

		-- Update table SuspiciousInfo if existed
		UPDATE si WITH (ROWLOCK, UPDLOCK)
		SET		si.SuspiciousDate	=	GETDATE()
			,	si.TransIds			=	STUFF((SELECT DISTINCT ',', CONVERT(VARCHAR(MAX), t1.TransIds) 
										FROM dbo.ArbitrageTicketDetails t1 WITH (NOLOCK)
										WHERE t1.MatchId = ft.MatchId AND t1.CustId = ft.CustId
										FOR XML PATH('')), 1, 1, '')
			,	si.TicketCounter	=	(SELECT SUM(t2.TicketCounter) 
										FROM dbo.ArbitrageTicketDetails t2 WITH (NOLOCK)
										WHERE t2.MatchId = ft.MatchId AND t2.CustId = ft.CustId)
			,	si.IsVerified		=	0
			,	si.ViolationCounter =	(SELECT COUNT(1)
										FROM (SELECT DISTINCT t2.Bettype, t2.LiveHomeScore, t2.LiveAwayScore, t2.Handicap
										FROM dbo.ArbitrageTicketDetails AS t2 WITH (NOLOCK)
										WHERE t2.MatchId = ft.MatchId AND t2.CustId = ft.CustId) AS A)
		FROM dbo.ArbitrageSuspiciousInfo si
				INNER JOIN #tmpFraudTickets ft WITH (NOLOCK)
					ON si.MatchId = ft.MatchId AND si.CustId = ft.CustId AND si.FraudCaseId = @CurrentFraudCaseId;	
							
		-- Insert new records for table SuspiciousInfo
		INSERT INTO dbo.ArbitrageSuspiciousInfo(CustId, MatchId, EventDate, FraudCaseId, SuspiciousDate, TransIds, ViolationCounter, TicketCounter)
		SELECT	[CustId]			= ft.CustId
			,	[MatchId]			= ft.MatchId
			,	[EventDate]			= ft.EventDate
			,	[FraudCaseId]		= @CurrentFraudCaseId
			,	[SuspiciousDate]	= GETDATE()
			,	[TransIds]			= STUFF((SELECT DISTINCT ',', CONVERT(VARCHAR(MAX), t1.TransIds) 
										FROM dbo.ArbitrageTicketDetails t1 WITH (NOLOCK)
										WHERE t1.MatchId = ft.MatchId AND t1.CustId = ft.CustId
										FOR XML PATH('')), 1, 1, '')
			,	ViolationCounter	= (SELECT COUNT(1)
										FROM (SELECT DISTINCT t2.Bettype, t2.LiveHomeScore, LiveAwayScore, t2.Handicap
										FROM dbo.ArbitrageTicketDetails AS t2 WITH (NOLOCK)
										WHERE t2.MatchId = ft.MatchId AND t2.CustId = ft.CustId) AS A)
			,	[TicketCounter]		= (SELECT SUM(t3.TicketCounter) 
										FROM dbo.ArbitrageTicketDetails t3 WITH (NOLOCK)
										WHERE t3.MatchId = ft.MatchId AND t3.CustId = ft.CustId)
		FROM #tmpFraudTickets ft WITH (NOLOCK)
				LEFT JOIN dbo.ArbitrageSuspiciousInfo si WITH (NOLOCK) 
					ON si.MatchId = ft.MatchId AND si.CustId = ft.CustId  AND si.FraudCaseId = @CurrentFraudCaseId
		WHERE si.MatchID IS NULL
		GROUP BY ft.CustId, ft.MatchId, ft.EventDate;			
		
			---=======Trace Log Info: Start=========================
			SET @RowCount = @@ROWCOUNT;

			SET @StepEndTime = GETDATE();
						
			SET @LogInfo = 'dbo.ArbitrageSuspiciousInfo COUNT = ' + CONVERT(VARCHAR(10), @RowCount)

			INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
			VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)

			---=======Trace Log Info: End STEP10 =========================

		---=======Trace Log Info: Start STEP 11=========================	
		SET @StepID = 11
		SET @StepDesc = 'UPDATE/INSERT INTO dbo.SuspiciousCustomer'
		SET @StepStartTime = GETDATE();

		---=======Trace Log Info: End  =========================
		-- Update table SuspiciousCustomer if existed
		WITH rs AS
		(
			SELECT		CustId, Username
			FROM		#tmpFraudTickets WITH(NOLOCK)
			GROUP BY	custid, username 
		)
		UPDATE	sc WITH (ROWLOCK, UPDLOCK)
		SET		sc.IsVerified = 0, sc.Username = rs.Username
		FROM	dbo.SuspiciousCustomer AS sc
				INNER JOIN rs ON sc.custid = rs.custid;
		
		-- Insert new records for table SuspiciousCustomer
		INSERT INTO dbo.SuspiciousCustomer(Custid, IsDelinquent, IsHedge, IsDirty, IsVerified, Username, CurrencyId, CurrencyName)
		SELECT DISTINCT ft.CustId, 0, 0, 0, 0, ft.Username, ft.CurrencyId,ft.CurrencyName
		FROM #tmpFraudTickets ft WITH (NOLOCK)
				LEFT JOIN dbo.SuspiciousCustomer sc WITH (NOLOCK) ON ft.CustId = sc.CustId
		WHERE	sc.CustId IS NULL;

		---=======Trace Log Info: Start=========================
		SET @RowCount = @@ROWCOUNT	
	
		SET @StepEndTime = GETDATE()
	
		SET @LogInfo = 'INSERT dbo.SuspiciousCustomer COUNT = ' + CONVERT(VARCHAR(10), @RowCount)

		INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
		VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)
		---=======Trace Log Info: End STEP 11 =========================

	END;
		---=======Trace Log Info: Start STEP 12=========================	
		SET @StepID = 12
		SET @StepDesc = 'UPDATE/INSERT INTO dbo.ScannedMatch'
		SET @StepStartTime = GETDATE()

		---=======Trace Log Info: End  =========================
		-- Update table ScannedMatch if existed
		UPDATE	sm WITH (ROWLOCK, UPDLOCK)
		SET		sm.ScannedDate				= GETDATE()
			,	sm.SuspiciousTicketsCount	= ISNULL((SELECT SUM(t1.TicketCounter)
												FROM dbo.ArbitrageTicketDetails t1 WITH (NOLOCK)
												WHERE t1.MatchId = m.MatchId 
												),0)
		FROM		dbo.ScannedMatch sm
		INNER JOIN	#tmpMatchListbk m WITH (NOLOCK) ON sm.MatchId = m.MatchId AND sm.FraudCaseId = @CurrentFraudCaseId;

		-- Insert new records for table ScannedMatch
		INSERT INTO		dbo.ScannedMatch (Matchid, FraudCaseId, ScannedDate, SuspiciousTicketsCount)  
		SELECT	DISTINCT [MatchId]			= m.matchid 
			,	[FraudCaseId]				= @CurrentFraudCaseId
			,	[ScannedDate]				= GETDATE() 
			,	[SuspiciousTicketsCount]	= ISNULL((SELECT SUM(t1.TicketCounter)
												FROM dbo.ArbitrageTicketDetails t1 WITH (NOLOCK)
												WHERE t1.MatchId = m.MatchId 
												GROUP BY t1.MatchId ),0)
		FROM #tmpMatchListbk m WITH(NOLOCK)
			LEFT JOIN dbo.ScannedMatch sm WITH (NOLOCK)ON m.matchid = sm.matchid AND sm.FraudCaseId = @CurrentFraudCaseId
		WHERE sm.Matchid IS NULL 
			AND sm.FraudCaseId IS NULL;

		---=======Trace Log Info: Start=========================
		SET @RowCount = @@ROWCOUNT	
	
		SET @StepEndTime = GETDATE()
	
		SET @LogInfo = 'INSERT INTO dbo.ScannedMatch COUNT = ' + CONVERT(VARCHAR(10), @RowCount)

		INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
		VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)

		---=======Trace Log Info: End STEP 12 =========================

	--Remove the XML documents
	EXEC sp_xml_removedocument @idocMatch;
	EXEC sp_xml_removedocument @idocAssociation;
	
	-------------------UPDATE SCANNING PRECONDITON--------------------------------------
	---------------------------------------------------------------------------
	---=======Trace Log Info: Start STEP 13=========================	
		SET @StepID = 13
		SET @StepDesc = 'INSERT INTO ArbitrageMatchScoreHDP'
		SET @StepStartTime = GETDATE()
	---=======Trace Log Info: End  =========================

	INSERT INTO dbo.ArbitrageMatchScoreHDP (MatchId, LiveHomeScore, LiveAwayScore, BetType, Handicap, HasScanned, UpdatedDate)
	SELECT		m.MatchID
				, m.LiveHomeScore
				, m.LiveAwayScore
				, m.BetType
				, m.Handicap
				, 0 AS HasScanned
				, @ScannedDate
	FROM		#tmpMatches m WITH(NOLOCK)
	LEFT JOIN	ArbitrageMatchScoreHDP a WITH(NOLOCK)
				ON	m.MatchId = a.MatchId
				AND	m.LiveHomeScore = a.LiveHomeScore
				AND	m.LiveAwayScore = a.LiveAwayScore
				AND m.BetType = a.BetType
				AND m.Handicap = a.Handicap
	WHERE		a.Matchid IS NULL
	GROUP BY	m.MatchId,m.LiveHomeScore,m.LiveAwayScore, m.Bettype, m.Handicap;

	---=======Trace Log Info: Start=========================
	SET @RowCount = @@ROWCOUNT	
	
	SET @StepEndTime = GETDATE()
	
	SET @LogInfo = 'dbo.ArbitrageMatchScoreHDP COUNT = ' + CONVERT(VARCHAR(10), @RowCount)

	INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
	VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)

	---=======Trace Log Info: End STEP 13 =========================

	--=====Update Matched Completed
	---=======Trace Log Info: Start STEP 3=========================	
		SET @StepID = 14
		SET @StepDesc = 'UPDATE dbo.ArbitrageMatchScoreHDP'
		SET @StepStartTime = GETDATE();
		---=======Trace Log Info: End  =========================

	WITH #tmpCompletedMatch AS
	(
		SELECT		DISTINCT ams.MatchID
		FROM		#tmpMatches m WITH(NOLOCK)
		INNER JOIN	dbo.ArbitrageMatchScanning ams WITH(NOLOCK)
					ON	m.MatchId = ams.MatchId 
					AND	ams.IsMatchCompleted = 1
	)
	UPDATE		sh
	SET			sh.HasScanned = 1,  sh.UpdatedDate = @ScannedDate
	FROM		dbo.ArbitrageMatchScoreHDP sh WITH(ROWLOCK)
	INNER JOIN	#tmpCompletedMatch cm WITH(NOLOCK)
				ON cm.MatchId = sh.MatchId
	WHERE		sh.MatchId = cm.MatchID;

	---=======Trace Log Info: Start=========================
	SET @RowCount = @@ROWCOUNT	
	
	SET @StepEndTime = GETDATE()
	
	SET @LogInfo = 'UPDATE dbo.ArbitrageMatchScoreHDP COUNT = ' + CONVERT(VARCHAR(10), @RowCount)

	INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
	VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)

	---=======Trace Log Info: End STEP 14 =========================


	---=======Trace Log Info: Start STEP 15=========================	
		SET @StepID = 15
		SET @StepDesc = 'UPDATE dbo.ArbitrageMatchScanning'
		SET @StepStartTime = GETDATE();
		---=======Trace Log Info: End  =========================


	WITH #tmpCompletedMatch AS
	(
		SELECT		DISTINCT ams.MatchID
		FROM		#tmpMatches m WITH(NOLOCK)
		INNER JOIN	dbo.ArbitrageMatchScanning ams WITH(NOLOCK)
					ON	m.MatchId = ams.MatchId 
					AND	ams.IsMatchCompleted = 1
	)
	UPDATE		ams
	SET			ams.IsScanCompleted = 1, ams.CapturedDate = @ScannedDate
	FROM		dbo.ArbitrageMatchScanning ams WITH(ROWLOCK)
	INNER JOIN	#tmpCompletedMatch cm WITH(NOLOCK)
				ON ams.MatchId = cm.MatchId				
				AND ams.IsMatchCompleted = 1;
	

	---=======Trace Log Info: Start=========================
	SET @RowCount = @@ROWCOUNT	
	
	SET @StepEndTime = GETDATE()
	
	SET @LogInfo = 'dbo.ArbitrageMatchScanning COUNT = ' + CONVERT(VARCHAR(10), @RowCount)

	INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
	VALUES (@TraceGroup, @SPName, @StepID, @StepStartTime, @StepEndTime, @StepDesc, @LogInfo)

	---=======Trace Log Info: End STEP 15 =========================

	--====Update for LiveScore has completed

	--1. UPDATE SCANNING STATUS
	UPDATE		sh WITH(ROWLOCK)
	SET			sh.HasScanned = 1, sh.UpdatedDate = @ScannedDate
	FROM		dbo.ArbitrageMatchScoreHDP sh WITH(ROWLOCK)
	INNER JOIN	(	SELECT	m.MatchId
						, MAX(m.LiveHomeScore) AS MaxHomeScore
						, MAX(m.LiveAwayScore) AS MaxAwayScore
					FROM	#tmpMatches m WITH(NOLOCK)
					GROUP BY MatchId) AS ms
				ON ms.MatchId = sh.MatchId
	WHERE		(sh.LiveHomeScore < ms.MaxHomeScore OR sh.LiveAwayScore < ms.MaxAwayScore)
				AND sh.HasScanned = 0;

	---=======Trace Log Info: Start=========================
	SET @StepID = 16
	SET @StepEndTime = GETDATE()

	SET @LogInfo = ''

	INSERT INTO Trace_Log(TraceGroup, SPName, StepId, StartTime, EndTime, StepDesc, LogInfo)
	VALUES (@TraceGroup, @SPName, @StepID, @ScannedDate, @StepEndTime, @StepDesc, @LogInfo)

	---=======Trace Log Info: End STEP 16 =========================
	

END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
