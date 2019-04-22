/*
Creator: 20190321@Long
Task:    Exclude Internal Accounts from Office IP [Redmine ID: 107865]
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

CREATE TABLE [dbo].[OfficeIPInternalAccount](
	[CustId]		INT NOT NULL,
	[RoleId]		TINYINT NOT NULL,
	[CreatedBy]		INT NULL,
	[CreatedDate]	DATETIME NULL,
	[IsActive]		BIT NULL,
 CONSTRAINT [PK_OfficeIPInternalAccount] PRIMARY KEY CLUSTERED 
(
	[CustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA]

GO
