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
) ON DATA

CREATE CLUSTERED INDEX CIX_ArbitrageTicketDetails_bk_MatchIdCustId ON dbo.ArbitrageTicketDetails_bk
(	
	EventDate	ASC,
	MatchId	ASC,
	CustId ASC
) ON DATA

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
		EventDate ASC,
		FraudCaseId ASC,
		MatchId ASC,
		CustId ASC
	) ON DATA
) ON DATA 

----===================C. ALTER TABLES=========================
----===========================================================
