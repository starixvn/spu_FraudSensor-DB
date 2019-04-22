/*
Creator: 20181023@LongLuu
Task:  Adjust index for [ArbitrageTicketDetails] - Sprint#x
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
ALTER TABLE [dbo].[ArbitrageTicketDetails]
DROP CONSTRAINT PK_ArbitrageTicketDetails;
GO

DROP INDEX NCIX_ArbitrageTicketDetails_MatchId   
    ON [dbo].[ArbitrageTicketDetails]
GO

DROP INDEX NCIX_ArbitrageTicketDetails_MatchIdCustId 
    ON [dbo].[ArbitrageTicketDetails]
GO

CREATE CLUSTERED INDEX CIX_ArbitrageTicketDetails_MatchId ON [dbo].[ArbitrageTicketDetails] (
		[MatchId]			ASC
) ON IDX;
GO

CREATE NONCLUSTERED INDEX NCIX_ArbitrageTicketDetails_MatchIdCustId ON [dbo].[ArbitrageTicketDetails] (
		[MatchId]			ASC
	,	[CustId]			ASC
) ON IDX;
GO

CREATE NONCLUSTERED INDEX NCIX_ArbitrageTicketDetails_MatchIdBettypeHandicap ON [dbo].[ArbitrageTicketDetails] (
		[MatchId]			ASC
	,	[BetType]			ASC
	,	[Handicap]			ASC
	,	[TotalScores]		ASC
	,	[CustId]			ASC
	,	[GroupId]			ASC
) ON IDX;
GO