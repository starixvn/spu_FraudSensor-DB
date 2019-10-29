/*
Creator: 20191025@Long.Luu
Task:    Add Login Transaction into Office IP Scanning [Redmine ID: 121800]
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

CREATE TABLE [dbo].[OfficeIPLogIn](
	[CustId]			BIGINT NOT NULL,
	[TransDate]			DATETIME NOT NULL,
	[IP]				NVARCHAR(15) NOT NULL,
	[SubscriberId]		INT NOT NULL,
	[CreatedDate]		DATETIME NOT NULL,
) ON [DATA] 
GO

CREATE CLUSTERED INDEX CIX_OfficeIPLogIn_TransDate ON [dbo].[OfficeIPLogIn] (
		[TransDate]		ASC
	,	[CustId]		ASC
) ON IDX;
GO