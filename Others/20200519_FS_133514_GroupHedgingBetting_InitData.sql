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
INSERT INTO dbo.FraudCase(FraudCaseName, FraudCaseDesc, FraudCaseInterval, IsActive, IsTest, IsInternal)
VALUES('Group Betting', 'Group Betting', 60, 1, 1, 0);

INSERT INTO dbo.FraudCase(FraudCaseName, FraudCaseDesc, FraudCaseInterval, IsActive, IsTest, IsInternal)
VALUES('Hedging', 'Hedging', 60, 1, 1, 1);