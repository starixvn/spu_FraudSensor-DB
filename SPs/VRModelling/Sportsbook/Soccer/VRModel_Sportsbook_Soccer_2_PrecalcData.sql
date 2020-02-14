CREATE PROCEDURE [dbo].[VRModel_Sportsbook_Soccer_2_PrecalcData]
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

	-- Winner/Loser counter
	TRUNCATE TABLE dbo.[VR2Model_WinnerByWeekCounter];
	TRUNCATE TABLE dbo.[VR2Model_LoserByWeekCounter];

	INSERT INTO dbo.[VR2Model_WinnerByWeekCounter](MarginRange, WeekOrder, NumOfWinner)
	SELECT	w.Margin
		,	w.WeekOrder
		,	COUNT(DISTINCT w.CustId)
	FROM dbo.[VR2Model_CumulativeMarginByWeek] AS w WITH(NOLOCK)
		INNER JOIN dbo.[VR2Model_WinLoseByWeek] AS c WITH(NOLOCK) ON w.CustId = c.CustId
	WHERE c.Winner = 1 
	GROUP BY w.Margin, w.WeekOrder;

	INSERT INTO dbo.[VR2Model_LoserByWeekCounter](MarginRange, WeekOrder, NumOfLoser)
	SELECT	w.Margin
		,	w.WeekOrder
		,	COUNT(DISTINCT w.CustId)
	FROM dbo.[VR2Model_CumulativeMarginByWeek] AS w WITH(NOLOCK)
		INNER JOIN dbo.[VR2Model_WinLoseByWeek] AS c WITH(NOLOCK) ON w.CustId = c.CustId
	WHERE c.Winner = 0 
	GROUP BY w.Margin, w.WeekOrder;

END;

/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/