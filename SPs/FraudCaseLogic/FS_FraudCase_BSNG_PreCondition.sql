ALTER PROCEDURE [dbo].[FS_FraudCase_BSNG_PreCondition] 
AS
/*
	Created: 20180306@LONG
	Task : PreCondition for Big Stake Near The Goal fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20180312@CaseyHuynh: Correct Code Syntax
		- 20180525@Casey.Huynh: Exclude League Test
		- 20180525@Casey.Huynh: Update set LiveScore = 0 for New Match when insert to MatchLiveScore
		- 20180605@Casey.Huynh: Enhance SP
		- 20180726@Casey.Huynh: Enhance SP: GET NEW MATCH for both Completed Match and Running Match if MatchID is not existing in MatchScore table 
								(remove condition m.EventStatus='Running')
		- 20180727@John.Ngo:	Get new match for both Completed Match and Running Match if MatchId is not existing in MatchScore table
		- 20190225@Long.Luu:	Scanning for completed matches during UM time [Redmine ID: #106820]
		- 20190320@Casey.Huynh: Enhance Performance, Remove #tmpChangedMatch redundant table [110060]
		- 20190329@Casey.Huynh: Implement Completed Match when the score is rejected: move code update table MatchScore completed Status to sp rule [111079]
		- 20190404@Casey.Huynh: Implement, not scan Match if it has no ticket in bettran tables [111454]
	Param's Explanation (filtered by):  
*/
BEGIN
	SET NOCOUNT ON;	
	
	DECLARE @CurrentTime DATETIME;
	
	SET @CurrentTime = GETDATE();
	
	--- ============1. INSERT NEW MATCH=============================
	;WITH newMatch AS
	(
	SELECT		m.matchid
				, m.eventdate
				, m.eventstatus
				, m.livehomescore + m.liveawayscore AS TotalScores
				, 0	AS HasScanned
				, @CurrentTime AS UpdatedDate
	FROM		bodb02.dbo.Match AS m WITH(NOLOCK)
	INNER JOIN	bodb02.dbo.league AS l WITH (NOLOCK) 
				ON m.leagueid = l.leagueid
	LEFT JOIN	dbo.MatchScore AS ms WITH(NOLOCK) 
				ON m.matchid = ms.MatchId
	WHERE		ms.MatchId IS NULL
				AND (m.eventstatus = 'Running' OR m.eventstatus = 'Completed')			
				AND m.sporttype = 1
				AND l.isTest = 0
				AND m.kickofftime <= @CurrentTime	
				AND	m.livehomescore + m.liveawayscore > 0
	)

	INSERT INTO dbo.MatchScore(MatchId, EventDate, EventStatus, TotalScores, HasScanned, UpdatedDate)
	SELECT		m.matchid
				, m.eventdate
				, m.eventstatus
				, m.TotalScores
				, m.HasScanned
				, m.UpdatedDate
	FROM		newMatch AS m WITH(NOLOCK)
	WHERE		EXISTS (SELECT TOP(1) Matchid
						FROM	bodb02.dbo.bettrans b WITH(NOLOCK)
						WHERE	b.matchid = m.Matchid);

	--- RETURN MATCH HAS NEW SCORE
	SELECT		ms.MatchId
	FROM		dbo.MatchScore AS ms WITH (NOLOCK)
	WHERE		ms.HasScanned = 0;

END;

