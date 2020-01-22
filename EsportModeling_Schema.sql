CREATE TABLE [dbo].[EsportWeeklyData](
	[CustId]			INT NOT NULL,
	[CurrencyId]		INT NOT NULL,
	[LicenseeId]		INT NOT NULL,
	[WeekOrder]			INT NOT NULL,
	[GameId]			SMALLINT NOT NULL,
	[BettypeId]			SMALLINT NOT NULL,
	[IsLive]			BIT NOT NULL,
	[RealTurnover]		MONEY NULL,
	[RealIncome]		MONEY NULL,
	[VirtualWinloss]	MONEY NULL,
	[BetCount]			INT NULL,
	[CumulativeMargin]	MONEY NULL,
	CONSTRAINT PK_EsportWeeklyData PRIMARY KEY CLUSTERED (
		[CustId]		ASC,
		[CurrencyId]	ASC,
		[LicenseeId]	ASC,
		[WeekOrder]		ASC,
		[GameId]		ASC,
		[BettypeId]		ASC,
		[IsLive]		ASC
	)
) ON [DATA]
GO

CREATE NONCLUSTERED INDEX IX_EsportWeeklyData_CumulativeMargin ON [dbo].[EsportWeeklyData] (
	[CumulativeMargin]	ASC
)
GO