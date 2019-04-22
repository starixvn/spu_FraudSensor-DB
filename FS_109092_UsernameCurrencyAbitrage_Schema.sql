/*
Creator: 20190228@Casey
Task:    Implement IP Rule [Redmine ID: 109092]
		 Updata Username and Currency for SuspiciousCustomers table [Redmine ID: #107858]
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

---==========================================================================
ALTER TABLE ArbitrageTicketDetails
ADD IsIPFraud BIT

CREATE NONCLUSTERED INDEX [NCIX_ArbitrageTicketDetails_IsIPFraud] ON [dbo].[ArbitrageTicketDetails]
(
	[IsIPFraud] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [IDX]
GO
--============================================================================
ALTER TABLE SuspiciousCustomer
ADD CurrencyId		TINYINT NULL
	, CurrencyName	NVARCHAR(50) NULL
	, Username		NVARCHAR(50) NULL

CREATE NONCLUSTERED INDEX [NCIX_SuspiciousCustomer_CurrencyId] ON [dbo].[SuspiciousCustomer]
(
	[CurrencyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [IDX]
GO

---==========================================================================

CREATE TABLE [dbo].[ArbitrageSuspiciousInfo](
	[CustId] [int] NOT NULL,
	[MatchId] [int] NOT NULL,
	[FraudCaseId] [tinyint] NOT NULL,
	[EventDate] [datetime] NULL,
	[SuspiciousDate] [datetime] NULL,
	[TransIds] [varchar](max) NULL,
	[IsVerified] [bit] NULL DEFAULT ((0)),
	[ViolationCounter] [int] NULL,
	[TicketCounter] [int] NULL,
	[VerifiedDate] [datetime] NULL,
	[VerifiedBy] [int] NULL,
 CONSTRAINT [PK_ArbitrageSuspiciousInfo] PRIMARY KEY CLUSTERED 
(
	[FraudCaseId] ASC,
	[MatchId] ASC,
	[CustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA] TEXTIMAGE_ON [DATA]

GO

SET ANSI_PADDING OFF
GO

CREATE NONCLUSTERED INDEX [NCIX_ArbitrageSuspiciousInfo_EventDate] ON [dbo].[ArbitrageSuspiciousInfo]
(
	[EventDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [IDX]
GO

CREATE NONCLUSTERED INDEX [NCIX_ArbitrageSuspiciousInfo_CustId] ON [dbo].[ArbitrageSuspiciousInfo]
(
	[CustId] ASC
)
INCLUDE ( 	[IsVerified]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [IDX]
GO

-----------------

CREATE TABLE tempPerformance
(
	ID	INT			IDENTITY
	, StartTime		DATETIME	NULL
	, EndTime		DATETIME	NULL
	, Step			TinyINT
	, Notes			NVARCHAR(1000)	NULL
)