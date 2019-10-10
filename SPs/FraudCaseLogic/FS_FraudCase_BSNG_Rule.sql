ALTER PROCEDURE [dbo].[FS_FraudCase_BSNG_Rule] 
	@MatchId		INT = NULL
AS
/*
	Created: 20180306@Long
	Task : Rule for Big Stake Near The Goal fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions:	
		- 20180321@Long: Support ViolationCounter & TicketCounter [Redmine ID: 92293]
		- 20180316@Casey: 
			+ Update get Oddslog from bodb_FraudSensor instead of "SPU_FraudDetection"
			+ Update Calculate Violation BSNG Rule: count 1 per each score
		- 20180406@Long: remove ticket status to scan for running matches
		- 20180312@CaseyHuynh: Correct Code Syntax
		- 20190219@Long: Store more info (Currency & Username) for table SuspiciousCutomers [Redmine ID: 107858]
		- 20190319@Casey.Huynh: Enhance Performance table #tmpFraudTickets [Redmine ID: 110060]
		- 20190320@Casey.Huynh: Enhance Performance, define PRIMARY KEY in table [Redmine ID: 110060]
		- 20190329@Casey.Huynh: Implement Completed Match when the score is rejected: Add code update table MatchScore completed Status to sp rule [Redmine ID: 111079]
		- 20190503@Long.Luu:	Fix the buffer issue with "big" Fraud Cases [Redmine ID: 112706]
		- 20190624@John.Ngo:	Remove Curreny Name on FS DB and use ID instead [Redmine ID: 115326]
		- 20190925@Long.Luu:	Change seconds to the goal [Redmine ID: 120881]
		- 20191010@Long.Luu:	Change input param [Redmine ID: 118117]

	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	

	DECLARE @CurrentFraudCaseId TINYINT;
	SET @CurrentFraudCaseId = 1; -- BSNG

	DECLARE @__matchId INT
	SET @__matchId = @MatchId
	
	DECLARE @ScannedDate DATETIME;
	SET	@ScannedDate = GETDATE();
	
	-- Arrange tables and initialize
	IF OBJECT_ID('tempdb..#tmpBettype') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpBettype;
	END
	
	CREATE TABLE #tmpBettype(
		Bettype			INT PRIMARY KEY
	);

	-- Arrange tables and initialize
	IF OBJECT_ID('tempdb..#tmpLastTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpLastTickets;
	END

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
			CustId				ASC
		,	TransId				ASC
		)
	);
	
	IF OBJECT_ID('tempdb..#tmpFraudTicketsCustInfo') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTicketsCustInfo;
	END
	
	CREATE TABLE #tmpFraudTicketsCustInfo(
			CustId				INT NOT NULL PRIMARY KEY CLUSTERED
		,	Username			NVARCHAR(50)
		,	CurrencyId			TINYINT
	);

	-------------------------------------

	IF OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatches;
	END

	CREATE TABLE #tmpMatches
	(
			MatchId				INT NOT NULL PRIMARY KEY CLUSTERED
		,	EventDate			DATETIME
		,	EventStatus			NVARCHAR(50)
		,	CurrentScore		TINYINT
	);

	-------GET BETTYPE--------------------------------
	INSERT INTO #tmpBettype (Bettype)
	SELECT DISTINCT bettype
	FROM	bodb02.dbo.SportBettypeMatrix WITH(NOLOCK)
	WHERE	SportType = 1 ;
	
	--- Get Info of Match -- Only Scan for Score less than currentScore
	INSERT INTO #tmpMatches(MatchId, EventDate, EventStatus, CurrentScore)
	SELECT @__matchId, m.eventdate, m.eventstatus, (m.livehomescore + liveawayscore)
	FROM bodb02.dbo.Match AS m WITH (NOLOCK)
	WHERE m.MatchId = @__matchId;
	
	--- GET THE LAST REJECT TIME OF PREVIOUS SCORE		
	INSERT INTO dbo.BSNGScanInfo (MatchId, EventDate, EventStatus, LiveHomeScore, LiveAwayScore, LastRejectedTicket, LastRejectedTime, HasScanned)
	SELECT	ms.MatchId
		,	ms.EventDate
		,	ms.EventStatus
		,	b.livehomescore
		,	b.liveawayscore
		,	MAX(transid) AS [TransId]
		,	MAX(TransDate) AS [DeleteTime]	
		,	0	
	FROM	bodb02.dbo.bettrans AS b WITH(NOLOCK)
		INNER JOIN #tmpBettype AS bt WITH(NOLOCK) ON b.bettype = bt.Bettype
		INNER JOIN #tmpMatches AS ms WITH(NOLOCK) ON b.matchid = ms.MatchId
		LEFT JOIN dbo.BSNGScanInfo AS si WITH(NOLOCK) ON si.MatchId = ms.MatchId
				AND si.livehomescore = b.livehomescore
				AND si.LiveAwayScore = b.liveawayscore
	WHERE b.liveindicator = 1
		AND b.statusID = 101
		AND (b.livehomescore + b.liveawayscore) < ms.CurrentScore
		AND si.MatchId IS NULL
	GROUP BY ms.MatchId
		,	ms.EventDate
		,	ms.EventStatus
		,	b.livehomescore
		,	b.liveawayscore;
		
	--- GET FRAUD TICKETS
	INSERT INTO #tmpFraudTickets (CustId, Username, CurrencyId, CurrencyName, EventDate, TransId, LiveHomeScore, LiveAwayScore)
	SELECT  [CustId]			= bt.custid
		,	[Username]			= bt.Username
		,	[CurrencyId]		= bt.currency
		,	[CurrencyName]		= bt.CurrencyName
		,	[EventDate]			= bt.eventdate
		,	[TransId]			= bt.transid
		,	[LiveHomeScore]		= bt.liveawayscore
		,	[LiveAwayScore]		= bt.livehomescore
	FROM (
		SELECT  ans.custid
			,	ans.username
			,	ans.currency
			,	ans.CurrencyName
			,	tch.eventdate
			,	ans.transid
			,	ans.liveawayscore
			,	ans.livehomescore
			,	SUM(ans.stake * ans.actualrate) OVER (
					PARTITION BY ans.custid
						, ans.bettype
						, ans.liveawayscore
						,ans.livehomescore
				) AS TotalStake
			,	40 * 0.01 * COALESCE(dds.maxbet, 0) AS MaxBet
		FROM bodb02.dbo.match AS tch WITH (NOLOCK)
			INNER JOIN bodb02.dbo.bettrans AS ans WITH (NOLOCK) ON tch.matchid = ans.matchid
			INNER JOIN dbo.BSNGScanInfo AS si WITH(NOLOCK) ON si.matchid = ans.matchid
			CROSS APPLY (
				SELECT TOP(1) l.Maxbet
				FROM bodb_FraudSensor.dbo.OddsLog AS l WITH (NOLOCK)
				WHERE l.oddsid = ans.oddsid
					AND l.logdate < ans.transdate
				ORDER BY l.logdate DESC
			) dds
		WHERE  tch.matchid = @__matchId
			AND ans.liveindicator = 1
			AND ans.transdate BETWEEN DATEADD(ss, -180, si.LastRejectedTime) AND si.LastRejectedTime
			AND ans.livehomescore = si.livehomescore
			AND ans.liveawayscore = si.liveawayscore
			AND ans.bettype IN (1, 3, 5, 7, 8, 15)
			AND ans.currency NOT IN (20, 27, 28)
			AND si.HasScanned = 0
		GROUP BY ans.custid
			,	ans.username
			,	ans.currency
			,	ans.CurrencyName
			,	tch.eventdate
			,	ans.transid
			,	ans.liveawayscore
			,	ans.livehomescore
			,	dds.maxbet
			,	ans.bettype
			,	ans.stake
			,	ans.actualrate
		) bt
	WHERE bt.TotalStake >= bt.Maxbet
	OPTION (MAXDOP 1);
	
	--===4. UPDATE: TABLE "ScannedMatch" (ScannedDate,SuspiciousTicketsCount)===========	
	UPDATE	sm WITH (ROWLOCK, UPDLOCK)
	SET		sm.ScannedDate = @ScannedDate
		,	sm.SuspiciousTicketsCount = sm.SuspiciousTicketsCount + ISNULL((SELECT COUNT(1) FROM #tmpFraudTickets AS t1 WITH (NOLOCK)), 0)
	FROM dbo.ScannedMatch AS sm
	WHERE sm.MatchId = @__matchId
		AND sm.FraudCaseId = @CurrentFraudCaseId;
	
	--===5. INSERT SCANNED MATCH: TABLE "ScannedMatch" (ScannedDate,SuspiciousTicketsCount)===========		
	IF NOT EXISTS (SELECT TOP(1) 1 FROM dbo.ScannedMatch AS sm WITH (NOLOCK) WHERE sm.matchid = @__matchId AND sm.FraudCaseId = @CurrentFraudCaseId)
	BEGIN
		INSERT INTO dbo.ScannedMatch (Matchid, FraudCaseId, ScannedDate, SuspiciousTicketsCount)  
		SELECT @__matchId, @CurrentFraudCaseId, @ScannedDate, COUNT(1) 
		FROM #tmpFraudTickets WITH (NOLOCK);
	END;

	-- Check the results and store/return data
	IF EXISTS (SELECT TOP(1) 1 FROM #tmpFraudTickets WITH (NOLOCK))
	BEGIN
		
		DECLARE @__updatedTmp TABLE (custId INT)

		--===5.2. Copying data to temp
		INSERT INTO #tmpFraudTicketsCustInfo (CustId, Username, CurrencyId)
		SELECT DISTINCT ft.Custid, ft.Username, ft.CurrencyId
		FROM #tmpFraudTickets AS ft WITH (NOLOCK);

		--===6. UPDATE: TABLE "SuspiciousInfo" if (Match,Custid,FrauseCase) is Exitsing
		UPDATE si WITH (ROWLOCK, UPDLOCK)
		SET si.SuspiciousDate	= @ScannedDate
			,	si.TransIds	= si.TransIds + ','+ STUFF((SELECT ',', CONVERT(VARCHAR(15), t1.TransId) 
										FROM #tmpFraudTickets AS t1 WITH (NOLOCK)
										WHERE t1.CustId = ft.CustId
										FOR XML PATH('')), 1, 1, '')
			,	si.TicketCounter = si.TicketCounter + (SELECT COUNT(1) 
														FROM #tmpFraudTickets AS t1 WITH (NOLOCK)
														WHERE t1.CustId = ft.CustId)
			,	si.IsVerified = 0
			,	si.ViolationCounter = si.ViolationCounter + (SELECT COUNT(1)
									FROM (SELECT t2.LiveHomeScore, t2.LiveAwayScore
									FROM #tmpFraudTickets AS t2 WITH (NOLOCK)
									WHERE t2.CustId = ft.CustId
									GROUP BY t2.LiveHomeScore, t2.LiveAwayScore) AS A)
		OUTPUT inserted.CustId INTO @__updatedTmp(custId)
		FROM dbo.SuspiciousInfo AS si 
			INNER JOIN #tmpFraudTickets AS ft WITH (NOLOCK) ON si.CustId = ft.CustId
		WHERE si.matchId = @__matchId AND si.FraudCaseId = @CurrentFraudCaseId
		
		IF @@ROWCOUNT > 0
		BEGIN
			DELETE FROM #tmpFraudTickets
			WHERE CustId IN (SELECT t.custId FROM @__updatedTmp t)
		END
		
		--===7. INSERT: TABLE "SuspiciousInfo" if (Match,Custid,FrauseCase) is Exitsing
		INSERT INTO dbo.SuspiciousInfo(CustId, MatchId, EventDate, FraudCaseId, SuspiciousDate, TransIds, ViolatiONCounter, TicketCounter)
			SELECT	[CustId]			= ft.CustId
				,	[MatchId]			= @__matchId
				,	[EventDate]			= ft.EventDate
				,	[FraudCaseId]		= @CurrentFraudCaseId
				,	[SuspiciousDate]	= @ScannedDate
				,	[TransIds]			= STUFF((SELECT ',', CONVERT(VARCHAR(15), t1.TransId) 
											 FROM #tmpFraudTickets AS t1 WITH(NOLOCK)
											 WHERE t1.CustId = ft.CustId
											 FOR XML PATH('')), 1, 1, '')
				,	ViolationCounter = (SELECT COUNT(1)
										FROM (SELECT t2.LiveHomeScore, t2.LiveAwayScore
										FROM #tmpFraudTickets AS t2 WITH (NOLOCK)
										WHERE t2.CustId = ft.CustId
										GROUP BY t2.LiveHomeScore,t2.LiveAwayScore) AS A)
				,	[TicketCounter]		= COUNT(1)
			FROM #tmpFraudTickets AS ft WITH (NOLOCK)
			GROUP BY ft.CustId, ft.EventDate;
	
		--===8. UPDATE: TABLE "SuspiciousCustomer" IsVerified=0 if has new Fraud Tickets)
		UPDATE sc WITH (ROWLOCK, UPDLOCK)
		SET sc.IsVerified = 0, sc.Username = t.Username
		FROM dbo.SuspiciousCustomer AS sc 
			INNER JOIN #tmpFraudTicketsCustInfo AS t WITH(NOLOCK) ON sc.Custid = t.CustId;

		--===9. INSERT: TABLE "SuspiciousCustomer" if NOT Exitsing Custid
		INSERT INTO dbo.SuspiciousCustomer(Custid, Username, CurrencyId, IsDelinquent, IsHedge, IsDirty, IsVerified)
		SELECT ft.CustId, ft.Username, ft.CurrencyId, 0, 0, 0, 0
		FROM #tmpFraudTicketsCustInfo AS ft WITH (NOLOCK)
		WHERE ft.CustId NOT IN (SELECT sc.CustId 
								FROM dbo.SuspiciousCustomer AS sc WITH (NOLOCK));
	END;
	
	--- UPDATE SCANNING STATUS: BSNGScanInfo 
	UPDATE si WITH(ROWLOCK, UPDLOCK)
	SET		si.HasScanned = 1, si.ScannedDate = @ScannedDate
	FROM	dbo.BSNGScanInfo AS si
	WHERE	si.MatchId = @__matchId AND si.HasScanned = 0;	

	--- UPDATE SCANNING STATUS: MatchScore, FOR COMPLETED MATCH
	UPDATE		ms 
	SET			ms.HasScanned = 1
				, ms.EventStatus = 'Completed'
				, ms.UpdatedDate = @ScannedDate
				, ms.TotalScores = m.CurrentScore
	FROM		dbo.MatchScore AS ms WITH (ROWLOCK, UPDLOCK)
	INNER JOIN	#tmpMatches AS m WITH (NOLOCK)
				ON ms.MatchId = m.MatchId
	WHERE		ms.HasScanned = 0
				AND m.EventStatus = 'Completed';
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/