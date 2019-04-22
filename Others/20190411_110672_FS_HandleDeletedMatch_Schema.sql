/*
Creator: 20190410@Casey.Huynh
Task:  Handle Deleted Match Redmine ID: #111454
Server:  bodb_FraudSensor

Reviewer: Billy
*/
--==============================================
ALTER TABLE dbo.DelayGoalMatchScanning
	ADD	EventStatus			NVARCHAR(50)
		, IsScanCompleted	BIT

--=================================================

CREATE TABLE dbo.FlagAccountMatchScanning(
	MatchId			INT NOT NULL,
	EventDate		DATETIME NOT NULL,
	KickOffTime		DATETIME NOT NULL,
	EventStatus		NVARCHAR(50) NULL,
	IsScanCompleted BIT NULL,
 CONSTRAINT PK_FlagAccountMatchScanning PRIMARY KEY CLUSTERED 
(
	MatchId ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON DATA
) ON DATA

GO
