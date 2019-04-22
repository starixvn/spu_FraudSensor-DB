/*
Creator: 20180406@LongLuu
Task:  Create tables for Fraud Sensor - Sprint#5
		+ 20180406@Casey: 
			> Alter Table DelayGoalAccount
			> Drop tables: EvidenceTypes, FlaggedAccount
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

USE	bodb_FraudSensor;
GO

--===========ALTER TABLES
ALTER TABLE [dbo].[DelayGoalAccount]
ADD		[IsManualAdd]		BIT NULL 
	,	[IsActive]			BIT NULL;

GO
ALTER TABLE [dbo].[DelayGoalAccount]
DROP CONSTRAINT PK_DelayGoalAccount

GO
ALTER TABLE [dbo].[DelayGoalAccount]
ALTER COLUMN CreatedBy INT NOT NULL; 

GO
ALTER TABLE [dbo].[DelayGoalAccount]
ADD CONSTRAINT [PK_DelayGoalAccount] PRIMARY KEY CLUSTERED
(
	 CustId             ASC
	,CreatedBy			ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]

GO
--=========DROP TABLES
DROP TABLE	FlaggedAccount;
DROP TABLE	EvidenceTypes;

	
