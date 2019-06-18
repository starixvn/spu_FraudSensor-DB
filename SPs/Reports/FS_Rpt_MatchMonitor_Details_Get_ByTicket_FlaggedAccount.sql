CREATE PROCEDURE [dbo].[FS_Rpt_MatchMonitor_Details_Get_ByTicket_FlaggedAccount]
		@MatchId					INT
	,	@EventDate					DATETIME
	,	@IsShowSpecialCurrencies	BIT = 0

	,	@LiveStatus					SMALLINT = -1 -- All Status
	,	@CurrencyIds				VARCHAR(500) = '-1' -- All currencies, separate by comma
	,	@TransDateFrom				DATETIME = NULL
	,	@TransDateTo				DATETIME = NULL
	,	@Bettype					SMALLINT = -1 -- All

AS
/*
	Created: 20190613@John.Ngo
	Task : Get Tickets by Match & Fraud Case for Arbitrage
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20190613@John.Ngo: Support filter for Flagged Account FraudCase [Redmine ID: 113868]

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @FraudCaseId		TINYINT = 6 -- Flagged Account
		,	@IsAfterMoveBetDay	BIT		= 1
		,	@HomeId				INT
		,	@AwayId				INT;

	--===	1.1 INITIAL TEMP TABLES #tmpBUMB: Include Balance Up and Move Bet Days	
	IF OBJECT_ID('tempdb..#tmpBUMB') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpBUMB;
	END;
	
	CREATE TABLE #tmpBUMB (
			BUDay		SMALLDATETIME
		,	MBDay		SMALLDATETIME
	 );
	 
	 --===	1.2 INITIAL: TEMP TABLES #tmpFraudTickets: GET Fraud Tickets
	IF OBJECT_ID('tempdb..#tmpFraudTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTickets;
	END;
	
	CREATE TABLE #tmpFraudTickets (
			TransId		BIGINT
	 );

	CREATE CLUSTERED INDEX #CIX_tmpFraudTickets_TransID ON #tmpFraudTickets (
			TransId			ASC
	);

	IF OBJECT_ID('tempdb..#tmpTicketResults') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpTicketResults;
	END;
	
	CREATE TABLE #tmpTicketResults (
			CustId			INT
		,	Username		NVARCHAR(50)
		,	CurrencyName	NVARCHAR(50)
		,	DangerLevel		TINYINT
		,	BettypeId		SMALLINT
		,	TransId			BIGINT
		,	TransDate		DATETIME
		,	BetId			BIGINT
		,	BetTeam			NVARCHAR(10)
		,	Handicap1		SMALLMONEY
		,	Handicap2		SMALLMONEY
		,	LiveHomeScore	SMALLINT
		,	LiveAwayScore	SMALLINT
		,	IsLive			BIT
		,	Odds			SMALLMONEY
		,	OddsType		TINYINT
		,	Stake			MONEY
		,	Winlost			MONEY
		,	[Status]		NVARCHAR(10)
		,	IP				NVARCHAR(15)
	 );

	IF OBJECT_ID('tempdb..#tmpCurrencyList') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCurrencyList;
	END;
	
	CREATE TABLE #tmpCurrencyList (
			CurrencyId		INT PRIMARY KEY
	 );

	INSERT INTO #tmpCurrencyList(CurrencyId)
	SELECT VAL
	FROM dbo.SPU_StrSplit(@CurrencyIds, ',');

	--===	2 GET: Balance Up Day and Move Bet Day
	INSERT INTO #tmpBUMB(BUDay,MBDay)
	EXECUTE bodb02.dbo.Age_SelBalanceUpDay;

	SELECT TOP(1) @IsAfterMoveBetDay = 0
	FROM #tmpBUMB WITH(NOLOCK)
	WHERE @EventDate BETWEEN BUDay AND MBDay;
	
	--===	3 GET: Fraud Tickets Insert to #tmpFraudTickets	
	INSERT INTO #tmpFraudTickets(TransId)
	SELECT VAL
	FROM dbo.SuspiciousInfo si WITH(NOLOCK)
		INNER JOIN dbo.SuspiciousCustomer c WITH(NOLOCK) ON si.CustId = c.custid
		CROSS APPLY dbo.SPU_StrSplit(si.transids, ',')
	WHERE	si.MatchId = @MatchId
		AND si.FraudCaseId = @FraudCaseId
		AND (@CurrencyIds = '-1' OR c.CurrencyId IN (SELECT CurrencyId FROM #tmpCurrencyList WITH(NOLOCK)))
		AND (@IsShowSpecialCurrencies = 1 OR c.CurrencyId NOT IN (SELECT CurrencyId FROM dbo.SpecialCurrency WITH(NOLOCK)));
			
	--===	4 GET: Fraud Tickets Info				
	If @IsAfterMoveBetDay = 1
		BEGIN
			SELECT	@HomeId = m.homeid
				,	@AwayId = m.awayid
			FROM bodb02.dbo.match m WITH(NOLOCK)
			WHERE m.matchid = @MatchId;
			
			INSERT INTO #tmpTicketResults(CustId, Username,	CurrencyName, DangerLevel, BettypeId, TransId, TransDate, BetId, BetTeam, Handicap1
				,	Handicap2, LiveHomeScore, LiveAwayScore, IsLive, Odds, OddsType, Stake, Winlost, [Status], IP)
			SELECT	[CustId]		= b.custid
				,	[Username]		= b.Username
				,	[CurrencyName]	= b.CurrencyName
				,	[DangerLevel]	= c.danger2 
				,	[BettypeId]		= b.bettype 
				,	[TransId]		= b.Transid
				,	[TransDate]		= b.transdate
				,	[BetId]			= b.betid
				,	[BetTeam]		= b.betteam
				,	[Handicap1]		= b.hdp1	
				,	[Handicap2]		= b.hdp2	
				,	[LiveHomeScore] = ISNULL(b.livehomescore,0) 
				,	[LiveAwayScore] = ISNULL(b.liveawayscore,0) 
				,	[IsLive]		= b.liveindicator 
				,	[Odds]			= b.odds
				,	[OddsType]		= b.oddstype
				,	[Stake]			= b.stake
				,	[Winlost]		= (CASE WHEN b.statusID IN (111,112,113) THEN (b.winlost-b.actual_stake )
											ELSE 0	END)
				,	[Status]		= b.[status]
				,   [IP]			= ISNULL(b.IP,'')
			FROM bodb02.dbo.bettrans b WITH(NOLOCK)
				INNER JOIN #tmpFraudTickets f WITH(NOLOCK) ON b.transid = f.TransID
				INNER JOIN bodb02.dbo.custInfo c WITH(NOLOCK) ON b.custid = c.custid
			WHERE b.winlostdate = @EventDate
				AND (@LiveStatus = -1 OR b.liveindicator = @LiveStatus)
				AND (@Bettype = -1 OR b.bettype = @Bettype);

		END;
	ELSE
		BEGIN		
			SELECT @HomeId = m.homeid
				,  @AwayId = m.awayid
			FROM bodb02.dbo.match14 m WITH(NOLOCK)
			WHERE m.matchid = @MatchId;
			
			INSERT INTO #tmpTicketResults(CustId, Username,	CurrencyName, DangerLevel, BettypeId, TransId, TransDate, BetId, BetTeam, Handicap1
				,	Handicap2, LiveHomeScore, LiveAwayScore, IsLive, Odds, OddsType, Stake, Winlost, [Status], IP)
			SELECT	[CustId]		= b.custid
				,	[Username]		= b.Username
				,	[CurrencyName]	= b.CurrencyName
				,	[DangerLevel]	= c.danger2 
				,	[BettypeId]		= b.bettype 
				,	[TransId]		= b.Transid
				,	[TransDate]		= b.transdate
				,	[BetId]			= b.betid
				,	[BetTeam]		= b.betteam
				,	[Handicap1]		= b.hdp1	
				,	[Handicap2]		= b.hdp2	
				,	[LiveHomeScore] = ISNULL(b.livehomescore,0) 
				,	[LiveAwayScore] = ISNULL(b.liveawayscore,0) 
				,	[IsLive]		= b.liveindicator 
				,	[Odds]			= b.odds
				,	[OddsType]		= b.oddstype
				,	[Stake]			= b.stake
				,	[Winlost]		= (CASE WHEN b.statusID IN (111,112,113) THEN (b.winlost-b.actual_stake )
											ELSE 0	END)
				,	[Status]		= b.[status]
				,   [IP]			= ISNULL(b.IP,'')
			FROM bodb02.dbo.bettrans14 b WITH(NOLOCK)
				INNER JOIN #tmpFraudTickets f WITH(NOLOCK) ON b.transid = f.TransID
				INNER JOIN bodb02.dbo.custInfo c WITH(NOLOCK) ON b.custid = c.custid
			WHERE b.winlostdate = @EventDate
				AND (@LiveStatus = -1 OR b.liveindicator = @LiveStatus)
				AND (@Bettype = -1 OR b.bettype = @Bettype);
		END;

	--===	5 RETURN: Fraud Tickets Info
	SELECT	t.CustId, t.Username, t.CurrencyName, t.DangerLevel, t.BettypeId, t.TransId, t.TransDate, t.BetId
		,	t.BetTeam, t.Handicap1, t.Handicap2, t.LiveHomeScore, t.LiveAwayScore, t.IsLive, t.Odds
		,	t.OddsType, t.Stake, t.Winlost, t.[Status], t.IP
	FROM #tmpTicketResults t WITH(NOLOCK)
	WHERE (@TransDateFrom IS NULL OR @TransDateTo IS NULL
	   OR (t.TransDate BETWEEN @TransDateFrom AND @TransDateTo));
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/