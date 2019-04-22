/*
Creator: 20180503@LongLuu
Task:  Create tables for Fraud Sensor - Sprint#6
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

USE	bodb_FraudSensor;
GO

--ALTER DATABASE bodb_FraudSensor  
--ADD FILEGROUP IDX;
--GO

ALTER DATABASE bodb_FraudSensor ADD FILE (NAME='idx_file', FILENAME='d:\idx\idx_file') TO FILEGROUP IDX;  

--=========== DROP TABLES
DROP TABLE	[dbo].[CustomerLogType];
DROP TABLE	[CustomerLog];
DROP TABLE	[CustomerMonitorAssignment]
GO

--=========== CREATE TABLES
CREATE TABLE	[dbo].[TicketsByIP](
	[TransId]				BIGINT NOT NULL,
	[IP]					NVARCHAR(15) NOT NULL
CONSTRAINT [PK_TicketsByIP] PRIMARY KEY CLUSTERED 
(
	[TransId]				ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO

CREATE NONCLUSTERED INDEX NIX_TicketsByIP_IP ON [dbo].[TicketsByIP] (
	[IP]					ASC
) ON IDX;
GO

CREATE TABLE	[dbo].[CustomerLog](
	[CustomerLogId] [int] IDENTITY(1,1) NOT NULL,
	[CustId] [int] NOT NULL,
	[CreatorId] [int] NOT NULL,
	[CaseId] [int] NULL,
	[LogDesc] [nvarchar](500) NULL,
	[LogDate] [datetime] NULL,
	[CustLogType] [nvarchar](20) NULL,
 CONSTRAINT [PK_CustomerLog] PRIMARY KEY CLUSTERED 
(
	[CustomerLogId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO

CREATE NONCLUSTERED INDEX NIX_CustomerLog_CustId ON [dbo].[CustomerLog] (
	[CustId]					ASC
) ON IDX;
GO
CREATE NONCLUSTERED INDEX NIX_CustomerLog_CustLogType ON [dbo].[CustomerLog] (
	[CustLogType]					ASC
) ON IDX;
GO

CREATE TABLE [dbo].[CustomerMonitorAssignment](
	[CustId] [int] NOT NULL,
	[AssigneeId] [nvarchar](50) NULL,
	[LastModifiedDate] [datetime] NOT NULL,
	[CreatorId] [int] NOT NULL
	
	CONSTRAINT [PK_CustomerMonitorAssignment] PRIMARY KEY CLUSTERED 
	(
	[CustId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO

CREATE NONCLUSTERED INDEX NIX_CustomerMonitorAssignment_CustIdAssigneeId ON [dbo].[CustomerMonitorAssignment] (
	[CustId]					ASC
	,[AssigneeId]				ASC
) ON IDX;
GO

--=========== ALTER TABLES 
ALTER TABLE [dbo].[SuspiciousInfo]
ADD VerifiedBy INT NULL
	, VerifiedDate DATETIME NULL
GO

