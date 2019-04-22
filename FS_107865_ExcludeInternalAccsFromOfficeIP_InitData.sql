/*
Creator: 20190321@Long
Task:    Exclude Internal Accounts from Office IP [Redmine ID: 107865]
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

INSERT INTO dbo.LogType (LogTypeId, LogTypeName, LogTypeDesc)
VALUES(22, 'Insert Office IP Internal Accounts', 'Insert Office IP Internal Accounts');

INSERT INTO dbo.LogType (LogTypeId, LogTypeName, LogTypeDesc)
VALUES(23, 'Update Office IP Internal Accounts', 'Update Office IP Internal Accounts');