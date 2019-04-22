/*
Creator: 20181113@LongLuu
Task:  Permission for Special Currencies - [Redmine ID: 104707]
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

USE	bodb_FraudSensor;
GO


----===================A. DROP TABLES=========================
----==========================================================



----===================B. CREATE TABLES========================
----===========================================================
CREATE TABLE [dbo].[SpecialCurrency](
	[CurrencyId]			INT NOT NULL,
	[CurrencyName]			NVARCHAR(100) NULL,
	[CreatedBy]				INT NULL,
	[CreatedDate]			DATETIME NULL
CONSTRAINT [PK_SpecialCurrency] PRIMARY KEY CLUSTERED 
(
	[CurrencyId]			ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]
GO

-- custid = 20902509: Starix58
DECLARE @today DATETIME = GETDATE();
INSERT INTO dbo.SpecialCurrency(CurrencyId, CurrencyName, CreatedBy, CreatedDate)
SELECT exchangeid, currency, 20902509, @today FROM bodb02.dbo.Exchange WITH(NOLOCK) WHERE CODE IN ('USD','VND')

----===================A. ALTER TABLES=========================
----===========================================================