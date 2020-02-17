GO

CREATE TABLE [dbo].[VR2Model_SoccerWeeklyData](
	[FromDate]			DATE NOT NULL,
	[ToDate]			DATE NOT NULL,
	[CustId]			INT NOT NULL,
	[SuperId]			INT NOT NULL,
	[BettypeId]			SMALLINT NOT NULL,
	[LeagueId]			INT NOT NULL,
	[IsLive]			BIT NOT NULL,
	[RealTurnover]		MONEY NULL,
	[RealWinloss]		MONEY NULL,
	[BetCount]			INT NULL,
	[IsDeposit]			BIT,
	CONSTRAINT PK_VR2Model_SoccerWeeklyData PRIMARY KEY CLUSTERED (
		[FromDate]		ASC,
		[ToDate]		ASC,
		[IsDeposit]		ASC,
		[IsLive]		ASC,
		[LeagueId]		ASC,
		[BettypeId]		ASC,
		[CustId]		ASC
	)
) ON [DATA]
GO

CREATE TABLE [dbo].[VR2Model_StagingSoccerWeeklyData](
	[FromDate]			DATE NOT NULL,
	[ToDate]			DATE NOT NULL,
	[WeekOrder]			INT NOT NULL,
	[CustId]			INT NOT NULL,
	[SuperId]			INT NOT NULL,
	[RealTurnover]		MONEY NULL,
	[RealWinloss]		MONEY NULL,
	CONSTRAINT PK_VR2Model_StagingSoccerWeeklyData PRIMARY KEY CLUSTERED (
		[FromDate]		ASC,
		[ToDate]		ASC,
		[CustId]		ASC,
		[SuperId]		ASC,
		[WeekOrder]		ASC
	)
);
GO

CREATE TABLE [dbo].[VR2Model_CumulativeMarginByWeek] (
		[CustId]		INT NOT NULL
	,	[SuperId]		INT NOT NULL
	,	[Margin]		NUMERIC(1,1) NOT NULL
	,	[WeekOrder]	    INT
	,	CONSTRAINT PK_VR2Model_CumulativeMarginByWeek PRIMARY KEY CLUSTERED(
			[CustId]    ASC,
			[SuperId]	ASC,
			[WeekOrder] ASC				
		)
) ON [DATA]
GO

CREATE NONCLUSTERED INDEX [IX_VR2Model_CumulativeMarginByWeek_Margin] ON [dbo].[VR2Model_CumulativeMarginByWeek]
(
		[Margin]		ASC
	,	[WeekOrder]		ASC
)
GO


CREATE TABLE [dbo].[VR2Model_CustomerCumulativeInfo] (
		[CustId]		    INT NOT NULL
	,	[SuperId]			INT NOT NULL
	,	[Margin]		    NUMERIC(1,1) NOT NULL
	,	[NumOfWeeksBet]	    INT
	,	CONSTRAINT PK_VR2Model_CustomerCumulativeInfo PRIMARY KEY CLUSTERED(
			[CustId]    ASC
		)
) ON [DATA]
GO

CREATE TABLE [dbo].[VR2Model_PlayersCumulative] (
		[CustId]			INT NOT NULL
	,	[LeagueId]			INT NOT NULL				
	,	[BettypeId]			INT NOT NULL
	,	[IsLive]			BIT NOT NULL
	,	[CumulativeMargin]	FLOAT
	,	CONSTRAINT PK_VR2Model_PlayersCumulative PRIMARY KEY CLUSTERED(
			[CustId]      ASC,
			[LeagueId]    ASC,
			[BettypeId]   ASC,
			[IsLive]      ASC
		)
) ON [DATA]
GO

CREATE TABLE [dbo].[VR2Model_WinnerByWeekCounter] (
		[MarginRange]		FLOAT NOT NULL
	,	[WeekOrder]		    SMALLINT
	,	[NumOfWinner]		INT
	,	CONSTRAINT PK_VR2Model_WinnerByWeekCounter PRIMARY KEY CLUSTERED(
			[MarginRange]  ASC,
			[WeekOrder]    ASC 
		)
) ON [DATA]
GO

CREATE TABLE [dbo].[VR2Model_LoserByWeekCounter] (
		[MarginRange]		FLOAT NOT NULL
	,	[WeekOrder]		    SMALLINT
	,	[NumOfLoser]		INT
	,	CONSTRAINT PK_VR2Model_LoserByWeekCounter PRIMARY KEY CLUSTERED(
			[MarginRange]	ASC,
			[WeekOrder]		ASC
		)
) ON [DATA]
GO

CREATE TABLE [dbo].[VR2Model_RawChanceOfDanger](
		[MarginRange]		FLOAT NOT NULL
	,	[WeekOrder]			SMALLINT
	,	[PercentageOfWin]	FLOAT
	,	CONSTRAINT PK_VR2Model_RawChanceOfDanger PRIMARY KEY CLUSTERED(
			[MarginRange]   ASC, 
			[WeekOrder]     ASC
		)
) ON [DATA]
GO

CREATE TABLE [dbo].[VR2Model_HorizontalSlopeIntercept](
		[MarginRange]	FLOAT 
	,	[Slope]			FLOAT
	,	[Intercept]		FLOAT
	,   CONSTRAINT PK_VR2Model_HorizontalSlopeIntercept PRIMARY KEY CLUSTERED ([MarginRange])
) ON [DATA]
GO

CREATE TABLE [dbo].[VR2Model_VerticalSlopeInterceptWinner](
		[WeekOrder]		SMALLINT
	,	[Slope]			FLOAT
	,	[Intercept]		FLOAT
	,	CONSTRAINT PK_VR2Model_VerticalSlopeInterceptWinner PRIMARY KEY CLUSTERED ([WeekOrder])
) ON [DATA]
GO

CREATE TABLE [dbo].[VR2Model_VerticalSlopeInterceptLoser](
		[WeekOrder]		SMALLINT
	,	[Slope]			FLOAT
	,	[Intercept]		FLOAT
	,	CONSTRAINT PK_VR2Model_VerticalSlopeInterceptLoser PRIMARY KEY CLUSTERED ([WeekOrder])
) ON [DATA]
GO

CREATE TABLE [dbo].[VR2Model_ChanceOfDangerSmoothHorizontal](
		[MarginRange]		FLOAT NOT NULL
	,	[WeekOrder]			SMALLINT
	,	[PercentageOfWin]	FLOAT
	,	CONSTRAINT PK_VR2Model_ChanceOfDangerSmoothHorizontal PRIMARY KEY CLUSTERED(
			[MarginRange]   ASC,
			[WeekOrder]     ASC
		)
) ON [DATA]
GO

CREATE TABLE [dbo].[VR2Model_ChanceOfDangerSmoothVertical](
		[MarginRange]		FLOAT NOT NULL
	,	[WeekOrder]			SMALLINT
	,	[PercentageOfWin]	FLOAT
	,	CONSTRAINT PK_VR2Model_ChanceOfDangerSmoothVertical PRIMARY KEY CLUSTERED (
			[MarginRange]   ASC,
			[WeekOrder]     ASC
		)
) ON [DATA]
GO

CREATE TABLE [dbo].[VR2Model_ChanceOfDanger](
		[MarginRange]		FLOAT NOT NULL
	,	[WeekOrder]			SMALLINT
	,	[PercentageOfWin]	FLOAT
	,	CONSTRAINT PK_VR2Model_ChanceOfDanger PRIMARY KEY CLUSTERED (
			[MarginRange]  ASC,
			[WeekOrder]    ASC
		)
) ON [DATA]
GO

CREATE TABLE [dbo].[VR2Model_LicenseeModifier](
		[SuperId]			INT NOT NULL PRIMARY KEY
	,	[PercentageOfWin]	FLOAT
) ON [DATA]
GO

CREATE TABLE [dbo].[VR2Model_VirtualRate] (
		[CustId]				INT NOT NULL
	,	[IsDeposit]				BIT NOT NULL
	,	[IsLive]				BIT NOT NULL
	,	[SportId]				INT		
	,	[LeagueGroupId]			INT			
	,	[LeagueId]				INT
	,	[BettypeGroupId]		INT
	,	[BettypeId]				INT
	,	[VirtualMultiplier]		FLOAT 
	,	[CreatedDate]			DATETIME
	,	CONSTRAINT PK_VR2Model_VirtualRate PRIMARY KEY CLUSTERED(
			[CustId]			ASC,
			[IsDeposit]			ASC,
			[IsLive]			ASC,
			[SportId]			ASC,
			[LeagueGroupId]		ASC,
			[LeagueId]			ASC,
			[BettypeGroupId]	ASC,
			[BettypeId]			ASC
		)
) ON [DATA]
GO