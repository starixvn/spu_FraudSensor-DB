/*
Creator: 20250507@John.Ngo
Task: [FS] Risk Control - Upgrade ExchangeID Data Type [RedmineID: #225337]
Server:  bodb_FraudSensor

Reviewer: Patrick
*/ 

USE bodb_FraudSensor;

-- 1. Drop the dependent index
DROP INDEX [NCIX_SuspiciousCustomer_CurrencyId] ON SuspiciousCustomer;

-- 2. Alter the column data type
ALTER TABLE SuspiciousCustomer
ALTER COLUMN CurrencyId SMALLINT NULL;

-- 3. Recreate the index
CREATE NONCLUSTERED INDEX [NCIX_SuspiciousCustomer_CurrencyId] ON [dbo].[SuspiciousCustomer] (
	[CurrencyId] ASC
) ON IDX;
GO

GO
/*<info serverAlias="DBFS-bodb_FraudSensor"></info>*/