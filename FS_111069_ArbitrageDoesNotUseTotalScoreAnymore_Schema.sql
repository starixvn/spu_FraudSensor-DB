/*
Creator: 20190409@Long.Luu
Task:    Do not use TotalScore for calculating Arbitrage anymore [Redmine ID: 111069]
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

--- Table [ArbitrageTicketDetails]
DROP INDEX NIX_ArbitrageTicketDetails_Bettype_Handicap_Totalscore 
    ON [dbo].[ArbitrageTicketDetails]
GO

ALTER TABLE [dbo].[ArbitrageTicketDetails]
DROP COLUMN TotalScores;
GO

ALTER TABLE [dbo].[ArbitrageTicketDetails]
ADD EventDate				DATETIME NULL;
GO

CREATE NONCLUSTERED INDEX NIX_ArbitrageTicketDetails_Bettype_Handicap_LiveHomeAwayScore ON [dbo].[ArbitrageTicketDetails] (
		[BetType]			ASC
	,	[Handicap]			ASC
	,	[LiveHomeScore]		ASC
	,	[LiveAwayScore]		ASC
) ON IDX;
GO

CREATE NONCLUSTERED INDEX NIX_ArbitrageTicketDetails_EventDate ON [dbo].[ArbitrageTicketDetails] (
		[EventDate]			ASC
) ON IDX;
GO

--- Table [ArbitrageMatchScoreHDP]
DROP TABLE [dbo].[ArbitrageMatchScoreHDP];
GO

CREATE TABLE [dbo].[ArbitrageMatchScoreHDP](
	[MatchId]			[int] NOT NULL,
	[BetType]			[int] NOT NULL,
	[Handicap]			[money] NOT NULL,
	[LiveHomeScore]		[smallint] NOT NULL,
	[LiveAwayScore]		[smallint] NOT NULL,
	[HasScanned]		[bit] NULL DEFAULT ((0)),
	[UpdatedDate]		[datetime] NULL,
 CONSTRAINT [PK_ArbitrageMatchScoreHDP] PRIMARY KEY CLUSTERED 
(
	[MatchId]			ASC,
	[BetType]			ASC,
	[Handicap]			ASC,
	[LiveHomeScore]		ASC,
	[LiveAwayScore]		ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA] 
GO
