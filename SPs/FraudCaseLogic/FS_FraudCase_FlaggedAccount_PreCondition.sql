
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
		,	EventDate		DATETIME
		,	KickOffTime		DATETIME
		,	EventStatus		NVARCHAR(20)
	);
	
	--==REMOVE MATCHES: PREVIOUS 14 DAYS
	DELETE	d
	FROM	dbo.FlagAccountMatchScanning d WITH(ROWLOCK)
	WHERE	d.IsScanCompleted = 1
			AND DATEDIFF(DAY, d.EventDate, GETDATE()) > 14;

	----GET MATCHES FROM MAIN DB
	;WITH NewMatch AS
	(
	SELECT		MatchId			= m.matchid
				, EventStatus	= m.EventStatus
				, KickOffTime	= m.kickofftime
				, EventDate		= m.eventdate
	FROM		bodb02.dbo.match AS m WITH (NOLOCK)
	INNER JOIN	bodb02.dbo.League AS l WITH(NOLOCK)
				ON m.leagueid = l.leagueid
	WHERE		(m.EventStatus = 'Running' OR m.EventStatus = 'Completed')
				AND m.sporttype = 1
				AND m.kickofftime <= GETDATE()
				AND l.isTest = 0
	)
	INSERT INTO #tmpMatches(MatchId, EventDate, KickOffTime, EventStatus)
	SELECT		MatchId
				, EventDate
				, KickOffTime
				, EventStatus
	FROM		NewMatch nm WITH(NOLOCK)
	WHERE		EXISTS (SELECT TOP(1) b.matchid
						FROM	bodb02.dbo.bettrans b WITH(NOLOCK)
						WHERE	b.matchid = nm.matchid);

		
	---Insert New Match to FlagAccountMatchScanning
	INSERT INTO dbo.FlagAccountMatchScanning (MatchId, EventDate, KickOffTime, EventStatus, IsScanCompleted)	
	SELECT		m.MatchId
				, m.EventDate
				, m.KickOffTime
				, m.EventStatus
				, 0 AS IsScanCompleted
	FROM		#tmpMatches AS m WITH(NOLOCK)
	LEFT JOIN	dbo.FlagAccountMatchScanning ms WITH(NOLOCK)
				ON m.matchid = ms.matchid
	WHERE		ms.matchid IS NULL;
	
	---Update EventStatus of FlagAccountMatchScanning
	UPDATE		ms
	SET			ms.EventStatus = m.EventStatus
	FROM		dbo.FlagAccountMatchScanning ms WITH(ROWLOCK)
	INNER JOIN	#tmpMatches AS m WITH(NOLOCK)
				ON m.matchid = ms.matchid;

	SELECT		DISTINCT MatchId
	FROM		dbo.FlagAccountMatchScanning ms WITH(NOLOCK)
	WHERE		ms.IsScanCompleted=0;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
