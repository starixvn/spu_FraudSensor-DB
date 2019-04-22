/*
Creator:	20180209@LongLuu
Task:		Create tables for Fraud Sensor
Server:		DB054.bodb_FraudSensor

Reviewer:	@Billy
*/

USE	bodb_FraudSensor;
GO

CREATE TABLE [dbo].[FraudCase] (
	[FraudCaseId]           TINYINT IDENTITY(1,1) NOT NULL,
	[FraudCaseName]         NVARCHAR(100) NOT NULL,
	[FraudCaseDesc]         NVARCHAR(500) NULL,
	[FraudCaseInterval]     INT NULL,
	[IsActive]              BIT DEFAULT((1)) NULL,
	[IsTest]                BIT DEFAULT((0)) NULL,
CONSTRAINT [PK_FraudCase] PRIMARY KEY CLUSTERED
(
	[FraudCaseId]           ASC
) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO
CREATE UNIQUE NONCLUSTERED INDEX IX_FraudCase_FraudCaseName ON [dbo].[FraudCase] (
	[FraudCaseName]         ASC
) ON IDX;
GO
-----------
CREATE TABLE [dbo].[DelayGoalAccount] (
	[CustId]                INT NOT NULL,
	[CreatedBy]             INT NULL,
	[CreatedDate]           DATETIME NULL,
CONSTRAINT [PK_DelayGoalAccount] PRIMARY KEY CLUSTERED
(
	[CustId]                ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO
-----------
CREATE TABLE [dbo].[FlaggedAccount] (
	[CustId]                INT NOT NULL,
	[Username]				NVARCHAR(50) NOT NULL,
	[EvidenceCode]          NVARCHAR(50) NOT NULL,
	[LevelId]               TINYINT NOT NULL,
CONSTRAINT [PK_FlaggedAccount] PRIMARY KEY CLUSTERED
(
	[Username]              ASC,
	[EvidenceCode]			ASC,
	[LevelId]               ASC,
	[CustId]                ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO
CREATE NONCLUSTERED INDEX IX_FlaggedAccount_CustId ON [dbo].[FlaggedAccount] (
	[CustId]                ASC
) ON IDX;
GO
-----------
CREATE TABLE [dbo].[ScannedMatch] (
	[MatchId]					INT NOT NULL,
	[FraudCaseId]				TINYINT NOT NULL,
	[ScannedDate]				DATE NULL,
	[SuspiciousTicketsCount]	INT NULL,
CONSTRAINT [PK_ScannedMatch] PRIMARY KEY CLUSTERED
(
	[MatchId]                   ASC,
	[FraudCaseId]               ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO

CREATE NONCLUSTERED INDEX CIX_ScannedMatch_ScannedDate ON [dbo].[ScannedMatch] (
	[ScannedDate]               ASC
) ON IDX;
GO
-----------
CREATE TABLE [dbo].[SuspiciousInfo](
	[CustId]                    INT NOT NULL,
	[MatchId]                   INT NOT NULL,
	[FraudCaseId]               TINYINT NOT NULL,
	[EventDate]                 DATETIME NULL,
	[SuspiciousDate]            DATETIME NULL,
	[TransIds]                  VARCHAR(MAX) NULL,
	[ViolationCounter]          SMALLINT NULL,
	[IsVerified]                BIT DEFAULT ((0)) NULL,
CONSTRAINT [PK_SuspiciousInfo] PRIMARY KEY CLUSTERED
(
	[CustId]                    ASC,
	[MatchId]                   ASC,
	[FraudCaseId]               ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO

CREATE NONCLUSTERED INDEX CIX_SuspiciousInfo_EventDate ON [dbo].[SuspiciousInfo] (
	[EventDate]                 ASC
) ON IDX;
GO
-----------
CREATE TABLE [dbo].[SuspiciousMatch](
	[MatchId]                   INT NOT NULL,
	[IsVerified]                BIT DEFAULT ((0)) NULL,
	[VerifiedBy]                INT NULL,
	[VerifiedDate]              DATETIME NULL,
	[IsDelinquent]              BIT DEFAULT ((0)) NULL,
	[DelinquentedBy]            INT NULL,
	[DelinquentedDate]          DATETIME NULL,
CONSTRAINT [PK_SuspiciousMatch] PRIMARY KEY CLUSTERED
(
	[MatchId]                   ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO

CREATE NONCLUSTERED INDEX CIX_SuspiciousMatch_IsVerified ON [dbo].[SuspiciousMatch] (
	[IsVerified]                ASC
) ON IDX;
GO
-----------
CREATE TABLE [dbo].[SuspiciousCustomer](
	[Custid]                    INT NOT NULL,
	[IsDelinquent]              BIT DEFAULT ((0)) NULL,
	[IsHedge]                   BIT DEFAULT ((0)) NULL,
CONSTRAINT [PK_SuspiciousCustomer] PRIMARY KEY CLUSTERED
(
	[Custid]                    ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO
CREATE NONCLUSTERED INDEX CIX_SuspiciousCustomer_DelinquentHedge ON [dbo].[SuspiciousCustomer] (
	[IsDelinquent]              ASC,
	[IsHedge]                   ASC
) ON IDX;
GO
-----------
CREATE TABLE [dbo].[OddsLog](
	[LogDate]                   SMALLDATETIME NOT NULL,
	[OddsId]                    INT NOT NULL,
	[Maxbet]                    FLOAT NULL,
CONSTRAINT [PK_OddsLog] PRIMARY KEY CLUSTERED
(
	[LogDate]                   ASC,
	[OddsId]                    ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO
-----------
CREATE TABLE [dbo].[LogType](
	[LogTypeId]                 SMALLINT NOT NULL,
	[LogTypeName]               NVARCHAR(50) NULL,
	[LogTypeDesc]               NVARCHAR(200) NULL,
CONSTRAINT [PK_LogType] PRIMARY KEY CLUSTERED
(
	[LogTypeId]                 ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO
-----------
CREATE TABLE [dbo].[UserLog](
	[LogTypeId]                 SMALLINT NOT NULL,
	[CreatorId]                 INT NOT NULL,
	[LoggedDate]                DATETIME NOT NULL,
	[SPName]                    VARCHAR(128) NULL,
	[Details]                   NVARCHAR(500) NULL
) ON UserLog;
GO
CREATE INDEX CIX_UserLog_LogTypeIdCreatorId ON [dbo].[UserLog] (
	[LogTypeId]                 ASC,
	[CreatorId]                 ASC,
	[LoggedDate]                ASC
) ON UserLog;
GO
-----------
CREATE TABLE [dbo].[MatchLiveScore](
	[MatchId]                   INT NOT NULL,
	[FraudCaseId]               TINYINT NOT NULL,
	[LiveHomeScore]             SMALLINT NULL,
	[LiveAwayScore]             SMALLINT NULL,
CONSTRAINT [PK_MatchLiveScore] PRIMARY KEY CLUSTERED
(
	[MatchId]                   ASC,
	[FraudCaseId]               ASC
) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO
-------CASEY CREATE TABLE [dbo].[MonitorMatch]--------
CREATE TABLE [dbo].[MonitorMatch] (
	[MatchId] [int] NOT NULL,
	[IsVerified] [bit] NULL,
	[VerifiedDate] [datetime] NULL,
	[VerifiedBy] [int] NULL,
	[Notes] [nvarchar](2000) NULL,
 CONSTRAINT [PK_MonitorMatchNotes] PRIMARY KEY CLUSTERED 
(
	[MatchId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
--------CASEY CREATE TABLE [dbo].[DelayGoalMatchScanning]---------
CREATE TABLE [dbo].[DelayGoalMatchScanning](
	[MatchId] [int] NOT NULL,
	[EventDate] [datetime] NOT NULL,
	[KickOffTime] [datetime] NOT NULL,
	[fromTransId] [bigint] NOT NULL,
 CONSTRAINT [PK_DelayGoalMatchScanning] PRIMARY KEY CLUSTERED 
(
	[MatchId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
