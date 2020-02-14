ALTER PROCEDURE [dbo].[VRModel_Sportsbook_Soccer_5_BuildChanceOfDanger]
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

	-- Smoothing the ChangeOfDanger table
	TRUNCATE TABLE dbo.[VR2Model_ChanceOfDanger];

	INSERT INTO dbo.[VR2Model_ChanceOfDanger](MarginRange, WeekOrder, PercentageOfWin)
	SELECT	h.MarginRange
		,	h.WeekOrder
		,	(h.PercentageOfWin + v.PercentageOfWin) / 2
	FROM dbo.[VR2Model_ChanceOfDangerSmoothHorizontal] AS h WITH(NOLOCK)
		INNER JOIN dbo.[VR2Model_ChanceOfDangerSmoothVertical] AS v WITH(NOLOCK) ON h.MarginRange = v.MarginRange AND h.WeekOrder = v.WeekOrder;
END;

/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/