/*
Creator: 20190403@Long
Task:    Add more filters for Arbitrage fraud case details [Redmine ID: 111069]
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

ALTER TABLE [dbo].[ArbitrageTicketDetails]
ADD LiveHomeScore SMALLINT NULL;

ALTER TABLE [dbo].[ArbitrageTicketDetails]
ADD LiveAwayScore SMALLINT NULL;

CREATE NONCLUSTERED INDEX NIX_ArbitrageTicketDetails_Bettype_Handicap_Totalscore ON [dbo].[ArbitrageTicketDetails] (
	BetType				ASC,
	Handicap			ASC,
	TotalScores			ASC
) ON IDX;
GO