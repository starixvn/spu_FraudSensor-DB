GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[FS_FraudCase_BetsNearGoal_Rule] 
	@MatchIds VARCHAR(MAX) = NULL
AS
/*
	Created: 20181207@Long
	Task : Rule for Bets Near The Goal fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions:	
		- 20181207@Long: Created [Redmine ID: 106079]
		- 20190219@Long: Store more info (Currency & Username) for table SuspiciousCutomers [Redmine ID: 107858]
		- 20190319@Casey.Huynh: Enhance Performance table #tmpFraudTickets [110060]
		- 20190320@Casey.Huynh: Enhance Performance, define PRIMARY KEY in table [110060]
	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	

	DECLARE @CurrentFraudCaseId TINYINT, @MinTicketsCount TINYINT, @ScannedDate DATETIME;
	SET @CurrentFraudCaseId = 11; -- Bets Near Goal
	SET	@MinTicketsCount = 5; -- Pre-defined
	SET	@ScannedDate = GETDATE();
	
	------- Arrange tables and initialize-------
	IF OBJECT_ID('tempdb..#tmpFraudTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTickets;
	END
	
	CREATE TABLE #tmpFraudTickets(
			CustId				INT				NOT NULL
		,	MatchId				INT				NOT NULL
		,	TransId				BIGINT			NOT NULL
		,	Username			NVARCHAR(50)
		,	CurrencyId			TINYINT
		,	CurrencyName		NVARCHAR(50)		
		,	EventDate			DATETIME		
		,	LiveHomeScore		SMALLINT
		,	LiveAwayScore		SMALLINT
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
			CustId				INT	NOT NULL PRIMARY KEY CLUSTERED
		,	Username			NVARCHAR(50)
		,	CurrencyId			TINYINT
		,	CurrencyName		NVARCHAR(50)
	);

	IF OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatches;
	END

	CREATE TABLE #tmpMatches
	(
		MatchId			INT NOT NULL PRIMARY KEY CLUSTERED
		, EventDate		DATETIME
		, EventStatus	NVARCHAR(50)
		, CurrentScore	TINYINT
	);
		
	---------------------------------------- START THE LOGIC----------------------------------------------
	-------GET MATCH-------
	INSERT INTO #tmpMatches(MatchId)
	SELECT val FROM dbo.SPU_StrSplit(@MatchIds, ',');	
	
	------- GET FRAUD TICKETS-------
	INSERT INTO #tmpFraudTickets (CustId, Username, CurrencyId, CurrencyName, MatchId, EventDate, TransId, LiveHomeScore, LiveAwayScore)
	SELECT  ans.custid
		,	ans.Username
		,	ans.currency
		,	ans.CurrencyName
		,	ans.matchid
		,	tch.eventdate
		,	ans.transid
		,	ans.liveawayscore
		,	ans.livehomescore
	FROM bodb02.dbo.match AS tch WITH (NOLOCK)
	INNER JOIN bodb02.dbo.bettrans AS ans WITH (NOLOCK) ON tch.matchid = ans.matchid
	INNER JOIN dbo.BSNGScanInfo AS si WITH(NOLOCK) ON si.matchid = ans.matchid 
		AND ans.livehomescore = si.livehomescore AND ans.liveawayscore = si.liveawayscore
	INNER JOIN #tmpMatches AS tm WITH(NOLOCK) ON tm.MatchId = tch.MatchId
	WHERE	ans.liveindicator = 1
		AND ans.transdate BETWEEN DATEADD(ss, -30, si.LastRejectedTime) AND si.LastRejectedTime
		AND ans.bettype IN (1, 3, 5, 7, 8, 15)
		AND ans.currency NOT IN (20, 27, 28)
		AND ans.statusID = 112 -- WON tickets
	GROUP BY ans.custid
		,	ans.Username
		,	ans.currency
		,	ans.CurrencyName
		,	ans.matchid
		,	tch.eventdate
		,	ans.liveawayscore
		,	ans.livehomescore
		,	ans.transid;

	DELETE t 
	FROM #tmpFraudTickets t
		INNER JOIN (SELECT t.MatchId, t.CustId, t.LiveHomeScore, t.LiveAwayScore
					FROM #tmpFraudTickets t
					GROUP BY t.MatchId, t.CustId, t.LiveHomeScore, t.LiveAwayScore
					HAVING COUNT(t.TransId) < @MinTicketsCount) a ON t.MatchId = a.MatchId AND t.CustId = a.CustId
						AND t.LiveHomeScore = a.LiveHomeScore AND t.LiveAwayScore = a.LiveAwayScore;
		
	-------INSERT SCANNED MATCH: TABLE "ScannedMatch" -------
	INSERT INTO dbo.ScannedMatch (Matchid, FraudCaseId, ScannedDate, SuspiciousTicketsCount)  
	SELECT [MatchId] = mi.matchid 
		, [FraudCaseId] = @CurrentFraudCaseId
		, [ScannedDate] = @ScannedDate 
		, [SuspiciousTicketsCount] = ISNULL((SELECT COUNT(1) 
									   		FROM #tmpFraudTickets t1 WITH (NOLOCK)
											WHERE t1.MatchId = mi.MatchId 
											GROUP BY t1.MatchId ),0)
	FROM #tmpMatches mi WITH (NOLOCK) 
		LEFT JOIN dbo.ScannedMatch sm WITH (NOLOCK)ON mi.matchid = sm.matchid AND sm.FraudCaseId = @CurrentFraudCaseId
	WHERE sm.Matchid IS NULL AND sm.FraudCaseId IS NULL ; 

	------- STORE SUSPICIOUS INFO ------- 
	IF EXISTS (SELECT TOP(1) 1 FROM #tmpFraudTickets WITH (NOLOCK))
	BEGIN
		INSERT INTO dbo.SuspiciousInfo(CustId, MatchId, EventDate, FraudCaseId, SuspiciousDate, TransIds, ViolationCounter, TicketCounter)
		SELECT	[CustId]			= ft.CustId
			,	[MatchId]			= ft.MatchId
			,	[EventDate]			= ft.EventDate
			,	[FraudCaseId]		= @CurrentFraudCaseId
			,	[SuspiciousDate]	= @ScannedDate
			,	[TransIds]			=	(
											STUFF((SELECT ',', CONVERT(VARCHAR(15), t1.TransId) 
											FROM #tmpFraudTickets AS t1 WITH(NOLOCK)
											WHERE t1.CustId = ft.CustId AND t1.MatchId = ft.MatchId 
											FOR XML PATH('')), 1, 1, '')
										)
			,	[ViolationCounter] =	(	
											SELECT COUNT(DISTINCT(t2.LiveHomeScore + t2.LiveAwayScore))
											FROM #tmpFraudTickets AS t2 WITH (NOLOCK)
											WHERE t2.CustId = ft.CustId AND t2.MatchId = ft.MatchId
											GROUP BY t2.MatchId, t2.CustId
										)
			,	[TicketCounter]		=	(
											SELECT COUNT(t3.TransId)
											FROM #tmpFraudTickets AS t3 WITH (NOLOCK)
											WHERE t3.CustId = ft.CustId AND t3.MatchId = ft.MatchId
										)
		FROM #tmpFraudTickets ft WITH (NOLOCK)
				LEFT JOIN dbo.SuspiciousInfo si WITH (NOLOCK) 
					ON si.MatchId = ft.MatchId AND si.FraudCaseId = @CurrentFraudCaseId AND si.CustId = ft.CustId 
		WHERE si.MatchID IS NULL AND si.FraudCaseId IS NULL AND si.CustId IS NULL
		GROUP BY ft.CustId, ft.MatchId, ft.EventDate;
		
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
	END;	
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/