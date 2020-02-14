ALTER PROCEDURE [dbo].[VRModel_Sportsbook_Soccer_6_BuildLicenseeAgentModifier]
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

	-- INITIALIZE
	DECLARE @AVGLicenseePercentageOfDanger MONEY;

	IF	OBJECT_ID('tempdb..#tmpWinnerCounterByLicensee') IS NOT NULL
	BEGIN
		DROP TABLE #tmpWinnerCounterByLicensee;
	END;

	CREATE TABLE #tmpWinnerCounterByLicensee (
			[SuperId]			INT NOT NULL PRIMARY KEY
		,	[NumOfWinner]		INT
	);

	IF	OBJECT_ID('tempdb..#tmpLoserCounterByLicensee') IS NOT NULL
	BEGIN
		DROP TABLE #tmpLoserCounterByLicensee;
	END;

	CREATE TABLE #tmpLoserCounterByLicensee (
			[SuperId]			INT NOT NULL PRIMARY KEY
		,	[NumOfLoser]		INT
	);

	IF	OBJECT_ID('tempdb..#tmpLicenseePercentageOfWin') IS NOT NULL
	BEGIN
		DROP TABLE #tmpLicenseePercentageOfWin;
	END;

	CREATE TABLE #tmpLicenseePercentageOfWin (
			[SuperId]			INT NOT NULL PRIMARY KEY
		,	[PercentageOfWin]	FLOAT
	);
	
	-- START
	INSERT INTO #tmpWinnerCounterByLicensee(SuperId, NumOfWinner)
	SELECT c.SuperId, COUNT(c.CustId)
	FROM dbo.[VR2Model_CustomerCumulativeInfo] AS c WITH(NOLOCK)
	WHERE c.Margin > 0
	GROUP BY c.SuperId;

	INSERT INTO #tmpLoserCounterByLicensee(SuperId, NumOfLoser)
	SELECT c.SuperId, COUNT(c.CustId)
	FROM dbo.[VR2Model_CustomerCumulativeInfo] AS c WITH(NOLOCK)
	WHERE c.Margin <= 0
	GROUP BY c.SuperId;

	INSERT INTO #tmpLicenseePercentageOfWin(SuperId, PercentageOfWin)
	SELECT	w.SuperId
		,	w.NumOfWinner / (w.NumOfWinner + l.NumOfLoser)
	FROM #tmpWinnerCounterByLicensee AS w WITH(NOLOCK)
		INNER JOIN #tmpLoserCounterByLicensee AS l WITH(NOLOCK) ON w.SuperId = l.SuperId;

	SELECT @AVGLicenseePercentageOfDanger = SUM(w.NumOfWinner) / (SUM(w.NumOfWinner) + SUM(l.NumOfLoser))
	FROM #tmpWinnerCounterByLicensee AS w WITH(NOLOCK)
		INNER JOIN #tmpLoserCounterByLicensee AS l WITH(NOLOCK) ON w.SuperId = l.SuperId;

	INSERT INTO dbo.VR2Model_LicenseeModifier(SuperId, PercentageOfWin)
	SELECT	l.SuperId
		,	l.PercentageOfWin * 100 / @AVGLicenseePercentageOfDanger
	FROM #tmpLicenseePercentageOfWin AS l WITH(NOLOCK);
END;

/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
