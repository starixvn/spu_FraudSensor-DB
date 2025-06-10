/*
Creator: 20250610@John.Ngo
Task: FS - Remove Unused Table [RedmineID: #225337]
Server:  DB052/DB053

Reviewer: Sol
*/ 
USE bk;

-- Rename 2 tables: bets_Translog, betsReject_Translog
EXEC sp_rename 'bets_Translog', 'DEL_bets_Translog';
EXEC sp_rename 'betsReject_Translog', 'DEL_betsReject_Translog';

-- Monitor for 1 week & Drop table
DROP TABLE dbo.DEL_bets_Translog;
DROP TABLE dbo.DEL_betsReject_Translog;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor"></info>*/
