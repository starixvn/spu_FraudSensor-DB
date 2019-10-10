ALTER PROCEDURE [dbo].[FS_FraudCase_BetsNearGoal_Rule] 
	@MatchId		INT
AS
/*
	Created: 20181207@Long
	Task : Rule for Bets Near The Goal fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions:	
		- 20181207@Long: Created [Redmine ID: 106079]
		- 20190219@Long: Store more info (Currency & Username) for table SuspiciousCutomers [Redmine ID: 107858]
		- 20190319@Casey.Huynh: Enhance Performance table #tmpFraudTickets [Redmine ID: 110060]
		- 20190320@Casey.Huynh: Enhance Performance, define PRIMARY KEY in table [Redmine ID: 110060]		
		- 20190503@Long.Luu: Fix the buffer issue with "big" Fraud Cases [Redmine ID: 112706]
		- 20190604@John.Ngo: Modify fraud case rules of Bet Neal the Goal [Redmine ID: 114438]
		- 20190624@John.Ngo:	Remove Curreny Name on FS DB and use ID instead [Redmine ID: 115326]
		- 20191010@Long.Luu:	Change input param [Redmine ID: 118117]

	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	
	
	DECLARE @CurrentFraudCaseId TINYINT, @ScannedDate DATETIME, @__matchId INT;
	SELECT @CurrentFraudCaseId = 11, @ScannedDate = GETDATE(), @__matchId = @MatchId; -- Bets Near Goal
	
	------- Arrange tables and initialize-------
	IF OBJECT_ID('tempdb..#tmpFraudTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTickets;
	END
	
	CREATE TABLE #tmpFraudTickets(
			CustId				INT				NOT NULL
		,	TransId				BIGINT			NOT NULL
		,	Username			NVARCHAR(50)
		,	CurrencyId			TINYINT
		,	CurrencyName		NVARCHAR(50)		
		,	EventDate			DATETIME		
		,	LiveHomeScore		SMALLINT
		,	LiveAwayScore		SMALLINT
		,	PRIMARY KEY CLUSTERED (
				CustId			ASC
			,	TransId			ASC
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
	);
		
	---------------------------------------- START THE LOGIC----------------------------------------------	
	------- GET FRAUD TICKETS-------
	INSERT INTO #tmpFraudTickets (CustId, Username, CurrencyId, CurrencyName, EventDate, TransId, LiveHomeScore, LiveAwayScore)
	SELECT  ans.custid
		,	ans.Username
		,	ans.currency
		,	ans.CurrencyName
		,	tch.eventdate
		,	ans.transid
		,	ans.liveawayscore
		,	ans.livehomescore
	FROM bodb02.dbo.match AS tch WITH (NOLOCK)
	INNER JOIN bodb02.dbo.bettrans AS ans WITH (NOLOCK) ON tch.matchid = ans.matchid
	INNER JOIN dbo.BSNGScanInfo AS si WITH(NOLOCK) ON si.matchid = ans.matchid 
		AND ans.livehomescore = si.livehomescore AND ans.liveawayscore = si.liveawayscore
	WHERE	tch.matchid = @__matchId
		AND ans.liveindicator = 1
		AND ans.transdate BETWEEN DATEADD(ss, -30, si.LastRejectedTime) AND si.LastRejectedTime
		AND ans.bettype IN (1, 3, 5, 7, 8, 15)
		AND ans.currency NOT IN (20, 27, 28)
		AND ans.statusID IN (101,102,112) -- Reject, Void, WON tickets
	GROUP BY ans.custid
		,	ans.Username
		,	ans.currency
		,	ans.CurrencyName
		,	tch.eventdate
		,	ans.liveawayscore
		,	ans.livehomescore
		,	ans.transid
	OPTION (MAXDOP 1);
		
	-------INSERT SCANNED MATCH: TABLE "ScannedMatch" -------
	IF NOT EXISTS (SELECT TOP(1) 1 FROM dbo.ScannedMatch AS sm WITH (NOLOCK) WHERE sm.matchid = @__matchId AND sm.FraudCaseId = @CurrentFraudCaseId)
	BEGIN
		INSERT INTO dbo.ScannedMatch (Matchid, FraudCaseId, ScannedDate, SuspiciousTicketsCount)  
		SELECT @__matchId, @CurrentFraudCaseId, @ScannedDate, COUNT(1) 
		FROM #tmpFraudTickets WITH (NOLOCK);
	END;

	------- STORE SUSPICIOUS INFO ------- 
	IF EXISTS (SELECT TOP(1) 1 FROM #tmpFraudTickets WITH (NOLOCK))
	BEGIN

		--copying data to temp
		INSERT INTO #tmpFraudTicketsCustInfo (CustId, Username, CurrencyId)
		SELECT DISTINCT ft.Custid, ft.Username, ft.CurrencyId
		FROM #tmpFraudTickets ft WITH (NOLOCK);

		DELETE t
		FROM #tmpFraudTickets t
			INNER JOIN dbo.SuspiciousInfo s WITH(NOLOCK) ON t.CustId = s.CustId
		WHERE s.MatchId = @__matchId AND s.FraudCaseId = @CurrentFraudCaseId
		
		INSERT INTO dbo.SuspiciousInfo(CustId, EventDate, FraudCaseId, SuspiciousDate, TransIds, ViolationCounter, TicketCounter)
		SELECT	[CustId]			= ft.CustId
			,	[EventDate]			= ft.EventDate
			,	[FraudCaseId]		= @CurrentFraudCaseId
			,	[SuspiciousDate]	= @ScannedDate
			,	[TransIds]			=	(
											STUFF((SELECT ',', CONVERT(VARCHAR(15), t1.TransId) 
											FROM #tmpFraudTickets AS t1 WITH(NOLOCK)
											WHERE t1.CustId = ft.CustId
											FOR XML PATH('')), 1, 1, '')
										)
			,	[ViolationCounter] =	(	
											SELECT COUNT(DISTINCT(t2.LiveHomeScore + t2.LiveAwayScore))
											FROM #tmpFraudTickets AS t2 WITH (NOLOCK)
											WHERE t2.CustId = ft.CustId
											GROUP BY t2.CustId
										)
			,	[TicketCounter]		=	(
											SELECT COUNT(t3.TransId)
											FROM #tmpFraudTickets AS t3 WITH (NOLOCK)
											WHERE t3.CustId = ft.CustId
										)
		FROM #tmpFraudTickets ft WITH (NOLOCK)
		GROUP BY ft.CustId, ft.EventDate;
		
		--==
		UPDATE sc WITH (ROWLOCK, UPDLOCK)
		SET sc.IsVerified = 0, sc.Username = t.Username
		FROM dbo.SuspiciousCustomer sc
			INNER JOIN #tmpFraudTicketsCustInfo t ON sc.Custid = t.CustId;

		INSERT INTO dbo.SuspiciousCustomer(Custid, Username, CurrencyId, IsDelinquent, IsHedge, IsDirty, IsVerified)
		SELECT ft.CustId, ft.Username, ft.CurrencyId, 0, 0, 0, 0
		FROM #tmpFraudTicketsCustInfo ft WITH (NOLOCK)
		WHERE ft.CustId NOT IN (SELECT sc.CustId 
								FROM dbo.SuspiciousCustomer sc WITH (NOLOCK));
	END;	
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/