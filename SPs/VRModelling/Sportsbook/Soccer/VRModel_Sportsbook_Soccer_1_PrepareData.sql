CREATE PROCEDURE [dbo].[VRModel_Sportsbook_Soccer_1_PrepareData]
		@FromDate			DATE
	,	@ToDate				DATE
	,	@IsDeposit			BIT
	,	@IsLive				BIT
	,	@LeagueGroupId		SMALLINT
	,	@LeagueId			INT
	,	@BettypeId			INT
AS
/*
	Created: 20200122@Long.Luu
	Task : 
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20200122@Long.Luu: Created [Redmine ID: #]

	Param's Explanation:
*/
BEGIN

	SET NOCOUNT ON;
	-- Sum over the date range
	DECLARE @Settings_MinBetCount	INT	= 1
		,	@Settings_MinBet		MONEY = 499;


	-- START
	TRUNCATE TABLE dbo.[VR2Model_CumulativeMarginByWeek];
	TRUNCATE TABLE dbo.[VR2Model_TotalCumuMarginByWeek];

	INSERT INTO dbo.[VR2Model_CumulativeMarginByWeek](CustId, SuperId, Margin, WeekOrder)
	SELECT	w.CustId, w.SuperId, SUM(w.RealWinloss) / SUM(w.RealTurnover), DATEPART( wk,w.FromDate) AS 'WeekOrder'
	FROM dbo.[VR2Model_SoccerWeeklyData] AS w WITH(NOLOCK)
	WHERE w.LeagueId = @LeagueId
		AND w.BettypeId = @BettypeId
		AND w.IsLive = @IsLive
		AND w.BetCount > @Settings_MinBetCount
		AND w.RealTurnover > @Settings_MinBet
	GROUP BY w.CustId, w.SuperId, w.FromDate;

	INSERT INTO dbo.[VR2Model_TotalCumuMarginByWeek](CustId, SuperId, Margin, NumOfWeeksBet)
	SELECT tmp1.CustId, tmp1.SuperId, tmp1.Margin,tmp2.NumOfWeeksBet FROM
	(
		Select top 1 w.CustId, w.SuperID, w.Margin FROM dbo.[VR2Model_CumulativeMarginByWeek] AS w WITH(NOLOCK) ORDER BY w.WeekOrder DESC
	) AS tmp1
	INNER JOIN  
	(
		SELECT w.CustId,COUNT(w.WeekOrder) AS 'NumOfWeeksBet'
		FROM dbo.[VR2Model_CumulativeMarginByWeek] AS w WITH(NOLOCK)
		GROUP BY w.CustId
	) AS tmp2 
	ON tmp1.CustId = tmp2.CustId;

	INSERT INTO dbo.[VR2Model_WinLoseByWeek](CustId, Winner, NumOfWeeksBet)
	SELECT tmp1.CustId, tmp1.Winner,tmp2.NumOfWeeksBet FROM
	(
		Select top 1 w.CustId, CASE WHEN w.Margin < 0 THEN 1 ELSE 0 END AS 'Winner' FROM dbo.[VR2Model_CumulativeMarginByWeek] AS w WITH(NOLOCK) ORDER BY w.WeekOrder DESC
	) AS tmp1
	INNER JOIN  
	(
		SELECT w.CustId,COUNT(w.WeekOrder) AS 'NumOfWeeksBet'
		FROM dbo.[VR2Model_CumulativeMarginByWeek] AS w WITH(NOLOCK)
		GROUP BY w.CustId
	) AS tmp2 
	ON tmp1.CustId = tmp2.CustId;

		
	UPDATE dbo.[VR2Model_CumulativeMarginByWeek] WITH(ROWLOCK, UPDLOCK)
	SET Margin = 0.1
	WHERE Margin > 0.1;

	UPDATE dbo.[VR2Model_CumulativeMarginByWeek] WITH(ROWLOCK, UPDLOCK)
	SET Margin = -0.1
	WHERE Margin < -0.1;

END;

/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/