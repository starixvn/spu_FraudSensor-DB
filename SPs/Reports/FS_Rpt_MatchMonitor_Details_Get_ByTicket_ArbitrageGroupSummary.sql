ALTER PROCEDURE [dbo].[FS_Rpt_MatchMonitor_Details_Get_ByTicket_ArbitrageGroupSummary]
		@MatchId					INT
	,	@EventDate					DATETIME
	,	@IsShowSpecialCurrencies	BIT = 0
	,	@CustomerList				NVARCHAR(MAX) = NULL -- xml format

	,	@LiveStatus					SMALLINT = -1 -- all statuses
	,	@CurrencyId					SMALLINT = -1 -- all currencies
	,	@TransDateFrom				DATETIME = NULL
	,	@TransDateTo				DATETIME = NULL
	,	@Bettype					SMALLINT = -1 -- all scoreHDP
	,	@Handicap					MONEY = -1 -- all scoreHDP
	,	@LiveHomeScore				SMALLINT = -1 -- all scoreHDP;
	,	@LiveAwayScore				SMALLINT = -1 -- all scoreHDP;
AS
/*
	Created: 20190419@Long.Luu
	Task : Get Tickets Summary by Match & Fraud Case for Arbitrage
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20190419@Long.Luu: Created [Redmine ID: 111069]

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
			GroupId		INT
		,	TransId		BIGINT
		,	IsIPFraud	BIT
	 );

	CREATE CLUSTERED INDEX #CIX_tmpFraudTickets_TransID ON #tmpFraudTickets (
			TransID			ASC
	);

	IF OBJECT_ID('tempdb..#tmpTicketResults') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpTicketResults;
	END;
	
	CREATE TABLE #tmpTicketResults (
			CustId			INT
		,	BettypeId		SMALLINT
		,	TransId			BIGINT
		,	GroupId			INT
		,	TransDate		DATETIME
		,	BetTeam			NVARCHAR(10)
		,	Handicap1		SMALLMONEY
		,	Handicap2		SMALLMONEY
		,	LiveHomeScore	SMALLINT
		,	LiveAwayScore	SMALLINT
		,	IsLive			BIT
	 );

	CREATE CLUSTERED INDEX #CIX_tmpTicketResults_TransDate ON #tmpTicketResults (
			TransDate		ASC
	);

	IF OBJECT_ID('tempdb..#tmpCustomerList') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomerList;
	END;
	
	CREATE TABLE #tmpCustomerList (
			CustId			INT PRIMARY KEY
	 );

	DECLARE @idocCustomerList INT;
	EXEC sp_xml_preparedocument @idocCustomerList OUTPUT, @CustomerList;
	
	INSERT INTO #tmpCustomerList (CustId)
	SELECT	DISTINCT Data.CustId
	FROM OPENXML(@idocCustomerList, '/Root/ArbitrageCustomer', 2) WITH (
			CustId INT '@CustId'	
	) AS Data;

	--===	2 GET: Balance Up Day and Move Bet Day
	INSERT INTO #tmpBUMB(BUDay,MBDay)
	EXECUTE bodb02.dbo.Age_SelBalanceUpDay;

	DECLARE @IsAfterMoveBetDay BIT = 1;

	SELECT TOP(1) @IsAfterMoveBetDay = 0
	FROM #tmpBUMB WITH(NOLOCK)
	WHERE @EventDate BETWEEN BUDay AND MBDay;
	
	--===	3 GET: Fraud Tickets Insert to #tmpFraudTickets	
	INSERT INTO #tmpFraudTickets(GroupId, TransId, IsIPFraud)
	SELECT si.GroupId, VAL, si.IsIPFraud
	FROM dbo.ArbitrageTicketDetails si WITH(NOLOCK)
		INNER JOIN dbo.SuspiciousCustomer c WITH(NOLOCK) ON si.CustId = c.custid
		INNER JOIN #tmpCustomerList cl WITH(NOLOCK) ON si.CustId = cl.CustId
		CROSS APPLY dbo.SPU_StrSplit(si.transids, ',')
	WHERE	si.MatchId = @MatchId
		AND (@Bettype = -1 OR @Handicap = -1 OR @LiveHomeScore = -1 OR @LiveAwayScore = -1 
			OR (si.BetType = @Bettype AND si.Handicap = @Handicap AND si.LiveHomeScore = @LiveHomeScore AND si.LiveAwayScore = @LiveAwayScore)) -- ScoreHDP
		AND (@CurrencyId = -1 OR c.CurrencyId = @CurrencyId)
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
			
			INSERT INTO #tmpTicketResults(CustId, BettypeId, TransId, GroupId, TransDate, BetTeam, Handicap1
				,	Handicap2, LiveHomeScore, LiveAwayScore, IsLive)
			SELECT	[CustId]		= b.custid
				,	[BettypeId]		= b.bettype 
				,	[TransId]		= b.Transid
				,	[GroupId]		= f.GroupId
				,	[TransDate]		= b.transdate
				,	[BetTeam]		= b.betteam
				,	[Handicap1]		= b.hdp1	
				,	[Handicap2]		= b.hdp2	
				,	[LiveHomeScore] = ISNULL(b.livehomescore,0) 
				,	[LiveAwayScore] = ISNULL(b.liveawayscore,0) 
				,	[IsLive]		= b.liveindicator 
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
			
			INSERT INTO #tmpTicketResults(CustId, BettypeId, TransId, GroupId, TransDate, BetTeam, Handicap1
				, Handicap2, LiveHomeScore, LiveAwayScore, IsLive)
			SELECT	[custid]		= b.custid
				,	[BettypeId]		= b.bettype 
				,	[TransId]		= b.Transid
				,	[GroupId]		= f.GroupId
				,	[TransDate]		= b.transdate
				,	[BetTeam]		= b.betteam
				,	[Handicap1]		= b.hdp1	
				,	[Handicap2]		= b.hdp2	
				,	[LiveHomeScore] = ISNULL(b.livehomescore,0) 
				,	[LiveAwayScore] = ISNULL(b.liveawayscore,0) 
				,	[IsLive]		= b.liveindicator 
			FROM bodb02.dbo.bettrans14 b WITH(NOLOCK)
				INNER JOIN #tmpFraudTickets f WITH(NOLOCK) ON b.transid = f.TransID
				INNER JOIN bodb02.dbo.custInfo c WITH(NOLOCK) ON b.custid = c.custid
			WHERE b.winlostdate = @EventDate
				AND (@LiveStatus = -1 OR b.liveindicator = @LiveStatus);
		END;

	--===	6 RETURN: Fraud Tickets Summarized Info				
	SELECT	t.BettypeId, (t.Handicap1 - t.Handicap2) AS Handicap, t.LiveHomeScore, t.LiveAwayScore, t.GroupId, COUNT(t.TransId) AS TicketCount
	FROM #tmpTicketResults t WITH(NOLOCK)
	WHERE (@TransDateFrom IS NULL OR @TransDateTo IS NULL
			OR (t.TransDate BETWEEN @TransDateFrom AND @TransDateTo))
	GROUP BY t.BettypeId, t.Handicap1, t.Handicap2, t.LiveHomeScore, t.LiveAwayScore, t.GroupId;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/