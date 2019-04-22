/*
Creator: 20180920@LongLuu
Task:  Clear old data of Fraud Sensor 2.0 for PRO launching [Redmine ID: #101367]
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

TRUNCATE TABLE dbo.[BSNGScanInfo]
GO
TRUNCATE TABLE dbo.[BSNGScanInfoArchive]
GO
TRUNCATE TABLE dbo.[CapturedData]
GO
TRUNCATE TABLE dbo.[CapturedData_Pontus]
GO
TRUNCATE TABLE dbo.[ChangedMatch]
GO
TRUNCATE TABLE dbo.[ChangedTicket]
GO
TRUNCATE TABLE dbo.[ChangedTicketGeneralInfo]
GO
TRUNCATE TABLE dbo.[CheckBetScannedMatch]
GO
TRUNCATE TABLE dbo.[CustomerLog]
GO
TRUNCATE TABLE dbo.[CustomerMonitorAssignment]
GO
TRUNCATE TABLE dbo.[CustomerVerified]
GO
TRUNCATE TABLE dbo.[DBA_duplicatedData_tracking]
GO
TRUNCATE TABLE dbo.[DelayGoalAccount]
GO
TRUNCATE TABLE dbo.[DelayGoalMatchScanning]
GO
TRUNCATE TABLE dbo.[FraudNotificationRecipient]
GO
TRUNCATE TABLE dbo.[MatchLiveScore]
GO
TRUNCATE TABLE dbo.[MatchScore]
GO
TRUNCATE TABLE dbo.[Message]
GO
TRUNCATE TABLE dbo.[MonitorMatch]
GO
TRUNCATE TABLE dbo.[OddsLog]
GO
TRUNCATE TABLE dbo.[ScannedMatch]
GO
TRUNCATE TABLE dbo.[SuspiciousCustomer]
GO
TRUNCATE TABLE dbo.[SuspiciousInfo]
GO
TRUNCATE TABLE dbo.[SuspiciousMatch]
GO
TRUNCATE TABLE dbo.[TicketsByIP]
GO
TRUNCATE TABLE dbo.[Trap_TicketsByIp]
GO
TRUNCATE TABLE dbo.[UserLog]
GO
TRUNCATE TABLE dbo.[UserMessage]
GO