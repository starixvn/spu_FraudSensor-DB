CREATE PROCEDURE [dbo].[FS_Task_ArchiveData_OddsLogAndCapturedData] 
AS
/*
	Created: 20250818@John.Ngo
	Task: Remove all data from OddsLog, CapturedData table, just keep data for the last 7 days
	DB: bodb_FraudSensor

	Revisions:
		- 20250818@John.Ngo: Remove all data from OddsLog, CapturedData table, just keep data for the last 7 days
		
	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	

	DECLARE @RemoveDate DATETIME;
	
	SELECT @RemoveDate = DATEADD(DAY, -7, GETDATE());

	DROP TABLE IF EXISTS #__tmpOddsLog
	CREATE TABLE #__tmpOddsLog(
		OddsId		INT
	);
	INSERT INTO #__tmpOddsLog(OddsId)
	SELECT OddsId
	FROM dbo.OddsLog WITH(NOLOCK)
	WHERE LogDate < @RemoveDate;

	DECLARE @__batch_del TABLE (OddsId INT);

	WHILE(1 = 1)
	BEGIN
		DELETE FROM @__batch_del;

		DELETE TOP(5000) FROM #__tmpOddsLog
		OUTPUT deleted.OddsId INTO @__batch_del(OddsId);
		IF @@ROWCOUNT = 0
			BREAK;

		DELETE dbo.OddsLog WITH(ROWLOCK)
		WHERE LogDate < @RemoveDate
			AND OddsId IN (SELECT t.OddsId FROM @__batch_del t);
		
		WAITFOR DELAY '00:00:0.100';
	END;
	
	WHILE(1 = 1)
	BEGIN
		DELETE TOP(5000) gbc WITH(ROWLOCK)
		FROM dbo.CapturedData AS gbc
		WHERE gbc.CapturedDate < @RemoveDate;
				
		IF (@@ROWCOUNT = 0)
			BREAK;
		
		WAITFOR DELAY '00:00:0.100';
	END;
	
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" isFunction="0" isNested="0"></info>*/
