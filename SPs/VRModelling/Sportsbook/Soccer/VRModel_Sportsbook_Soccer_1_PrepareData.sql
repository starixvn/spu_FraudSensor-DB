ALTER PROCEDURE [dbo].[VRModel_Sportsbook_Soccer_1_PrepareData]
		@FromDate			DATE
	,	@ToDate				DATE
	,	@IsDeposit			BIT
	,	@IsLive				BIT
	,	@SportId			INT
	,	@LeagueGroupId		SMALLINT
	,	@Leagues			VARCHAR(200)
	,	@BettypeGroupId		INT
	,	@Bettypes			VARCHAR(200)
AS
/*
	Created: 20200212@Long.Luu
	Task : 
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20200212@Long.Luu: Created [Redmine ID: #127584]

	Param's Explanation:
*/
BEGIN

	SET NOCOUNT ON;

	-- Initialize
	DECLARE @Settings_MinBetCount	INT	= 1
		,	@Settings_MinBet		MONEY = 499;

	IF	OBJECT_ID('tempdb..#tmpSoccerWeeklyData') IS NOT NULL
	BEGIN
		DROP TABLE #tmpSoccerWeeklyData;
	END;

	CREATE TABLE #tmpSoccerWeeklyData(
		[FromDate]			DATE NOT NULL,
		[ToDate]			DATE NOT NULL,
		[WeekOrder]			INT NOT NULL,
		[CustId]			INT NOT NULL,
		[SuperId]			INT NOT NULL,
		[RealTurnover]		MONEY NULL,
		[RealWinloss]		MONEY NULL,
		CONSTRAINT PK_#tmpSoccerWeeklyData PRIMARY KEY CLUSTERED (
			[FromDate]		ASC,
			[ToDate]		ASC,
			[CustId]		ASC,
			[SuperId]		ASC,
			[WeekOrder]		ASC
		)
	);

	IF	OBJECT_ID('tempdb..#tmpBettypes') IS NOT NULL
		DROP TABLE	#tmpBettypes;

	CREATE TABLE	#tmpBettypes (
			Bettype			SMALLINT PRIMARY KEY
	);

	INSERT INTO #tmpBettypes(BetType)
	SELECT val FROM dbo.strSplit_Key(@Bettypes,',');

	IF	OBJECT_ID('tempdb..#tmpLeagues') IS NOT NULL
		DROP TABLE	#tmpLeagues;

	CREATE TABLE	#tmpLeagues (
			LeagueId		SMALLINT PRIMARY KEY
	);

	INSERT INTO #tmpLeagues(LeagueId)
	SELECT val FROM dbo.strSplit_Key(@Leagues,',');

	-- START
	TRUNCATE TABLE dbo.[VR2Model_CumulativeMarginByWeek];
	TRUNCATE TABLE dbo.[VR2Model_CustomerCumulativeInfo];

	INSERT INTO #tmpSoccerWeeklyData(FromDate, ToDate, CustId, SuperId, RealTurnover, RealWinloss)
	SELECT	w.FromDate
		,	w.ToDate
		,	w.CustId
		,	w.SuperId
		,	w.RealTurnover
		,	w.RealWinloss
	FROM dbo.[VR2Model_SoccerWeeklyData] AS w WITH(NOLOCK)
		INNER JOIN #tmpBettypes AS b WITH(NOLOCK) ON w.BettypeId = b.Bettype
		INNER JOIN #tmpLeagues AS l WITH(NOLOCK) ON w.LeagueId = l.LeagueId
	WHERE w.FromDate >= @FromDate AND w.ToDate <= @ToDate
		AND w.IsDeposit = @IsDeposit
		AND w.IsLive = @IsLive
		AND w.BetCount > @Settings_MinBetCount
		AND w.RealTurnover > @Settings_MinBet;

	UPDATE t WITH(ROWLOCK, UPDLOCK)
	SET t.WeekOrder = ROW_NUMBER() OVER(PARTITION BY t.CustId ORDER BY t.FromDate ASC)
	FROM #tmpSoccerWeeklyData AS t;

	;WITH rs AS
	(
		SELECT	t.CustId, t.SuperId, t.WeekOrder, t.RealTurnover, t.RealWinloss
		FROM #tmpSoccerWeeklyData AS t WITH(NOLOCK)
		WHERE t.WeekOrder = 1

		UNION ALL

		SELECT	t1.CustId, t1.SuperId, t1.WeekOrder, t1.RealTurnover + rs.RealTurnover,  t1.RealWinloss + rs.RealWinloss
		FROM rs 
			INNER JOIN #tmpSoccerWeeklyData AS t1 WITH(NOLOCK) ON rs.CustId = t1.CustId AND t1.WeekOrder = rs.WeekOrder + 1
	)
	INSERT INTO dbo.[VR2Model_CumulativeMarginByWeek](CustId, SuperId, WeekOrder, Margin)
	SELECT	CustId
		,	SuperId
		,	WeekOrder
		,	CAST(ROUND(RealWinloss / RealTurnover, 2) AS NUMERIC(1,1))
	FROM rs;
		
	UPDATE dbo.[VR2Model_CumulativeMarginByWeek] WITH(ROWLOCK, UPDLOCK)
	SET Margin = 0.1
	WHERE Margin > 0.1;

	UPDATE dbo.[VR2Model_CumulativeMarginByWeek] WITH(ROWLOCK, UPDLOCK)
	SET Margin = -0.1
	WHERE Margin < -0.1;

	;WITH cte AS
	(
	   SELECT CustId, SuperId, WeekOrder, Margin,
			 ROW_NUMBER() OVER (PARTITION BY CustId ORDER BY WeekOrder DESC) AS RowNumber
	   FROM dbo.[VR2Model_CumulativeMarginByWeek] WITH(NOLOCK)
	)
	INSERT INTO dbo.[VR2Model_CustomerCumulativeInfo](CustId, SuperId, Margin, NumOfWeeksBet)
	SELECT CustId, SuperId, Margin, WeekOrder
	FROM cte
	WHERE RowNumber = 1;
END;

/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/