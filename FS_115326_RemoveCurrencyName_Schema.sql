/*
Creator: 2019624@John.Ngo
Task:    Remove Curreny Name on FS DB and use ID instead [Redmine ID: 115326]
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

USE	bodb_FraudSensor;
GO

--- SuspiciousCustomer
ALTER TABLE dbo.SuspiciousCustomer
DROP COLUMN CurrencyName;
GO

--- DROP TABLES
DROP TABLE dbo.Trace_Log;