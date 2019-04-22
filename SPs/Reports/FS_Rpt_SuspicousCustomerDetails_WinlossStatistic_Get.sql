USE [bodb_FraudSensor]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[FS_Rpt_SuspicousCustomerDetails_WinlossStatistic_Get]
						@CustId			INT
					,	@FromDate		DATETIME
					,	@ToDate			DATETIME
					,   @IsShowSpecialCurrencies	BIT = 0
AS
/*
	Created:	20180506@John.Ngo
	Task:		Customer Details report - Get Winloss Statistic
	Server:		

	Revisions:
		- 20180523:		 Add rptmonth and rptyear [Redmine: #95528]
		- 20181211@John: Adding View Permission on Special Currencies [Redmine ID: #104707]

	Param's Explanation: EXEC FS_Rpt_SuspicousCustomerDetails_WinlossStatistic_Get @FromDate='2017-10-04 00:00:00',@ToDate='2018-05-02 00:00:00',@CustId=28216314

*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE	@SupportedDate		DATETIME
		,	@NumDays			INT ;

	IF OBJECT_ID('tempdb..#CustomerStatistic') IS NOT NULL
	BEGIN
		DROP TABLE	#CustomerStatistic;
	END;

	CREATE TABLE	#CustomerStatistic (
						Bettype			SMALLINT
					,	LeagueId		INT
					,	IsLive			BIT
					,	Winloss100		MONEY
					,	Turnover100		MONEY
					,	BetCount		INT 
					,	RptYear INT
					,	RptMonth INT);
					
	IF OBJECT_ID('tempdb..#WinlostDate') IS NOT NULL
	BEGIN
		DROP TABLE	#WinlostDate;
	END;

	CREATE TABLE	#WinlostDate (
					winlostdate		DATETIME
					PRIMARY KEY CLUSTERED (winlostdate) );

	SELECT	TOP(1)
			@SupportedDate = cbd.rptDate 
	FROM	DBWH.bodb_Account.dbo.mcCustBettingDaily AS cbd WITH(NOLOCK)
	ORDER BY cbd.rptDate DESC;								
	
	SELECT	@NumDays = DATEDIFF(DAY, @FromDate, @ToDate) + 1;
		
	IF	@NumDays > 0
	BEGIN
		WITH cte AS (
			SELECT	TOP(@NumDays)
					[num]	= ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) - 1
			FROM		(VALUES (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) x10(n)
			CROSS APPLY	(VALUES (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) x100(n)
			CROSS APPLY	(VALUES (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) x1000(n)
			CROSS APPLY	(VALUES (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) x10000(n)
		)
		INSERT INTO	#WinlostDate (winlostdate)
		SELECT	DATEADD(DAY, cte.num, @FromDate)
		FROM	cte WITH(NOLOCK);
		
		INSERT INTO #CustomerStatistic (Bettype, LeagueId, IsLive, Winloss100, Turnover100, BetCount, RptYear, RptMonth)
		SELECT	[Bettype]		= b.bettype
			,	[LeagueId]		= ISNULL(m.leagueid, o.leagueid)
			,	[IsLive]		= b.liveindicator
			,	[Winloss100]	= SUM(winlost - actual_stake)
			,	[Turnover100]	= SUM(ABS(b.stake))
			,	[BetCount]		= COUNT(b.transid)
			,   [RptYear] = YEAR(b.winlostdate)
			,	[RptMonth] = MONTH(b.winlostdate)
		FROM		bodb02.dbo.bettrans AS b WITH (NOLOCK)
		INNER JOIN	#WinlostDate AS d WITH (NOLOCK)
				ON	b.winlostdate = d.winlostdate
		LEFT JOIN	bodb02.dbo.match AS m WITH (NOLOCK)
				ON	m.matchid = b.matchid
		LEFT JOIN	bodb02.dbo.outright AS o WITH (NOLOCK)
				ON	o.orid = b.matchid
		LEFT JOIN	bodb02.dbo.league AS l WITH (NOLOCK)
				ON	l.leagueid = o.leagueid		
		WHERE	b.custid = @CustId
			AND	b.winlostdate > @SupportedDate
			AND	b.statusID NOT IN (101, 102, 103)
			AND	b.ruben = 1
			AND	bettype < 19999
			AND	COALESCE(m.sporttype, l.sporttype, -1) <= 99
			AND (@IsShowSpecialCurrencies = 1 OR b.currency NOT IN (SELECT CurrencyId FROM dbo.SpecialCurrency WITH(NOLOCK)))
		GROUP BY b.bettype, ISNULL(m.leagueid, o.leagueid), liveindicator, YEAR(b.winlostdate), MONTH(b.winlostdate);
		
		 -- Add TOP() to fix wrong join order
		INSERT INTO #CustomerStatistic (Bettype, LeagueId, IsLive, Winloss100, Turnover100, BetCount, RptYear, RptMonth)
		SELECT 	[Bettype]		= _cbd.Bettype
			,	[LeagueId]		= _cbd.LeagueId
			,	[IsLive]		= _cbd.IsLive
			,	[Winloss100]	= _cbd.Winloss100
			,	[Turnover100]	= _cbd.Turnover100
			,	[BetCount]		= _cbd.BetCount
			,	[RptYear]		= _cbd.RptYear
			,	[RptMonth]		= _cbd.RptMonth
		FROM	#WinlostDate AS d WITH (NOLOCK) 
		CROSS APPLY	(
			SELECT	TOP(99999999)
					[Bettype]		= cbd.Bettype
				,	[LeagueId]		= cbd.LeagueId
				,	[IsLive]		= cbd.IsLive
				,	[Winloss100]	= SUM(cbd.Winloss100)
				,	[Turnover100]	= SUM(cbd.Turnover100)
				,	[BetCount]		= SUM(cbd.BetCount)
				,   [RptYear]		= YEAR(cbd.rptDate)
				,	[RptMonth]		= MONTH(cbd.rptDate)
			FROM	DBWH.bodb_Account.dbo.mcCustBettingDaily AS cbd WITH (NOLOCK)
			INNER JOIN	bodb02.dbo.league l WITH(NOLOCK)
					ON	cbd.leagueid = l.leagueid
			WHERE	cbd.custid = @CustId
				AND	cbd.rptDate = d.winlostdate
				AND	cbd.status NOT IN (-1,18,9,10,14)
				AND	cbd.leagueid > 0
				AND l.sporttype <= 99
				AND (@IsShowSpecialCurrencies = 1 OR cbd.currency NOT IN (SELECT CurrencyId FROM dbo.SpecialCurrency WITH(NOLOCK)))
			GROUP BY cbd.bettype, cbd.leagueid, cbd.islive, YEAR(cbd.rptDate), MONTH(cbd.rptDate)
		) _cbd
		WHERE	d.winlostdate <= @SupportedDate;
	END;					

	SELECT	[SumTO]			= SUM(cs.Turnover100)
		,	[SumWL]			= SUM(cs.Winloss100)
		,	[Margin]		= SUM(cs.Winloss100) / CASE WHEN SUM(cs.Turnover100) = 0 THEN 1 ELSE SUM(cs.Turnover100) END * 100
		,	[BetCount]		= SUM(cs.BetCount)
		,	[RptMonth] = cs.RptMonth
		,	[RptYear] = cs.RptYear
	FROM	#CustomerStatistic AS cs WITH (NOLOCK)
	GROUP BY cs.RptMonth, cs.RptYear;

	SELECT	[EventChoice]	= CASE WHEN cs.islive = 1 THEN 'Live' ELSE 'Non-Live' END
		,	[SumTO]			= SUM(cs.Turnover100) 
		,	[SumWL]			= SUM(cs.Winloss100)
		,	[Margin]		= SUM(cs.Winloss100) / CASE WHEN SUM(cs.Turnover100) = 0 THEN 1 ELSE SUM(cs.Turnover100) END * 100
	FROM	#CustomerStatistic AS cs WITH (NOLOCK)
	GROUP BY CASE WHEN cs.islive = 1 THEN 'Live' ELSE 'Non-Live' END;

	SELECT	TOP(5)
			[SportName]		= sp.Sportname
		,	[SumTO]			= SUM(cs.Turnover100)
		,	[SumWL]			= SUM(cs.Winloss100)
		,	[Margin]		= SUM(cs.Winloss100) / CASE WHEN SUM(cs.Turnover100) = 0 THEN 1 ELSE SUM(cs.Turnover100) END * 100
	FROM		#CustomerStatistic AS cs WITH (NOLOCK)
	INNER JOIN	bodb02.dbo.league AS l WITH (NOLOCK)
			ON	cs.leagueid = l.leagueid
	INNER JOIN	bodb02.dbo.sports AS sp WITH (NOLOCK)
			ON	l.SportType = sp.SportType
	GROUP BY sp.SportName	
	ORDER BY Margin DESC;

	SELECT	TOP(5)
			[BettypeName]	= bt.typenamee
		,	[Bettype]		= cs.Bettype
		,	[SumTO]			= SUM(cs.Turnover100)
		,	[SumWL]			= SUM(cs.Winloss100)
		,	[Margin]		= SUM(cs.Winloss100) / CASE WHEN SUM(cs.Turnover100) = 0 THEN 1 ELSE SUM(cs.Turnover100) END * 100
	FROM		#CustomerStatistic AS cs WITH (NOLOCK)
	LEFT JOIN	DBWH.bodb_Account.dbo.Bettype bt WITH (NOLOCK)
			ON	cs.bettype = bt.typeid
	GROUP BY bt.typenamee, cs.Bettype
	ORDER BY Margin DESC;

	DROP TABLE	#CustomerStatistic;
	DROP TABLE	#WinlostDate;
END

GO
/*<info serverAlias="DBSPU-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
