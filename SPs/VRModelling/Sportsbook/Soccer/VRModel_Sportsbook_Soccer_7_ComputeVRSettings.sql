ALTER PROCEDURE [dbo].[VRModel_Sportsbook_Soccer_7_ComputeVRSettings]
		@FromDate			DATE
	,	@ToDate				DATE
	,	@IsDeposit			BIT
	,	@IsLive				BIT
	,	@SportId			INT
	,	@LeagueGroupId		SMALLINT
	,	@LeagueId			INT
	,	@BettypeGroupId		INT
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

	INSERT INTO dbo.VR2Model_VirtualRate(
			CustId
		,	IsDeposit
		,	IsLive
		,	SportId
		,	LeagueGroupId
		,	LeagueId
		,	BettypeGroupId
		,	BettypeId
		,	VirtualMultiplier
		,	CreatedDate)
	SELECT	@IsDeposit
		,	@IsLive
		,	@SportId
		,	@LeagueGroupId
		,	@LeagueId
		,	@BettypeGroupId
		,	@BettypeId
		,	c.CustId
		,	-((1 - d.PercentageOfWin * l.PercentageOfWin) * 100) AS VirtualRateSettings
		,	GETDATE()
	FROM dbo.VR2Model_CustomerCumulativeInfo AS c WITH(NOLOCK)
		INNER JOIN dbo.VR2Model_ChanceOfDanger AS d WITH(NOLOCK) ON c.Margin = d.MarginRange AND c.NumOfWeeksBet = d.WeekOrder
		INNER JOIN dbo.VR2Model_LicenseeModifier AS l WITH(NOLOCK) ON c.SuperId = l.SuperId;
END;

/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/