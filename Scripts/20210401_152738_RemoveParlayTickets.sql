/*
Creator: 20210401@Long
Task: Remove parlay ticket from CheckBet
Server:  bodb_FraudSensor
Revision:

Reviewer: Patrick
*/ 

USE bodb_FraudSensor;

DELETE FROM dbo.[ChangedTicket] WITH(ROWLOCK, UPDLOCK)
WHERE TransId IN (111472969043,111473759415,111473524430);
GO

DELETE FROM dbo.[ChangedTicketGeneralInfo] WITH(ROWLOCK, UPDLOCK)
WHERE TransId IN (111472969043,111473759415,111473524430);
GO

/*<info serverAlias="DBFS-bodb_FraudSensor"></info>*/
