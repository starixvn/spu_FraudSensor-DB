ALTER PROCEDURE [dbo].[VRModel_Sportsbook_Soccer_2_PrecalcData]
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

	-- Winner/Loser counter
	TRUNCATE TABLE dbo.[VR2Model_WinnerByWeekCounter];
	TRUNCATE TABLE dbo.[VR2Model_LoserByWeekCounter];

	INSERT INTO dbo.[VR2Model_WinnerByWeekCounter](MarginRange, WeekOrder, NumOfWinner)
	SELECT	w.Margin
		,	w.WeekOrder
		,	COUNT(DISTINCT w.CustId)
	FROM dbo.[VR2Model_CumulativeMarginByWeek] AS w WITH(NOLOCK)
	WHERE w.Margin > 0
	GROUP BY w.Margin, w.WeekOrder;

	INSERT INTO dbo.[VR2Model_LoserByWeekCounter](MarginRange, WeekOrder, NumOfLoser)
	SELECT	w.Margin
		,	w.WeekOrder
		,	COUNT(DISTINCT w.CustId)
	FROM dbo.[VR2Model_CumulativeMarginByWeek] AS w WITH(NOLOCK)
	WHERE w.Margin <= 0
	GROUP BY w.Margin, w.WeekOrder;

END;

/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/