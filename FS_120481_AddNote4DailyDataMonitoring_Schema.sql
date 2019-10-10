/*
Creator: 20191010@Long.Luu
Task:    Add Note for Daily Data Monitoring report [Redmine ID: 120481]
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

ALTER TABLE [dbo].[ChangedMatch]
ADD Note				NVARCHAR(500) NULL;
GO
