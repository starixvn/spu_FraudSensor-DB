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
		[SuperId]		ASC,
		[Game]			ASC,
		[BettypeId]		ASC,
		[IsLive]		ASC
	)
) ON [DATA]
GO

CREATE TABLE [dbo].[SoccerWeeklyData](
	[FromDate]			DATE NOT NULL,
	[ToDate]			DATE NOT NULL,
	[WeekOrder]			INT NOT NULL,
	[CustId]			INT NOT NULL,
	[SuperId]			INT NOT NULL,
	[BettypeId]			SMALLINT NOT NULL,
	[LeagueId]			INT NOT NULL,
	[IsMajorLeague]		BIT,
	[IsLive]			BIT NOT NULL,
	[RealTurnover]		MONEY NULL,
	[RealWinloss]		MONEY NULL,
	[BetCount]			INT NULL,
	[VirtualRate]		FLOAT,
	[IsDeposit]			BIT,
	CONSTRAINT PK_SoccerWeeklyData PRIMARY KEY CLUSTERED (
		[FromDate]		ASC,
		[ToDate]		ASC,
		[CustId]		ASC,
		[SuperId]		ASC,
		[BettypeId]		ASC,
		[LeagueId]		ASC,
		[VirtualRate]	ASC,
		[IsLive]		ASC
	)
) ON [DATA]
GO

CREATE TABLE [dbo].[RobotPunterWeeklyData](
	[FromDate]			DATE NOT NULL,
	[ToDate]			DATE NOT NULL,
	[WeekOrder]			INT NOT NULL,
	[CustId]			INT NOT NULL,
	[SuperId]			INT NOT NULL,
	[SportId]			INT NOT NULL,
	[IsLive]			BIT NOT NULL,
	[RealTurnover]		MONEY NULL,
	[RealWinloss]		MONEY NULL,
	[BetCount]			INT NULL,
	CONSTRAINT PK_RobotPunterWeeklyData PRIMARY KEY CLUSTERED (
		[FromDate]		ASC,
		[ToDate]		ASC,
		[CustId]		ASC,
		[SportId]		ASC,
		[IsLive]		ASC
	)
) ON [DATA]
GO
