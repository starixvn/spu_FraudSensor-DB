/*
Creator: 20200519@Long.Luu
Task:  Group/Hedging Betting [Redmine ID: 133514]
Server:  bodb_FraudSensor

Reviewer: Patrick
*/

USE	bodb_FraudSensor;
GO

----===================D. INIT DATA=========================
----==========================================================
SET IDENTITY_INSERT dbo.FraudCase ON;  
INSERT INTO dbo.FraudCase(FraudCaseId, FraudCaseName, FraudCaseDesc, FraudCaseInterval, IsActive, IsTest, IsInternal)
VALUES(13, 'Group Betting', 'Group Betting', 60, 1, 1, 0);

INSERT INTO dbo.FraudCase(FraudCaseId, FraudCaseName, FraudCaseDesc, FraudCaseInterval, IsActive, IsTest, IsInternal)
VALUES(14, 'Hedging', 'Hedging', 60, 1, 1, 1);

SET IDENTITY_INSERT dbo.FraudCase OFF;  