/*
Created: 20200519@Long.Luu
Task : PreCondition for Group Betting fraud case
DB: bodb_FraudSensor

Reviewer: Patrick
*/ 

USE	bodb_FraudSensor;
GO
----===================A. DROP TABLES=========================
----==========================================================


----===================B. CREATE TABLES========================
----===========================================================
CREATE TABLE [dbo].[ScanningMatch](
		[MatchId]			INT NOT NULL
	,	[FraudCaseId]		TINYINT NOT NULL
    ,	[EventDate]			DATE NOT NULL
    ,	[KickOffTime]		DATETIME NOT NULL
    ,	[FromTransId]		BIGINT NULL
    ,	[EventStatus]		NVARCHAR(50)
    ,	[IsScanCompleted]	BIT DEFAULT(0)
	,	CONSTRAINT [PK_ScanningMatch] PRIMARY KEY CLUSTERED 
		(
				[FraudCaseId]		ASC
			,	[MatchId]			ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA] 
GO

CREATE NONCLUSTERED INDEX IX_ScanningMatch_IsScanCompletedEventDate ON [dbo].[ScanningMatch](
		[IsScanCompleted]	DESC
	,	[EventDate]			DESC
) ON [IDX];
GO

CREATE NONCLUSTERED INDEX IX_ScanningMatch_KickOffTime ON [dbo].[ScanningMatch](
		[KickOffTime]		DESC
) ON [IDX];
GO

----===================C. ALTER TABLES=========================
----===========================================================
