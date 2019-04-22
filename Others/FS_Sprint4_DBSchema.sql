/*
Creator: 20180320@LongLuu
		+ 20180318@CaseyHuynh: 
			- Table "FraudCase" Add Column [IsInternal](0: External, 1: Internal)
			- Table "SuspiciousCustomer" Add Column [IsVerified]
Task:  Create tables for Fraud Sensor
Server:  bodb_FraudSensor
*/

ALTER TABLE [dbo].[FraudCase]
ADD [IsInternal]		BIT NULL;
GO

ALTER TABLE [dbo].[SuspiciousInfo]
ADD [ViolationCounter]		INT NULL; 
GO

ALTER TABLE [dbo].[SuspiciousInfo]
ADD [TicketCounter]			INT NULL; 
GO
---------------
ALTER TABLE [dbo].[SuspiciousCustomer]
ADD [IsDirty]				BIT DEFAULT ((0)) NULL 
	,[IsVerified]			BIT DEFAULT ((0)) NULL;
GO

CREATE INDEX CIX_SuspiciousCustomer_Dirty ON [dbo].[SuspiciousCustomer] (
	[IsDirty]               ASC
)
GO
---------------
ALTER TABLE [dbo].[OddsLog] 
DROP CONSTRAINT [PK_OddsLog];   
GO  

ALTER TABLE [dbo].[OddsLog] 
ALTER COLUMN [LogDate]		DATETIME NOT NULL;
GO

ALTER TABLE [dbo].[OddsLog] 
ALTER COLUMN [OddsId]		INT NOT NULL;
GO

ALTER TABLE [dbo].[OddsLog] 
ADD CONSTRAINT PK_OddsLog PRIMARY KEY (
		LogDate				DESC
	,	OddsId				DESC
)
GO
---------------
CREATE TABLE [dbo].[CustomerLogType](
	[CustLogTypeId]         TINYINT IDENTITY(1,1) NOT NULL,
	[CustLogTypeName]       NVARCHAR(50) NOT NULL,
	[IsActive]				BIT DEFAULT((1)) NULL,
CONSTRAINT [PK_CustomerLogType] PRIMARY KEY CLUSTERED
(
	[CustLogTypeId]         ASC
) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO
---------------
CREATE TABLE [dbo].[CustomerLog](
	[CustomerLogId]			INT IDENTITY(1,1) NOT NULL,
	[CustId]				INT NOT NULL,
	[CustLogTypeId]			INT NOT NULL,
	[CreatorId]				INT NOT NULL,
	[CaseId]				INT NULL,
	[LogDesc]				NVARCHAR(500) NULL,
	[LogDate]				DATETIME NULL,
	[IsActive]				BIT DEFAULT((1)) NULL,
CONSTRAINT [PK_CustomerLog] PRIMARY KEY CLUSTERED 
(
	[CustomerLogId]			ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO
---------------
CREATE TABLE [dbo].[CustomerMonitorAssignment](
	[CustId]				INT NOT NULL,
	[AssigneeId]			INT NOT NULL,
	[LastModifiedDate]		DATETIME NOT NULL,
	[CreatorId]				INT NOT NULL,
) ON [DATA]
GO

CREATE CLUSTERED INDEX CIX_CustomerMonitorAssignment_CustIdAssigneeId ON [dbo].[CustomerMonitorAssignment] (
	[CustId]				ASC,
	[AssigneeId]			ASC
) ON IDX;
GO
---------------
CREATE TABLE [dbo].[CustomerVerified](
	[CustId]				INT NOT NULL,
	[FraudCaseId]			INT NOT NULL,
	[VerifiedDate]			DATETIME NOT NULL,
	[CreatorId]				INT NOT NULL,
	[CreatorName]			NVARCHAR(50) NOT NULL
) ON [DATA]
GO

CREATE CLUSTERED INDEX CIX_CustomerVerified_CustIdFraudCaseId ON [dbo].[CustomerVerified] (
	[CustId]				ASC,
	[FraudCaseId]			ASC
) ON IDX;
GO
---------------
CREATE TABLE [dbo].[EvidenceTypes](
	[EviGroupID]			INT NOT NULL,
	[EviCode]				NVARCHAR(50) NOT NULL,
	[IsActive]				BIT DEFAULT((1)) NULL,
	[EviName]				NVARCHAR(150) NULL,
	[EviDescription]		NVARCHAR(200) NULL,
	[EviPriority]			INT NULL,
	[OrderNo]				SMALLINT NULL,
 CONSTRAINT [PK_EvidenceTypes] PRIMARY KEY CLUSTERED 
(
	[EviCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO