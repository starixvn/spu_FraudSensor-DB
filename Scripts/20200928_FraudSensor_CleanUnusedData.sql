/*
Creator: 20200928@Long
Task: Clean data for Fraud Sensor
Server:  bodb_FraudSensor
Revision:
		- 20200928@Long: Clean data [Redmine ID: 142465]
Reviewer: Patrick
*/ 

USE bodb_FraudSensor;

-- Customer Daily
-- First step: stop the job FS-CustomerTicketCountDaily
-- and then
TRUNCATE TABLE dbo.SummaryByCustomer_Daily;

-- Scanned Matches
WHILE(1 = 1)
	BEGIN
		DELETE TOP (50000)
		FROM dbo.ScannedMatch WITH(ROWLOCK)
		WHERE ScannedDate < '20200101';
		
		IF (@@ROWCOUNT < 50000) 
			BREAK;
	END;

-- OfficeIP Login
WHILE(1 = 1)
	BEGIN
		DELETE TOP (50000)
		FROM dbo.OfficeIPLogIn WITH(ROWLOCK)
		WHERE TransDate < '20200101';
		
		IF (@@ROWCOUNT < 50000) 
			BREAK;
	END;

-- OddsLog
WHILE(1 = 1)
	BEGIN
		DELETE TOP (50000)
		FROM dbo.OddsLog WITH(ROWLOCK)
		WHERE OddsId > 0 AND LogDate < '20200101';
		
		IF (@@ROWCOUNT < 50000) 
			BREAK;
	END;

-- Footprint
TRUNCATE TABLE dbo.FootprintHistory;

-- Captured Data
WHILE(1 = 1)
	BEGIN
		DELETE TOP (50000)
		FROM dbo.CapturedData WITH(ROWLOCK)
		WHERE CapturedDate < '20200101';
		
		IF (@@ROWCOUNT < 50000) 
			BREAK;
	END;

-- Arbitrage
TRUNCATE TABLE dbo.Arbitrage_Rule_Trace;
TRUNCATE TABLE dbo.ArbitrageMatchScanning;
TRUNCATE TABLE dbo.ArbitrageMatchScoreHDP;
TRUNCATE TABLE dbo.ArbitrageSuspiciousInfo;
TRUNCATE TABLE dbo.ArbitrageSuspiciousInfo_bk;
TRUNCATE TABLE dbo.ArbitrageTicketDetails;
TRUNCATE TABLE dbo.ArbitrageTicketDetails_bk;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor"></info>*/
