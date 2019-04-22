GO
SET QUOTED_IDENTIFIER ON ;
GO
SET ANSI_NULLS ON ;
GO

ALTER PROCEDURE [dbo].[FS_FraudCase_BetsNearGoal_PreCondition] 
AS
/*
	Created: 20180306@LONG
	Task : PreCondition for Bets Near The Goal fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20181207@Long: Created [Redmine ID: 106079]

	Param's Explanation (filtered by):  
*/
BEGIN
	SET NOCOUNT ON;	
	
	DECLARE @CurrentFraudCaseId TINYINT;
	SET @CurrentFraudCaseId = 11; -- Bets Near Goal
	
	SELECT DISTINCT m.matchid AS MatchId
	FROM bodb02.dbo.match m WITH(NOLOCK) 
		INNER JOIN bodb02.dbo.league AS l WITH (NOLOCK) ON m.leagueid = l.leagueid
		LEFT JOIN dbo.ScannedMatch sm WITH(NOLOCK) ON m.matchid = sm.matchid AND sm.FraudCaseId = @CurrentFraudCaseId
	WHERE sm.MatchId IS NULL
		AND m.eventstatus = 'Completed'
		AND m.sporttype = 1
		AND l.isTest = 0;		
END;

GO 
 GRANT EXECUTE ON [dbo].[FS_FraudCase_BetsNearGoal_PreCondition] TO [bodbSPUNet];
GO 
/*<info serverAlias="DBSPU-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
