/*
Creator: 20180618@LongLuu
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
CREATE TABLE [dbo].[CheckBetCategory](
	[CategoryId]			INT NOT NULL,
	[CategoryName]			NVARCHAR(100) NULL,
	[CategoryDataType]		NVARCHAR(15) NULL,
	[IsTest]				BIT DEFAULT(0),
CONSTRAINT [PK_CheckBetCategory] PRIMARY KEY CLUSTERED 
(
	[CategoryId]			ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO

CREATE TABLE [dbo].[ChangedTicket](
	[CategoryId]			INT NOT NULL,
	[TransId]				BIGINT NOT NULL,
	[CapturedDate]			DATETIME NOT NULL,
	[NewValue]				NVARCHAR(20) NULL,
	[OldValue]				NVARCHAR(20) NULL,
	[OldCaptureDate]		DATETIME NULL,
CONSTRAINT [PK_ChangedTicket] PRIMARY KEY CLUSTERED 
(
	[CategoryId]			ASC,
	[TransId]				ASC,
	[CapturedDate]			ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO

CREATE TABLE [dbo].[ChangedTicketGeneralInfo](
	[TransId]				BIGINT NOT NULL,
	[TransDate]				DATETIME NULL,
	[CustId]				INT NULL,
	[Username]				NVARCHAR(50) NULL,
	[MatchId]				INT NULL,
	[HomeId]				INT NULL,
	[AwayId]				INT NULL,
	[Bettype]				SMALLINT NULL,
	[Oddstype]				TINYINT NULL,
	[Currency]				NVARCHAR(50) NULL,
	[Creator]				NVARCHAR(50) NULL,
	[LiveIndicator]			BIT NULL,
CONSTRAINT [PK_ChangedTicketGeneralInfo] PRIMARY KEY CLUSTERED 
(
	[TransId]				ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO

CREATE TABLE [dbo].[CheckBetScannedMatch](
	[MatchId]				INT NOT NULL,
	[ScannedDate]			DATE NOT NULL,
 CONSTRAINT [PK_CheckBetScannedMatch] PRIMARY KEY CLUSTERED 
(
	[MatchId]				ASC,
	[ScannedDate]			ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO
----===================C. ALTER TABLES=========================
----===========================================================
