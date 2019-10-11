/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[FS_Task_ScannedMatch_ArchiveData]
AS
/*
	Created: 20191011@Patrick
	Task : Archive scanned match after move bet day
		- Copying before MB
		- Deleting after MB

	DB: bodb_FraudSensor
	Original:

	Revisions:	

	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	
	DECLARE @__moveBetSchedule TABLE(RowId TINYINT IDENTITY(1,1), ScheduleId TINYINT, MoveBetDay SMALLDATETIME)

	INSERT INTO @__moveBetSchedule(ScheduleId, MoveBetDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel
	
	--copying
	DECLARE @__matchIds TABLE (matchid INT PRIMARY KEY)

	INSERT INTO @__matchIds(matchid)
	SELECT matchid
	FROM bodb02.dbo.match m WITH(NOLOCK)
	WHERE m.eventdate IN (SELECT t.MoveBetDay FROM @__moveBetSchedule t)
		AND m.sporttype = 1

	--incase regen
	DELETE s 
	FROM dbo.ScannedMatch_bk s
	WHERE MatchId IN (SELECT t.matchid FROM @__matchIds t)

	INSERT INTO dbo.ScannedMatch_bk([MatchId], [FraudCaseId], [ScannedDate], [SuspiciousTicketsCount])
	SELECT [MatchId], [FraudCaseId], [ScannedDate], [SuspiciousTicketsCount]
	FROM dbo.ScannedMatch WITH(NOLOCK)
	WHERE MatchId IN (SELECT t.matchid FROM @__matchIds t)

	--deleting
	DELETE s
	FROM dbo.ScannedMatch s
	WHERE MatchId NOT IN (SELECT m.matchid FROM bodb02.dbo.match m WITH(NOLOCK) WHERE sporttype = 1)

END
GO
