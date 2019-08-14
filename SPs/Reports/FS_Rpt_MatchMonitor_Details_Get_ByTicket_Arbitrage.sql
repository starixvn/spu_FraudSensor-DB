ALTER PROCEDURE [dbo].[FS_Rpt_MatchMonitor_Details_Get_ByTicket_Arbitrage]
		@MatchId					INT
	,	@EventDate					DATETIME
	,	@IsShowSpecialCurrencies	BIT = 0

	,	@LiveStatus					SMALLINT = -1 -- all statuses
	,	@CurrencyIds				VARCHAR(500) = '-1' -- all currencies, separate by comma
	,	@TransDateFrom				DATETIME = NULL
	,	@TransDateTo				DATETIME = NULL
	,	@Bettype					SMALLINT = -1 -- all scoreHDP
	,	@Handicap					MONEY = -1 -- all scoreHDP
	,	@LiveHomeScore				SMALLINT = -1 -- all scoreHDP
	,	@LiveAwayScore				SMALLINT = -1 -- all scoreHDP
	,	@Odds						SMALLMONEY = NULL -- all odds
	,	@Site						VARCHAR(10) = 'CN88' -- '' for all sites
AS
/*
	Created: 20180815@Long.Luu
	Task : Get Tickets by Match & Fraud Case for Arbitrage
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20180815@Long.Luu: Implement Get Tickets by Match & Fraud Case for Arbitrage
		- 20181114@Long.Luu: Adding View Permission on Special Currencies [Redmine ID: #104707]
		- 20190219@John.Ngo: Update logic Special Currencies and seperate Arbitrage [Redmine ID: #99753]
		- 20190403@Long.Luu: Support more filters for Arbitrage fraud case details [Redmine ID: 111069]
		- 20190530@Long.Luu: Support filter by Currencies & Sites [Redmine ID: 114153]
		- 20190725@Long.Luu: CN88 Arbitrage [Redmine ID: 117498]

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON;

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
			GroupId			INT
		,	GraphDBGroupId	INT
		,	TransId			BIGINT
		,	IsIPFraud		BIT
	 );

	CREATE CLUSTERED INDEX #CIX_tmpFraudTickets_TransID ON #tmpFraudTickets (
			TransID			ASC
	);

	IF OBJECT_ID('tempdb..#tmpSiteSusScoreHDPGroup') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSiteSusScoreHDPGroup;
	END;
	
	CREATE TABLE #tmpSiteSusScoreHDPGroup (			
			BetType			INT
		,	Handicap		MONEY
		,	LiveHomeScore	SMALLINT
		,	LiveAwayScore	SMALLINT
		,	GroupId			INT
	);

	CREATE CLUSTERED INDEX #CIX_tmpSiteSusScoreHDPGroup ON #tmpSiteSusScoreHDPGroup (
			BetType			ASC
		,	Handicap		ASC
		,	LiveHomeScore	ASC
		,	LiveAwayScore	ASC
		,	GroupId			ASC
	);

	IF OBJECT_ID('tempdb..#tmpTicketResults') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpTicketResults;
	END;
	
	CREATE TABLE #tmpTicketResults (
			CustId			INT
		,	Username		NVARCHAR(50)
		,	DangerLevel		TINYINT
		,	BettypeId		SMALLINT
		,	TransId			BIGINT
		,	GroupId			INT
		,	GraphDBGroupId	INT
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
		,	CurrencyName	NVARCHAR(50)
		,	FullStake		MONEY
		,	ComPTStake		MONEY
		,	VirtualStake	MONEY
		,	IPAddress		VARCHAR(15)
		,	IsIPFraud		BIT
	 );

	CREATE CLUSTERED INDEX #CIX_tmpTicketResults_TransDate ON #tmpTicketResults (
			TransDate		ASC
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
	 
	IF (@Site <> 'CN88')
	BEGIN
		SELECT @Site = '';
	END;

	--===	2 GET: Balance Up Day and Move Bet Day
	INSERT INTO #tmpBUMB(BUDay,MBDay)
	EXECUTE bodb02.dbo.Age_SelBalanceUpDay;

	DECLARE @IsAfterMoveBetDay BIT = 1;

	SELECT TOP(1) @IsAfterMoveBetDay = 0
	FROM #tmpBUMB WITH(NOLOCK)
	WHERE @EventDate BETWEEN BUDay AND MBDay;
	
	--===	3 GET: Fraud Tickets Insert to #tmpFraudTickets	
	INSERT INTO #tmpSiteSusScoreHDPGroup(BetType, Handicap, LiveHomeScore, LiveAwayScore, GroupId)
	SELECT DISTINCT si.BetType, si.Handicap, si.LiveHomeScore, si.LiveAwayScore, si.GraphDBGroupId
	FROM dbo.ArbitrageTicketDetails si WITH(NOLOCK)
		--INNER JOIN bodb02.dbo.vw_Customer c WITH(NOLOCK) ON si.CustId = c.CustId
		INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK) ON si.CustId = c.CustId
	WHERE si.MatchId = @MatchId
		AND (@Site = '' OR c.Site = @Site);

	INSERT INTO #tmpFraudTickets(GroupId, GraphDBGroupId, TransId, IsIPFraud)
	SELECT si.GroupId, si.GraphDBGroupId, VAL, si.IsIPFraud
	FROM dbo.ArbitrageTicketDetails si WITH(NOLOCK)
		INNER JOIN dbo.SuspiciousCustomer c WITH(NOLOCK) ON si.CustId = c.custid
		INNER JOIN #tmpSiteSusScoreHDPGroup g WITH(NOLOCK) ON si.BetType = g.BetType AND si.Handicap = g.Handicap AND si.LiveHomeScore = g.LiveHomeScore AND si.LiveAwayScore = g.LiveAwayScore AND si.GroupId = g.GroupId
		CROSS APPLY dbo.SPU_StrSplit(si.transids, ',')
	WHERE	si.MatchId = @MatchId
		AND (@Bettype = -1 OR @Handicap = -1 OR @LiveHomeScore = -1 OR @LiveAwayScore = -1 
			OR (si.BetType = @Bettype AND si.Handicap = @Handicap AND si.LiveHomeScore = @LiveHomeScore AND si.LiveAwayScore = @LiveAwayScore)) -- ScoreHDP
		AND (@CurrencyIds = '-1' OR c.CurrencyId IN (SELECT CurrencyId FROM #tmpCurrencyList WITH(NOLOCK)))
		AND (@IsShowSpecialCurrencies = 1 OR c.CurrencyId NOT IN (SELECT CurrencyId FROM dbo.SpecialCurrency WITH(NOLOCK)));
			
	--===	4 GET: Homeid and AwayId
	DECLARE @homeId INT;
	DECLARE @awayId INT;
			
	--===	5 GET: Fraud Tickets Info				
	If @IsAfterMoveBetDay = 1
		BEGIN
			SELECT	@homeId = m.homeid
				,	@awayId = m.awayid
			FROM bodb02.dbo.match m WITH(NOLOCK)
			WHERE m.matchid = @MatchId;
			
			INSERT INTO #tmpTicketResults(CustId, Username,	DangerLevel, BettypeId,	TransId, GroupId, GraphDBGroupId, TransDate, BetId,	BetTeam, Handicap1
				,	Handicap2, LiveHomeScore, LiveAwayScore, IsLive, Odds, OddsType, CurrencyName, FullStake, ComPTStake, VirtualStake, IPAddress, IsIPFraud)
			SELECT	[CustId]		= b.custid
				,	[Username]		= b.Username
				,	[DangerLevel]	= c.danger2 
				,	[BettypeId]		= b.bettype 
				,	[TransId]		= b.Transid
				,	[GroupId]		= f.GroupId
				,	[GraphDBGroupId]= f.GraphDBGroupId 
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
				,	[CurrencyName]	= b.currencyname
				,	[FullStake]		= b.stake * b.actualrate 
				,	[ComPTStake]	= b.stake * (1 - b.tpositiontaking) * b.actualrate 
				,	[VirtualStake]	= b.stake * (1 - b.tpositiontaking) * b.virtualrate
				,	[IPAddress]		= b.ip
				,	[IsIPFraud]		= f.IsIPFraud
			FROM bodb02.dbo.bettrans b WITH(NOLOCK)
				INNER JOIN #tmpFraudTickets f WITH(NOLOCK) ON b.transid = f.TransID
				INNER JOIN bodb02.dbo.custInfo c WITH(NOLOCK) ON b.custid = c.custid
			WHERE b.winlostdate = @EventDate
				AND (@LiveStatus = -1 OR b.liveindicator = @LiveStatus);

		END;
	ELSE
		BEGIN		
			SELECT @homeId = m.homeid
					, @awayId = m.awayid
			FROM bodb02.dbo.match14 m WITH(NOLOCK)
			WHERE m.matchid = @MatchId;
			
			INSERT INTO #tmpTicketResults(CustId, Username,	DangerLevel, BettypeId,	TransId, GroupId, GraphDBGroupId, TransDate, BetId,	BetTeam, Handicap1
				, Handicap2, LiveHomeScore, LiveAwayScore, IsLive, Odds, OddsType, CurrencyName, FullStake, ComPTStake, VirtualStake, IPAddress, IsIPFraud)
			SELECT	[custid]		= b.custid
				,	[Username]		= b.Username
				,	[DangerLevel]	= c.danger2 
				,	[BettypeId]		= b.bettype 
				,	[TransId]		= b.Transid
				,	[GroupId]		= f.GroupId
				,	[GraphDBGroupId]= f.GraphDBGroupId
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
				,	[CurrencyName]	= b.currencyname
				,	[FullStake]		= b.stake * b.actualrate 
				,	[ComPTStake]	= b.stake * (1 - b.tpositiontaking) * b.actualrate 
				,	[VirtualStake]	= b.stake * (1 - b.tpositiontaking) * b.virtualrate
				,	[IPAddress]		= b.ip
				,	[IsIPFraud]		= f.IsIPFraud
			FROM bodb02.dbo.bettrans14 b WITH(NOLOCK)
				INNER JOIN #tmpFraudTickets f WITH(NOLOCK) ON b.transid = f.TransID
				INNER JOIN bodb02.dbo.custInfo c WITH(NOLOCK) ON b.custid = c.custid
			WHERE b.winlostdate = @EventDate
				AND (@LiveStatus = -1 OR b.liveindicator = @LiveStatus);
		END;

	--===	6 RETURN: Fraud Tickets Info				
	SELECT	t.CustId, t.Username, t.DangerLevel, t.BettypeId, t.TransId, t.GroupId, t.GraphDBGroupId, t.TransDate, t.BetId
		,	t.BetTeam, t.Handicap1, t.Handicap2, t.LiveHomeScore, t.LiveAwayScore, t.IsLive, t.Odds
		,	t.OddsType, t.CurrencyName, t.FullStake, t.ComPTStake, t.VirtualStake, t.IPAddress AS [IP], t.IsIPFraud
	FROM #tmpTicketResults t WITH(NOLOCK)
	WHERE (@TransDateFrom IS NULL OR @TransDateTo IS NULL
			OR (t.TransDate BETWEEN @TransDateFrom AND @TransDateTo))
			AND (@Odds IS NULL OR t.Odds >= @Odds);
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/