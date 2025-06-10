/*
Creator: 20250610@John.Ngo
Task: FS - Remove Unused Table [RedmineID: #225337]
Server:  DB052/DB053

Reviewer: Sol
*/ 
USE bk;

-- Rename 2 tables: bets_Translog, betsReject_Translog
EXEC sp_rename 'bets_Translog', 'bets_Translog_Archive';
EXEC sp_rename 'betsReject_Translog', 'betsReject_Translog_Archive';

-- Monitor for 1 week & Drop table
DROP TABLE dbo.bets_Translog_Archive;
DROP TABLE dbo.betsReject_Translog_Archive;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor"></info>*/
