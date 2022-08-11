/*
Creator: 20220810@John.Ngo
Task: FS - Scale Out DBTrans [RedmineID: #176471]
Server:  bodb_FraudSensor
Revision:

Reviewer: Patrick
*/ 

USE bodb_FraudSensor;

-- TicketsByIP
ALTER TABLE [dbo].[TicketsByIP]
ADD SequenceID		BIGINT NULL;
GO

GO
/*<info serverAlias="DBFS-bodb_FraudSensor"></info>*/
