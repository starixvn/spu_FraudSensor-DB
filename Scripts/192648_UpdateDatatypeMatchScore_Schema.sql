/*
Creator: 20230814@John.Ngo
Task: FS - Update datatype for MatchScore [Redmine ID: #192648]
Server:  bodb_FraudSensor
Revision:

Reviewer: Sol
*/ 

USE bodb_FraudSensor;

ALTER TABLE [dbo].[MatchScore]
ALTER COLUMN TotalScores SMALLINT NOT NULL;
GO

GO
/*<info serverAlias="DBFS-bodb_FraudSensor"></info>*/
