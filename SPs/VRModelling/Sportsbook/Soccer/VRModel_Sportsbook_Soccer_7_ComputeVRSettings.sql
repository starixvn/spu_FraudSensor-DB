ALTER PROCEDURE [dbo].[VRModel_Sportsbook_Soccer_7_ComputeVRSettings]
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

	DECLARE @BettypeId		INT
		,	@LeagueId		INT;

	-- INITIALIZE
	IF	OBJECT_ID('tempdb..#tmpBettypes') IS NOT NULL
		DROP TABLE	#tmpBettypes;

	CREATE TABLE	#tmpBettypes (
			Bettype			SMALLINT PRIMARY KEY
	);

	INSERT INTO #tmpBettypes(BetType)
	SELECT val FROM dbo.SPU_StrSplit(@Bettypes,',');

	IF	OBJECT_ID('tempdb..#tmpLeagues') IS NOT NULL
		DROP TABLE	#tmpLeagues;

	CREATE TABLE	#tmpLeagues (
			LeagueId		SMALLINT PRIMARY KEY
	);

	INSERT INTO #tmpLeagues(LeagueId)
	SELECT val FROM dbo.SPU_StrSplit(@Leagues,',');

	-- START
	IF ((SELECT COUNT(1) FROM #tmpLeagues WITH(NOLOCK)) > 1)
		BEGIN
			SELECT @LeagueId = NULL, @BettypeId = NULL;
		END
	ELSE
		BEGIN
			SELECT TOP (1) @LeagueId = LeagueId
			FROM #tmpLeagues WITH(NOLOCK);
		END;

	IF ((SELECT COUNT(1) FROM #tmpBettypes WITH(NOLOCK)) > 1)
		BEGIN
			SELECT @BettypeId = NULL;
		END
	ELSE
		BEGIN
			SELECT TOP (1) @BettypeId = Bettype
			FROM #tmpBettypes WITH(NOLOCK);
		END;
	
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