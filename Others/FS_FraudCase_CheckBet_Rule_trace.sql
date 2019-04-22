GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[FS_FraudCase_CheckBet_Rule] 
AS
/*
	Created: 20180619@LONG
	Task : Rule for Check Bet fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20181114@Long: Split data in SuspiciousInfo by Currency [Redmine ID: #104707]
		- 20181120@Long: Change the way to get data [Redmine ID: #105113]
		- 20181228@Long: Modify to check for completely completed matches only [Redmine ID: #107398]

	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	
	
	----------- DECLARE -----------
	DECLARE @WinlossDate			DATETIME,		
		@CapturedDate				DATETIME;

	DECLARE @CategoryStake			TINYINT,
		@CategoryOdds				TINYINT,
		@CategoryLiveHomeScore		TINYINT,
		@CategoryLiveAwayScore		TINYINT,
		@CategoryTPositionTaking	TINYINT,
		@CategoryMatchId			TINYINT,
		@CategoryStatus				TINYINT,
		@CategoryBetteam			TINYINT,
		@CategoryHdp1				TINYINT,
		@CategoryHdp2				TINYINT;

	IF	OBJECT_ID('tempdb..#tmpMatchesInfo') IS NOT NULL
	BEGIN;
		DROP TABLE	#tmpMatchesInfo;
	END;
	CREATE TABLE #tmpMatchesInfo(
		WinlossDate					DATETIME,
		MatchId						INT,
		HomeId						INT,
		AwayId						INT
    );
	CREATE UNIQUE CLUSTERED INDEX IX_tmpMatchesInfo_Bettype_MatchId ON #tmpMatchesInfo(WinlossDate, MatchId);

	IF	OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
	BEGIN;
		DROP TABLE	#tmpMatches;
	END;
	CREATE TABLE #tmpMatches(
		WinlossDate					DATETIME,
		MatchId						INT
    );
	CREATE UNIQUE CLUSTERED INDEX IX_tmpMatches_Bettype_MatchId ON #tmpMatches(WinlossDate, MatchId);

	IF	OBJECT_ID('tempdb..#tmpSportbooksBettype') IS NOT NULL
	BEGIN;
		DROP TABLE	#tmpSportbooksBettype;
	END;
	CREATE TABLE #tmpSportbooksBettype(
		Bettype				INT,
		EventType			INT,
		SubProduct			VARCHAR(500)
    );
	CREATE UNIQUE CLUSTERED INDEX IX_tmpSportbooksBettype_Bettype ON #tmpSportbooksBettype(Bettype);
	
	IF	OBJECT_ID('tempdb..#tmpChangedTickets') IS NOT NULL
	BEGIN;
		DROP TABLE	#tmpChangedTickets;
	END;
    CREATE TABLE #tmpChangedTickets(
		transid				BIGINT, 
		bettype				INT, 
		original_stake		MONEY
	);
	CREATE UNIQUE CLUSTERED INDEX IX_tmpChangedTickets_TransID_Bettype ON #tmpChangedTickets(transid,bettype);

	IF	OBJECT_ID('tempdb..#tmpCheckBet') IS NOT NULL
	BEGIN;
		DROP TABLE	#tmpCheckBet;
	END;
	CREATE TABLE #tmpCheckBet (
		transid				BIGINT, 
		bettype				INT, 
		isCashOut			BIT, 
		isVoid				BIT, 
		custid				INT, 
		matchid				INT, 
		bettrans_stake		MONEY, 
		bets_stake			MONEY, 
		isOriginal			BIT, 
		isValidTP			TINYINT, 
		isValidOdds			TINYINT, 
		isValidBetteam		TINYINT
	);
	CREATE UNIQUE CLUSTERED INDEX IX_tmpCheckBet_TransID_Bettype ON #tmpCheckBet(transid,bettype);
	
	IF	OBJECT_ID('tempdb..#tmpChangedInfo') IS NOT NULL
	BEGIN;
		DROP TABLE	#tmpChangedInfo;
	END;
	CREATE TABLE #tmpChangedInfo (
		-- General info
		TransId				BIGINT, 
		TransDate			DATETIME,
		CustId				INT,
		Username			NVARCHAR(50),
		MatchId				INT,
		HomeId				INT,
		AwayId				INT,
		Bettype				SMALLINT,
		Oddstype			TINYINT,
		Currency			NVARCHAR(10),
		Creator				INT,
		LiveIndicator		BIT,
		-- Changed info
		NewMatchId			INT,
		OldMatchId			INT, 
		NewStake			MONEY, 
		OldStake			MONEY, 
		NewLiveHomeScore	SMALLINT, 
		OldLiveHomeScore	SMALLINT,
		NewLiveAwayScore	SMALLINT, 
		OldLiveAwayScore	SMALLINT, 
		NewOdds				SMALLMONEY, 
		OldOdds				SMALLMONEY, 
		NewBetteam			NVARCHAR(10), 
		OldBetteam			NVARCHAR(10), 
		NewHdp1				SMALLMONEY, 
		OldHdp1				SMALLMONEY, 
		NewHdp2				SMALLMONEY, 
		OldHdp2				SMALLMONEY,
		NewPT				SMALLMONEY, 
		OldPT				SMALLMONEY,
		NewStatus			NVARCHAR(10), 
		OldStatus			NVARCHAR(10)
	);
	CREATE UNIQUE CLUSTERED INDEX IX_tmpChangedInfo_TransId ON #tmpChangedInfo(TransId);

	----------- INIT -----------
	SELECT @CategoryStake			= 1,
		@CategoryOdds				= 2,
		@CategoryLiveHomeScore		= 3,
		@CategoryLiveAwayScore		= 4,
		@CategoryTPositionTaking	= 5,
		@CategoryMatchId			= 6,
		@CategoryStatus				= 7,
		@CategoryBetteam			= 8,
		@CategoryHdp1				= 9,
		@CategoryHdp2				= 10,
		@CapturedDate				= GETDATE();

	-- Get completed matches to scan
	INSERT INTO #tmpMatchesInfo(WinlossDate, MatchId, HomeId, AwayId)
	SELECT m.eventdate, m.matchid, m.homeid, m.awayid
	FROM bodb02.dbo.match m WITH(NOLOCK)
	WHERE m.eventstatus = 'completed'
	UNION
	SELECT m.eventdate, m.orid, m.teamid, -1
	FROM bodb02.dbo.outright m WITH(NOLOCK)
		INNER JOIN bodb02.dbo.League AS l WITH(NOLOCK) ON m.leagueid = l.leagueid
	WHERE m.status IS NOT NULL
		AND l.sporttype IN (SELECT DISTINCT sbm.sporttype FROM bodb02.dbo.SportBettypeMatrix AS sbm WITH(NOLOCK));

	-- Remove scanned matches
	DELETE FROM #tmpMatchesInfo WITH(ROWLOCK)
	WHERE MatchId IN (	
						SELECT DISTINCT sm.MatchId 
						FROM dbo.CheckBetScannedMatch sm WITH(NOLOCK) 
						WHERE CAST(sm.ScannedDate AS DATE) = CAST(@CapturedDate AS DATE)
					);

	-- Remove matches that still has running tickets
	DELETE FROM #tmpMatchesInfo WITH(ROWLOCK)
	WHERE MatchId IN (	
						SELECT DISTINCT b.MatchId 
						FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
						WHERE b.ruben = 0
					);

	INSERT INTO #tmpSportbooksBettype(Bettype, EventType, SubProduct)
    SELECT Bettype,
		 EventType,
		 SubProduct
    FROM bodb02.dbo.f_SportBettypeMatrix_Sel(1, 0, 0, 2, '', '', 0)
    WHERE ProductID = 1;

    DELETE #tmpSportbooksBettype WITH(ROWLOCK)
    WHERE SubProduct IN ( 'BT-Sold','BT-Bought','BT-Comm', 'BT-Winloss', 'MG-SuperLive');

	INSERT INTO #tmpMatches(MatchId, WinlossDate)
	SELECT DISTINCT c.MatchId, c.WinlossDate
	FROM #tmpMatchesInfo c WITH(NOLOCK);

	INSERT INTO dbo.CheckBetScannedMatch(MatchId, ScannedDate)
	SELECT DISTINCT
		'MatchId'					= c.MatchId,
		'ScannedDate'				= @CapturedDate
	FROM #tmpMatchesInfo c WITH(NOLOCK);
	
	----------- START -----------
	WHILE EXISTS(SELECT TOP(1) 1 FROM #tmpMatches WITH(NOLOCK))
	BEGIN  
		SELECT TOP(1) @WinlossDate = WinlossDate FROM #tmpMatches WITH(NOLOCK);
		
		-- Normal Tickets
		INSERT INTO #tmpChangedTickets (transid, bettype, original_stake)
		SELECT b.transid, b.bettype, b.stake
		FROM bodb02.dbo.bettrans bt WITH(NOLOCK) 
		   INNER JOIN bk.dbo.bets b WITH(NOLOCK) ON bt.transid = b.transid AND bt.MatchId = b.matchid     
		   INNER JOIN #tmpSportbooksBettype s WITH(NOLOCK) ON s.bettype = b.bettype
		   INNER JOIN #tmpMatches m  WITH(NOLOCK) ON bt.matchid = m.matchid
		WHERE m.WinlossDate = @WinlossDate
			AND bt.currency NOT IN (20, 27, 28)
			AND bt.transid NOT IN (SELECT TransId FROM dbo.[ChangedTicket] WITH(NOLOCK))
			AND (bt.stake <> b.stake
				OR bt.livehomescore <> b.livehomescore
				OR bt.liveawayscore <> b.liveawayscore
				OR bt.tpositiontaking <> b.tpositiontaking
				OR bt.odds <> b.odds
				OR bt.betteam <> b.betteam
				OR ((bt.matchid <> b.matchid) AND s.EventType = 2)
				OR bt.hdp1 <> b.hdp1 
				OR bt.hdp2 <> b.hdp2
				);

		-- Reject Tickets
		INSERT INTO #tmpChangedTickets (transid, bettype, original_stake)
		SELECT bt.transid, bt.bettype, bt.stake
		FROM bodb02.dbo.bettrans bt WITH(NOLOCK) 
		   INNER JOIN bk.dbo.betsReject b WITH(NOLOCK) ON bt.transid = b.transid        
		   INNER JOIN #tmpSportbooksBettype s WITH(NOLOCK) ON s.bettype = b.bettype
		   INNER JOIN #tmpMatches m  WITH(NOLOCK) ON bt.matchid = m.matchid
		WHERE m.WinlossDate = @WinlossDate
			AND bt.currency NOT IN (20, 27, 28)
			AND bt.custid <> 98632			
			AND bt.transid NOT IN (SELECT TransId FROM dbo.[ChangedTicket] WITH(NOLOCK))
			AND bt.status <> b.status;
	
		-- Cash Out tickets can make stake is reduced (mean bettrans.stake <> bet.stake), must exclude Cash Out ticket is correct	
		INSERT INTO #tmpCheckBet (transid, bettype, isCashOut, isVoid, custid, matchid, bettrans_stake, bets_stake, isOriginal, isValidTP, isValidOdds, isValidBetteam)
		SELECT bt.transid, 
			bt.bettype, 
			1 AS isCashOut, 
			CASE WHEN bt.statusID IN (102) THEN 1 ELSE 0 END, 
			bt.custid, 
			bt.matchid, 
			bt.stake, 
			b.stake, 
			1 AS isOriginal,
			CASE WHEN bt.tpositiontaking<>b.tpositiontaking THEN 0 ELSE 1 END AS isValidTP,
			CASE WHEN bt.odds<>b.odds THEN 0 ELSE 1 END AS isValidOdds,
			CASE WHEN (bt.betteam <> b.betteam) THEN 0 ELSE 1 END AS isValidBetteam
		FROM bodb02.dbo.bettrans bt WITH(NOLOCK) 
			INNER JOIN bk.dbo.bets b WITH(NOLOCK) ON bt.transid = b.transid        
			INNER JOIN #tmpSportbooksBettype s WITH(NOLOCK) ON s.bettype = b.bettype
			INNER JOIN #tmpMatches m  WITH(NOLOCK) ON bt.matchid = m.matchid
		WHERE m.WinlossDate = @WinlossDate
			AND bt.currency NOT IN (20, 27, 28)
			AND CAST(ExtraInfo AS XML).exist('/p25/@s') = 1
			AND bt.betdaqid = 0;
                
		IF EXISTS (SELECT TOP(1) 1 FROM #tmpCheckBet WITH(NOLOCK))
		BEGIN
			-- Cash Out tickets are valid: get stake from valid bettype 911 -- Valid ticket: exclude void
			IF EXISTS (SELECT TOP(1) 1 FROM #tmpCheckBet WITH(NOLOCK) WHERE isVoid = 0)
			BEGIN
				INSERT INTO #tmpCheckBet (transid, bettype, isCashOut, bettrans_stake, bets_stake, isOriginal, isValidTP, isValidOdds, isValidBetteam)
				SELECT b.refno, 
					-1			AS bettype, 
					1			AS isCashOut, 
					bs.stake	AS bettrans_stake, 
					0			AS bets_stake, 
					0			AS isOriginal,
					CASE WHEN b.tpositiontaking <> bs.tpositiontaking THEN 0 ELSE 1 END AS isValidTP,
					CASE WHEN b.odds <> bs.odds THEN 0 ELSE 1 END AS isValidOdds,
					CASE WHEN (b.betteam <> bs.betteam) THEN 0 ELSE 1 END AS isValidBetteam
				FROM bodb02.dbo.bettrans b WITH(NOLOCK)
					INNER JOIN bk.dbo.bets bs WITH(NOLOCK) ON b.transid = bs.transid
				WHERE EXISTS (SELECT 1 FROM #tmpCheckBet c WITH(NOLOCK) WHERE b.custid = c.custid AND b.matchid = c.matchid AND b.refno = c.transid AND c.isVoid = 0)
					AND b.bettype = 911
					AND b.statusID NOT IN (102);
			END;

			-- Cash Out tickets are invalid: get stake from bettype 911 which is maked invalid when original ticket is invalid
			IF EXISTS (SELECT TOP(1) 1 FROM #tmpCheckBet WITH(NOLOCK) WHERE isVoid = 1)
			BEGIN
				;WITH betcheck AS (
					SELECT zb.transid, 
						zb.betcheck, 
						zb.custid, 
						zb.matchid
					FROM bodb02.dbo.zzzbettrans zb WITH(NOLOCK)
					WHERE EXISTS (SELECT 1 FROM #tmpCheckBet c WITH(NOLOCK) WHERE zb.custid = c.custid AND zb.matchid = c.matchid AND zb.transid = c.transid AND c.isVoid = 1)
					UNION SELECT NULL, NULL, NULL, NULL
				)
				, transid AS (
					SELECT transid
					FROM bodb02.dbo.zzzbettrans zb WITH(NOLOCK)
					WHERE EXISTS (SELECT 1 FROM betcheck b WITH(NOLOCK) WHERE zb.custid = b.custid AND zb.matchid = b.matchid AND zb.refno = b.transid AND zb.betcheck = b.betcheck)
						AND zb.bettype = 911
					UNION SELECT NULL
				)

				INSERT INTO #tmpCheckBet (transid, bettype, isCashOut, bettrans_stake, bets_stake, isOriginal, isValidTP, isValidOdds, isValidBetteam)
				SELECT b.refno, 
					-1			AS bettype,
					1			AS isCashOut, 
					bs.stake	AS bettrans_stake, 
					0			AS bets_stake, 
					0			AS isOriginal,
					CASE WHEN b.tpositiontaking <> bs.tpositiontaking THEN 0 ELSE 1 END AS isValidTP,
					CASE WHEN b.odds <> bs.odds THEN 0 ELSE 1 END AS isValidOdds,
					CASE WHEN (b.betteam <> bs.betteam) THEN 0 ELSE 1 END AS isValidBetteam
				FROM bodb02.dbo.bettrans b WITH(NOLOCK)
					INNER JOIN bk.dbo.bets bs WITH(NOLOCK) ON b.transid = bs.transid
				WHERE EXISTS (SELECT 1 FROM transid t WITH(NOLOCK) WHERE b.transid = t.transid);
			END;
	
			-- Remove all Cash Out tickets from table total
			DELETE ct WITH(ROWLOCK)
			FROM #tmpChangedTickets ct
				INNER JOIN #tmpCheckBet c WITH(NOLOCK) ON ct.transid = c.transid AND ct.bettype = c.bettype;
		
			-- Insert Cash Out tickets are incorrect
			INSERT INTO #tmpChangedTickets (transid, bettype, original_stake)
			SELECT cb.transid, 
				MAX(cb.bettype) AS bettype, 
				SUM(CASE WHEN cb.isOriginal = 1 THEN cb.bets_stake ELSE -cb.bettrans_stake END)  AS original_stake
			FROM #tmpCheckBet cb WITH(NOLOCK)
			WHERE cb.transid NOT IN (SELECT ct.TransId FROM dbo.[ChangedTicket] ct WITH(NOLOCK))
			GROUP BY cb.transid
			HAVING SUM(ISNULL(cb.bettrans_stake, 0) - ISNULL(cb.bets_stake, 0)) <> 0
				OR MIN(ISNULL(cb.isValidTP, 0)) = 0
				OR MIN(ISNULL(cb.isValidOdds, 0)) = 0
				OR MIN(ISNULL(cb.isValidBetteam, 0)) = 0;
		END;
		
		--Check ticket of sport book, racing, numbergame, virtual sports but Casino, P2P, Live CS, Bingo	
		INSERT INTO #tmpChangedInfo(
				TransId
			,	TransDate
			,	CustId
			,	Username
			,	MatchId
			,	HomeId
			,	AwayId
			,	Bettype
			,	Oddstype
			,	Creator
			,	LiveIndicator
			,	Currency
			,	NewMatchId
			,	OldMatchId
			,	NewStake
			,	OldStake
			,	NewLiveHomeScore
			,	OldLiveHomeScore
			,	NewLiveAwayScore
			,	OldLiveAwayScore
			,	NewOdds
			,	OldOdds
			,	NewBetteam
			,	OldBetteam
			,	NewHdp1
			,	OldHdp1
			,	NewHdp2
			,	OldHdp2
			,	NewPT
			,	OldPT
			,	NewStatus
			,	OldStatus
		)
		SELECT  'TransId'		= bt.transid,
			'TransDate'			= b.transdate,
			'CustId'			= bt.custid,
			'Username'			= bt.username,
			'MatchId'			= bt.matchid,
			'HomeId'			= 0,
			'AwayId'			= 0,
			'Bettype'			= bt.bettype,
			'Oddstype'			= bt.oddstype,
			'Creator'			= bt.creator,
			'LiveIndicator'		= bt.liveindicator,
			'Currency'			= bt.CurrencyName,
			'NewMatchId'		= bt.matchid,
			'OldMatchId'		= b.matchid,
			'NewStake'			= bt.stake, 
			'OldStake'			= t.original_stake,
			'NewLiveHomeScore'	= bt.livehomescore, 
			'OldLiveHomeScore'	= b.livehomescore,
			'NewLiveAwayScore'	= bt.liveawayscore, 
			'OldLiveAwayScore'	= b.liveawayscore,
			'NewOdds'			= bt.odds,
			'OldOdds'			= b.odds,
			'NewBetteam'		= bt.betteam,
			'OldBetteam'		= b.betteam,
			'NewHdp1'			= bt.hdp1,
			'OldHdp1'			= b.hdp1,
			'NewHdp2'			= bt.hdp2,
			'OldHdp2'			= b.hdp2,
			'NewPT'				= bt.tpositiontaking,
			'OldPT'				= b.tpositiontaking,
			'NewStatus'			= bt.status,
			'OldStatus'			= ISNULL(r.status, bt.status)
		FROM bodb02.dbo.bettrans bt WITH(NOLOCK)
			INNER JOIN bk.dbo.bets b WITH(NOLOCK) ON bt.transid = b.transid
			LEFT JOIN bk.dbo.betsreject r WITH (NOLOCK) ON bt.transid = r.transid
			INNER JOIN #tmpChangedTickets t WITH(NOLOCK) ON bt.transid = t.transid AND bt.bettype=t.bettype
			INNER JOIN bodb02.dbo.custinfo c WITH(NOLOCK) ON bt.creator = c.custid		
			INNER JOIN #tmpSportbooksBettype s WITH(NOLOCK) ON s.bettype = b.bettype;

		DELETE FROM #tmpMatches WITH(ROWLOCK)
		WHERE WinlossDate = @WinlossDate;

		TRUNCATE TABLE #tmpChangedTickets;
		TRUNCATE TABLE #tmpCheckBet;

	END;

	----------- STORE GENERAL INFO -----------
	INSERT INTO dbo.[ChangedTicketGeneralInfo](TransId, TransDate, Currency, Username, Creator, MatchId, HomeId, AwayId, Oddstype, CustId, Bettype, LiveIndicator)
	SELECT DISTINCT ct.TransId, ct.TransDate, ct.Currency, ct.Username, c.username, ct.MatchId, m.homeid, m.awayid, ct.Oddstype, ct.CustId, ct.Bettype, ct.LiveIndicator
	FROM #tmpChangedInfo AS ct WITH(NOLOCK)
		INNER JOIN #tmpMatchesInfo AS m WITH (NOLOCK) ON ct.MatchId = m.matchid		
		INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK) ON c.custid = ct.Creator;

	----------- STORE CHANGED INFO -----------
	INSERT INTO dbo.[ChangedTicket](CategoryId, TransId, CapturedDate, NewValue, OldValue, OldCaptureDate)
	SELECT 'CategoryId'		= @CategoryStake,
		'TransId'			= c.TransId,
		'CapturedDate'		= @CapturedDate,
		'NewValue'			= c.NewStake,
		'OldValue'			= c.OldStake,
		'OldCaptureDate'	= c.TransDate
	FROM #tmpChangedInfo c WITH(NOLOCK);

	INSERT INTO dbo.[ChangedTicket](CategoryId, TransId, CapturedDate, NewValue, OldValue, OldCaptureDate)
	SELECT 'CategoryId'		= @CategoryOdds,
		'TransId'			= c.TransId,
		'CapturedDate'		= @CapturedDate,
		'NewValue'			= c.NewOdds,
		'OldValue'			= c.OldOdds,
		'OldCaptureDate'	= c.TransDate
	FROM #tmpChangedInfo c WITH(NOLOCK);

	INSERT INTO dbo.[ChangedTicket](CategoryId, TransId, CapturedDate, NewValue, OldValue, OldCaptureDate)
	SELECT 'CategoryId'		= @CategoryLiveHomeScore,
		'TransId'			= c.TransId,
		'CapturedDate'		= @CapturedDate,
		'NewValue'			= c.NewLiveHomeScore,
		'OldValue'			= c.OldLiveHomeScore,
		'OldCaptureDate'	= c.TransDate
	FROM #tmpChangedInfo c WITH(NOLOCK);

	INSERT INTO dbo.[ChangedTicket](CategoryId, TransId, CapturedDate, NewValue, OldValue, OldCaptureDate)
	SELECT 'CategoryId'		= @CategoryLiveAwayScore,
		'TransId'			= c.TransId,
		'CapturedDate'		= @CapturedDate,
		'NewValue'			= c.NewLiveAwayScore,
		'OldValue'			= c.OldLiveAwayScore,
		'OldCaptureDate'	= c.TransDate
	FROM #tmpChangedInfo c WITH(NOLOCK);

	INSERT INTO dbo.[ChangedTicket](CategoryId, TransId, CapturedDate, NewValue, OldValue, OldCaptureDate)
	SELECT 'CategoryId'		= @CategoryTPositionTaking,
		'TransId'			= c.TransId,
		'CapturedDate'		= @CapturedDate,
		'NewValue'			= c.NewPT,
		'OldValue'			= c.OldPT,
		'OldCaptureDate'	= c.TransDate
	FROM #tmpChangedInfo c WITH(NOLOCK);

	INSERT INTO dbo.[ChangedTicket](CategoryId, TransId, CapturedDate, NewValue, OldValue, OldCaptureDate)
	SELECT 'CategoryId'		= @CategoryMatchId,
		'TransId'			= c.TransId,
		'CapturedDate'		= @CapturedDate,
		'NewValue'			= c.NewMatchId,
		'OldValue'			= c.OldMatchId,
		'OldCaptureDate'	= c.TransDate
	FROM #tmpChangedInfo c WITH(NOLOCK);

	INSERT INTO dbo.[ChangedTicket](CategoryId, TransId, CapturedDate, NewValue, OldValue, OldCaptureDate)
	SELECT 'CategoryId'		= @CategoryStatus,
		'TransId'			= c.TransId,
		'CapturedDate'		= @CapturedDate,
		'NewValue'			= c.NewStatus,
		'OldValue'			= c.OldStatus,
		'OldCaptureDate'	= c.TransDate
	FROM #tmpChangedInfo c WITH(NOLOCK);

	INSERT INTO dbo.[ChangedTicket](CategoryId, TransId, CapturedDate, NewValue, OldValue, OldCaptureDate)
	SELECT 'CategoryId'		= @CategoryBetteam,
		'TransId'			= c.TransId,
		'CapturedDate'		= @CapturedDate,
		'NewValue'			= c.NewBetteam,
		'OldValue'			= c.OldBetteam,
		'OldCaptureDate'	= c.TransDate
	FROM #tmpChangedInfo c WITH(NOLOCK);

	INSERT INTO dbo.[ChangedTicket](CategoryId, TransId, CapturedDate, NewValue, OldValue, OldCaptureDate)
	SELECT 'CategoryId'		= @CategoryHdp1,
		'TransId'			= c.TransId,
		'CapturedDate'		= @CapturedDate,
		'NewValue'			= c.NewHdp1,
		'OldValue'			= c.OldHdp1,
		'OldCaptureDate'	= c.TransDate
	FROM #tmpChangedInfo c WITH(NOLOCK);

	INSERT INTO dbo.[ChangedTicket](CategoryId, TransId, CapturedDate, NewValue, OldValue, OldCaptureDate)
	SELECT 'CategoryId'		= @CategoryHdp2,
		'TransId'			= c.TransId,
		'CapturedDate'		= @CapturedDate,
		'NewValue'			= c.NewHdp2,
		'OldValue'			= c.OldHdp2,
		'OldCaptureDate'	= c.TransDate
	FROM #tmpChangedInfo c WITH(NOLOCK);
END;
