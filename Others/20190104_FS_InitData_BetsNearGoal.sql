/*
Creator: 20190104@JohnNgo
Task:  Add new fraud case - Bets Near The Goal for Fraud Sensor - Redmine ID: 106079
Server:  bodb_FraudSensor

Reviewer: Billy
*/

USE	bodb_FraudSensor;
GO

----===================D. INIT DATA=========================
----==========================================================
INSERT INTO dbo.FraudCase(FraudCaseName, FraudCaseDesc, FraudCaseInterval, IsActive, IsTest, IsInternal)
VALUES('Bets Near Goal', 'Bets Near Goal', 60, 1, 1, 1);

UPDATE dbo.LogType WITH(UPDLOCK, ROWLOCK)
SET LogTypeName = 'Insert CustomerInfo'
WHERE LogTypeId = 12;

UPDATE dbo.LogType WITH(UPDLOCK, ROWLOCK)
SET LogTypeName = 'Delete CustomerInfo'
WHERE LogTypeId = 13;