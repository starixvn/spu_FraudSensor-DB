/*
Creator: 20190409@Long.Luu
Task:    Do not use TotalScore for calculating Arbitrage anymore [Redmine ID: 111069]
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

--- Clear Tables Data
TRUNCATE TABLE [dbo].[ArbitrageTicketDetails];
GO

TRUNCATE TABLE [dbo].[ArbitrageMatchScanning];
GO

TRUNCATE TABLE [dbo].[ArbitrageSuspiciousInfo];
GO

DELETE FROM [dbo].[ScannedMatch] WITH(ROWLOCK)
WHERE FraudCaseId = 10;