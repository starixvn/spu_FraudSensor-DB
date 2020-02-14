CREATE PROCEDURE [dbo].[VRModel_Sportsbook_Soccer_3_CreateRawChanceOfDanger]
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

	TRUNCATE TABLE dbo.[VR2Model_RawChanceOfDanger];
		
	INSERT INTO dbo.[VR2Model_RawChanceOfDanger](MarginRange, WeekOrder, PercentageOfWin)
	SELECT	w.MarginRange
		,	w.WeekOrder
		,	w.NumOfWinner / (w.NumOfWinner + l.NumOfLoser)
	FROM dbo.[VR2Model_WinnerByWeekCounter] AS w WITH(NOLOCK)
		INNER JOIN dbo.[VR2Model_LoserByWeekCounter] AS l WITH(NOLOCK) ON w.MarginRange = l.MarginRange AND w.WeekOrder = l.WeekOrder
	UNION
	SELECT w.MarginRange, w.WeekOrder, 0.1
	FROM dbo.[VR2Model_WinnerByWeekCounter] AS w WITH(NOLOCK)
		LEFT JOIN dbo.[VR2Model_LoserByWeekCounter] AS l WITH(NOLOCK) ON w.MarginRange = l.MarginRange AND w.WeekOrder = l.WeekOrder
	WHERE l.NumOfLoser IS NULL
	UNION
	SELECT l.MarginRange, l.WeekOrder, 0
	FROM dbo.[VR2Model_WinnerByWeekCounter] AS w WITH(NOLOCK)
		RIGHT JOIN dbo.[VR2Model_LoserByWeekCounter] AS l WITH(NOLOCK) ON w.MarginRange = l.MarginRange AND w.WeekOrder = l.WeekOrder
	WHERE w.NumOfWinner IS NULL;

END;

/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/