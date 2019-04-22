
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER PROCEDURE [dbo].[FS_FraudCase_FlaggedAccount_PreCondition] 
AS
/*
	Created: 20180308@LONG
	Task : PreCondition for Flagged Account fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20180312@CaseyHuynh:	Correct Code Syntax
		- 20180525@Casey.Huynh: Exclude League Test
		- 20190225@Long.Luu:	Scanning for completed matches during UM time [Redmine ID: #106820]
		- 20190320@Casey.Huynh: Enhance Performance, define PRIMARY KEY in table [110060]
	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	
	
	DECLARE @fraudCaseID INT = 6;

	IF OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatches;
	END;

	CREATE TABLE #tmpMatches(
			MatchId			INT	NOT	NULL PRIMARY KEY CLUSTERED		
		,	EventStatus		NVARCHAR(20)
	);

	INSERT INTO #tmpMatches(MatchId, EventStatus)
	SELECT  [MatchId] = m.matchid
		,	[EventStatus] = m.eventstatus
	FROM bodb02.dbo.match AS m WITH (NOLOCK)
		INNER JOIN bodb02.dbo.League AS l WITH(NOLOCK) ON m.leagueid = l.leagueid
	WHERE (m.eventstatus = 'running' OR m.eventstatus = 'completed')
		AND m.sporttype = 1
		AND m.kickofftime <= GETDATE()
		AND l.isTest = 0;		

	DELETE m
	FROM #tmpMatches AS m
		LEFT JOIN dbo.ScannedMatch AS ms WITH(NOLOCK)ON ms.matchid = m.matchid AND ms.FraudCaseId = @fraudCaseID
	WHERE ms.MatchId IS NOT NULL AND m.EventStatus = 'completed';

	SELECT DISTINCT MatchId
	FROM #tmpMatches WITH(NOLOCK);
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
