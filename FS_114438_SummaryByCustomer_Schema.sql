/*
Creator: 20190607@John.Ngo
Task:    Summary total bets of Customer [Redmine ID: 114438]
Server:  bodb_FraudSensor

Reviewer: Billy
*/  

-- Daily
IF	OBJECT_ID('dbo.SummaryByCustomer_Daily') IS NULL
BEGIN
	CREATE TABLE [dbo].[SummaryByCustomer_Daily](
				CustId				INT
			,	MatchId				INT
			,	EventDate			DATETIME
			,	MatchCode			NVARCHAR(50)
			,	BetCount			INT
	) ON [DATA];

	CREATE CLUSTERED INDEX	CIX_SummaryByCustomer_Daily_EventDate_MatchId_CustId ON dbo.SummaryByCustomer_Daily (
			EventDate			ASC
		,	MatchId				ASC
		,	CustId				ASC
	) ON [DATA];
END;
GO