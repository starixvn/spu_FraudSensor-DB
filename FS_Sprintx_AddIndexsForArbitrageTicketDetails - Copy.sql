/*
Creator: 20181004@LongLuu
Task:  Create tables for Fraud Sensor - Sprint#8
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

USE	bodb_FraudSensor;
GO


----===================A. DROP TABLES=========================
----==========================================================

----===================B. CREATE TABLES========================
----===========================================================

----===================C. ALTER TABLES=========================
----===========================================================

CREATE NONCLUSTERED INDEX NCIX_ArbitrageTicketDetails_MatchId ON [dbo].[ArbitrageTicketDetails] (
		[MatchId]			ASC
) ON IDX;
GO

CREATE NONCLUSTERED INDEX NCIX_ArbitrageTicketDetails_MatchIdCustId ON [dbo].[ArbitrageTicketDetails] (
		[MatchId]			ASC
	,	[CustId]			ASC
) ON IDX;
GO