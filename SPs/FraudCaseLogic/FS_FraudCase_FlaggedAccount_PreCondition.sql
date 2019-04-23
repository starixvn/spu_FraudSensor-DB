
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
		- 20190404@Casey.Huynh: Implement, not scan Match if it has no ticket in bettran tables [111454]
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

	
	;WITH newMatch AS
	(
	SELECT		MatchId = m.matchid
				,EventStatus = m.eventstatus
	FROM		bodb02.dbo.match AS m WITH (NOLOCK)
	INNER JOIN	bodb02.dbo.League AS l WITH(NOLOCK)
				ON m.leagueid = l.leagueid
	WHERE		(m.eventstatus = 'running' OR m.eventstatus = 'completed')
				AND m.sporttype = 1
				AND m.kickofftime <= GETDATE()
				AND l.isTest = 0
	)
	INSERT INTO #tmpMatches(MatchId, EventStatus)
	SELECT		MatchId
				, EventStatus
	FROM		newMatch nm WITH(NOLOCK)
	WHERE		EXISTS (SELECT TOP(1) Matchid
						FROM	bodb02.dbo.bettrans b WITH(NOLOCK)
						WHERE	b.matchid = nm.Matchid);

		
	---Insert New Match to DelayGoalMatchScanning: LastScannedTransId default = 0 
	INSERT INTO dbo.FlagAccountMatchScanning (Matchid, EventDate, KickOffTime, fromTransId, IsScanCompleted)	
	SELECT		[MatchId]		= m.matchid
			,	[EventDate]		= m.eventdate
			,	[KickOffTime]	= m.kickofftime
			,	[fromTransid]	= 0
			,	[IsScanCompleted] = 0
	FROM		#tmpMatches AS m WITH(NOLOCK)
	LEFT JOIN	dbo.FlagAccountMatchScanning ms WITH(NOLOCK)
				ON m.matchid = ms.matchid
	WHERE		ms.Matchid IS NULL;
	
	---Update EventStatus of DelayGoalMatchScanning
	UPDATE		ms
	SET			ms.EventStatus = m.EventStatus
	FROM		dbo.FlagAccountMatchScanning ms WITH(ROWLOCK)
	INNER JOIN	#tmpMatches AS mr WITH(NOLOCK)
				ON m.matchid = ms.matchid;

	SELECT		DISTINCT MatchId
	FROM		dbo.FlagAccountMatchScanning ms WITH(NOLOCK)
	WHERE		ms.IsScanCompleted=0;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
