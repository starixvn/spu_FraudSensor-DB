/*
Creator: 20190419@Casey.Huynh	
Task:  Arbitrage Archive Data before BU Day
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

USE	bodb_FraudSensor;
GO
----===================A. DROP TABLES=========================
----==========================================================


----===================B. CREATE TABLES========================
----===========================================================

CREATE TABLE dbo.ArbitrageTicketDetails_bk(
	CustId			INT NOT NULL,
	MatchId			INT NOT NULL,
	GroupId			INT NOT NULL,
	TransIds		VARCHAR(MAX) NULL,
	BetType			INT NOT NULL,
	Handicap		MONEY NOT NULL,
	TicketCounter	INT NULL,
	IsIPFraud		BIT NULL,
	GraphDBGroupId	INT NULL,
	LiveHomeScore	SMALLINT NULL,
	LiveAwayScore	SMALLINT NULL,
	EventDate		DATETIME NULL
) ON IDX TEXTIMAGE_ON DATA

CREATE CLUSTERED INDEX CIX_ArbitrageTicketDetails_bk_MatchIdCustId ON dbo.ArbitrageTicketDetails_bk
(
	MatchId	ASC,
	CustId ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON IDX

CREATE NONCLUSTERED INDEX NCIX_ArbitrageTicketDetails_bk_Bettype_Handicap_LiveHomeAwayScore ON dbo.ArbitrageTicketDetails_bk
(
	BetType ASC,
	Handicap ASC,
	LiveHomeScore ASC,
	LiveAwayScore ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON IDX

CREATE NONCLUSTERED INDEX NCIX_ArbitrageTicketDetails_bk_EventDate ON dbo.ArbitrageTicketDetails_bk
(
	EventDate ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON IDX

--------------------------------------------------------------------

CREATE TABLE dbo.ArbitrageSuspiciousInfo_bk(
	CustId				INT NOT NULL,
	MatchId				INT NOT NULL,
	FraudCaseId			TINYINT NOT NULL,
	EventDate			DATETIME NULL,
	SuspiciousDate		DATETIME NULL,
	TransIds			VARCHAR(MAX) NULL,
	IsVerified			BIT NULL DEFAULT ((0)),
	ViolationCounter	INT NULL,
	TicketCounter		INT NULL,
	VerifiedDate		DATETIME NULL,
	VerifiedBy			INT NULL,
 CONSTRAINT PK_ArbitrageSuspiciousInfo_bk PRIMARY KEY CLUSTERED 
(
	FraudCaseId ASC,
	MatchId ASC,
	CustId ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON DATA
) ON DATA TEXTIMAGE_ON DATA


CREATE NONCLUSTERED INDEX NCIX_ArbitrageSuspiciousInfo_bk_CustId ON dbo.ArbitrageSuspiciousInfo_bk
(
	CustId ASC
)
INCLUDE ( 	IsVerified) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON IDX
GO

CREATE NONCLUSTERED INDEX NCIX_ArbitrageSuspiciousInfo_bk_EventDate ON dbo.ArbitrageSuspiciousInfo_bk
(
	EventDate ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON IDX
GO

----===================C. ALTER TABLES=========================
----===========================================================
