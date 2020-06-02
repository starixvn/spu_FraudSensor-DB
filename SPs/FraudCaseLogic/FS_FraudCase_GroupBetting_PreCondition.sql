
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER PROCEDURE [dbo].[FS_FraudCase_GroupBetting_PreCondition] 
AS
/*
	Created: 20200519@Long.Luu
	Task : PreCondition for Group Betting fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20200519@Long.Luu: Created [Redmine ID: #133798]

	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	
	
	DECLARE @fraudCaseID INT = 13;

	IF OBJECT_ID('tempdb..#tmpBettypes') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpBettypes;
	END;

	CREATE TABLE #tmpBettypes(
			BettypeId		INT	NOT	NULL PRIMARY KEY CLUSTERED
	);

	IF OBJECT_ID('tempdb..#tmpSports') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSports;
	END;

	CREATE TABLE #tmpSports(
			SportId			SMALLINT	NOT	NULL PRIMARY KEY CLUSTERED
	);

	IF OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatches;
	END;

	CREATE TABLE #tmpMatches(
			MatchId			INT	NOT	NULL PRIMARY KEY CLUSTERED
		,	EventDate		DATETIME
		,	KickOffTime		DATETIME
		,	EventStatus		NVARCHAR(20)
	);

	-- START
	-- Init sports and bettypes
	INSERT INTO #tmpBettypes(BettypeId)
	SELECT val FROM SPU_StrSplit('1,3,7,8,20,21,153,154,155,156,609,610,612,701,704,705,9001,9003,9004', ',');

	INSERT INTO #tmpSports(SportId)
	SELECT DISTINCT m.SportType
	FROM bodb02.dbo.SportBettypeMatrix AS m WITH(NOLOCK)
		INNER JOIN #tmpBettypes AS b WITH(NOLOCK) ON m.BetType = b.BettypeId;
	
	-- Remove scanned matches, just keep the latest 7 days
	DELETE	d
	FROM	dbo.ScanningMatch d WITH(ROWLOCK)
	WHERE	d.FraudCaseId = @fraudCaseID
			AND d.IsScanCompleted = 1
			AND DATEDIFF(DAY, d.EventDate, GETDATE()) > 7;

	-- Get matches for scanning
	;WITH NewMatch AS
	(
		SELECT	MatchId			= m.matchid
			,	EventStatus		= m.EventStatus
			,	KickOffTime		= m.kickofftime
			,	EventDate		= m.eventdate
		FROM bodb02.dbo.match AS m WITH (NOLOCK)
			INNER JOIN bodb02.dbo.League AS l WITH(NOLOCK) ON m.leagueid = l.leagueid
			INNER JOIN #tmpSports AS s WITH(NOLOCK) ON m.sporttype = s.SportId
		WHERE	(m.EventStatus = 'Running' OR m.EventStatus = 'Completed')
			AND m.kickofftime <= GETDATE()
			AND l.isTest = 0
	)
	INSERT INTO #tmpMatches(MatchId, EventDate, KickOffTime, EventStatus)
	SELECT	MatchId
		,	EventDate
		,	KickOffTime
		,	EventStatus
	FROM NewMatch AS nm WITH(NOLOCK)
	WHERE EXISTS (	SELECT TOP(1) b.matchid
					FROM	bodb02.dbo.bettrans AS b WITH(NOLOCK)
					WHERE	b.matchid = nm.matchid);

		
	-- Insert New Matches to ScanningMatch
	INSERT INTO dbo.ScanningMatch (MatchId, FraudCaseId, EventDate, KickOffTime, EventStatus, IsScanCompleted)	
	SELECT	m.MatchId
		,	@fraudCaseID
		,	CAST(m.EventDate AS DATE)
		,	m.KickOffTime
		,	m.EventStatus
		,	0 AS IsScanCompleted
	FROM #tmpMatches AS m WITH(NOLOCK)
		LEFT JOIN dbo.ScanningMatch AS ms WITH(NOLOCK) ON m.matchid = ms.matchid AND ms.FraudCaseId = @fraudCaseID
	WHERE ms.matchid IS NULL;
	
	-- Update EventStatus of ScanningMatch
	UPDATE ms WITH(ROWLOCK)
	SET	ms.EventStatus = m.EventStatus
	FROM dbo.ScanningMatch ms
		INNER JOIN	#tmpMatches AS m WITH(NOLOCK) ON m.matchid = ms.matchid AND ms.FraudCaseId = @fraudCaseID;

	SELECT DISTINCT MatchId
	FROM dbo.ScanningMatch AS ms WITH(NOLOCK)
	WHERE ms.FraudCaseId = @fraudCaseID
		AND ms.IsScanCompleted = 0;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
