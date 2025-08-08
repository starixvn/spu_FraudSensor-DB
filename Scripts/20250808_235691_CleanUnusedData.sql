/*
Creator: 20250808@John.Ngo
Task: Clean data for Fraud Sensor [RedmineID: #235691]
Server:  DB053

Reviewer: Sol
*/ 
USE bodb_FraudSensor;

-------- OddsLog
TRUNCATE TABLE dbo.OddsLog;
	
-------- Delete Old Data 'CapturedData' --------
DECLARE @StopDate		   DATE = DATEADD(DAY,-7, GETDATE());

WHILE(1 = 1)
BEGIN
	DELETE TOP(5000) gbc WITH(ROWLOCK)
	FROM dbo.CapturedData AS gbc
	WHERE gbc.CapturedDate < @StopDate;
			
	WAITFOR DELAY '00:00:0.100';
IF (@@ROWCOUNT = 0)
	BREAK;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor"></info>*/
