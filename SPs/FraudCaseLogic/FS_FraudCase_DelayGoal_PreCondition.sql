SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
ALTER PROCEDURE [dbo].[FS_FraudCase_DelayGoal_PreCondition]

AS
/*
	Created: 20180312@CaseyHuynh
	Task : Get Match to scan for Delay Goal Fraud Case (Match Status = Running AND Sport = Soccer AND League Type = Main Markets AND Kick-off Time < Current Time)
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20180312@CaseyHuynh:	Correct Code Syntax
		- 20180525@Casey.Huynh: Exclude League Test		
		- 20190225@Long.Luu:	Scanning for completed matches during UM time [Redmine ID: #106820]
		- 20190320@Casey.Huynh: Enhance Performance, define PRIMARY KEY in table [110060]
		- 20190404@Casey.Huynh: Implement, not scan Match if it has no ticket in bettran tables [111454]
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @fraudCaseID INT = 8;
	
	IF OBJECT_ID('tempdb..#tmpMatchRunning') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatchRunning;
	END;

	CREATE TABLE #tmpMatchRunning(
			MatchId			INT NOT	NULL PRIMARY KEY CLUSTERED
		,	EventDate		DATE
		,	KickOffTime		DATETIME
		,	EventStatus		NVARCHAR(20)
	);
	
	;WITH newMatch AS
	(
	SELECT		[MatchId]		= m.matchid
			,	[EventDate]		= m.eventdate
			,	[KickOffTime]	= m.kickofftime
			,	[eventstatus]	= m.eventstatus
	FROM		bodb02.dbo.match AS m WITH(NOLOCK)
	INNER JOIN	bodb02.dbo.League AS l WITH(NOLOCK) 
				ON	m.leagueid = l.leagueid
	WHERE		m.sporttype = 1
				AND	(m.eventstatus = 'Running' OR m.eventstatus = 'Completed')
				AND	m.kickofftime <= GETDATE()
				AND	l.IsMainMarket = 1
				AND	l.isTest = 0
	)
	INSERT INTO #tmpMatchRunning(MatchId, EventDate, KickOffTime, EventStatus)
	SELECT		MatchId
				, EventDate
				, KickOffTime
				, EventStatus
	FROM		newMatch nm WITH(NOLOCK)
	WHERE		EXISTS (SELECT TOP(1) Matchid
						FROM	bodb02.dbo.bettrans b WITH(NOLOCK)
						WHERE	b.matchid = nm.Matchid);
	
	---Insert New Match to DelayGoalMatchScanning: LastScannedTransId default = 0 
	INSERT INTO dbo.DelayGoalMatchScanning (Matchid, EventDate, KickOffTime, fromTransId, IsScanCompleted)	
	SELECT		[MatchId]		= mr.matchid
			,	[EventDate]		= mr.eventdate
			,	[KickOffTime]	= mr.kickofftime
			,	[fromTransid]	= 0
			,	[IsScanCompleted] = 0
	FROM		#tmpMatchRunning AS mr WITH(NOLOCK)
	LEFT JOIN	dbo.DelayGoalMatchScanning AS ms WITH(NOLOCK)
				ON mr.matchid = ms.matchid
	WHERE		ms.Matchid IS NULL;
	
	---Return Match List Need to Scanning
	SELECT		dms.Matchid
	FROM		dbo.DelayGoalMatchScanning dms WITH(NOLOCK)
	WHERE		dms.IsScanCompleted = 0;
	
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/

