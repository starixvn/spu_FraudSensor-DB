CREATE TABLE [dbo].[EsportWeeklyData](
	[FromDate]			DATE NOT NULL,
	[ToDate]			DATE NOT NULL,
	[WeekOrder]			INT NOT NULL,
	[CustId]			INT NOT NULL,
	[CurrencyId]		INT NOT NULL,
	[LicenseeAgent]		VARCHAR(3) NOT NULL,
	[SuperId]			INT NOT NULL,
	[Game]				VARCHAR(50) NOT NULL,
	[BettypeId]			SMALLINT NOT NULL,
	[IsLive]			BIT NOT NULL,
	[RealTurnover]		MONEY NULL,
	[RealIncome]		MONEY NULL,
	[VirtualWinloss]	MONEY NULL,
	[BetCount]			INT NULL,
	CONSTRAINT PK_EsportWeeklyData PRIMARY KEY CLUSTERED (
		[FromDate]		ASC,
		[ToDate]		ASC,
		[CustId]		ASC,
		[Game]			ASC,
		[BettypeId]		ASC,
		[IsLive]		ASC
	)
) ON [DATA]
GO
