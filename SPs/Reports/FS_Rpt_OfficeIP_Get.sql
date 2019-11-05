
ALTER PROCEDURE [dbo].[FS_Rpt_OfficeIP_Get]
		@FromDate					DATETIME
	,	@ToDate						DATETIME 
	,	@IsShowSpecialCurrencies	BIT = 0
AS
/*
	Created:	20180605@Casey.Huynh
	Task:		Get Office IP Report
	Server:		

	Revisions:
		- 20181114@Long.Luu: Adding View Permission on Special Currencies [Redmine ID: #104707]
		- 20190219@John.Ngo: Update logic Special Currencies [Redmine ID: #99753]
		- 20191025@Long.Luu: Support Office IP for Login transaction [Redmine ID: #121800]

	Param's Explanation: 
	
	Sample: 
		Exec FS_Rpt_OfficeIP_Get @FromDate = '2018-05-01' , @ToDate = '2018-06-06' 	
*/

BEGIN

	SET NOCOUNT ON;
	
	DECLARE @FraudCaseId		INT = 2;
	DECLARE @LastTimeOfToDate	DATETIME = DATEADD(ss, -1, DATEADD(dd, 1, @ToDate));
	
	IF OBJECT_ID('tempdb..#tmpTicketDetails') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpTicketDetails;
	END;
	CREATE TABLE #tmpTicketDetails(
			Username		NVARCHAR(50)
		,	TransDate		DATETIME		
		,	TransId			BIGINT		
		,	LeagueId		NVARCHAR(1000)
		,	HomeId			INT
		,	AwayId			INT
		,	BetTypeId		INT
		,	LiveHomeScore	SMALLINT
		,	LiveAwayScore	SMALLINT
		,	Handicap1		SMALLMONEY
		,	Handicap2		SMALLMONEY
		,	BetTeam			NVARCHAR(10)
		,	IsLive			BIT
		,	Odds			SMALLMONEY
		,	OddsType		TINYINT
		,	Stake			MONEY
		,	WinLost			MONEY
		,	Status			NVARCHAR(10)
		,	IP				NVARCHAR(15)
		,	CurrencyName	NVARCHAR(20)
	);
	
	--===	1.2 INITIAL: TEMP TABLES #tmpFraudTickets: GET Fraud Tickets
	IF OBJECT_ID('tempdb..#tmpFraudTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTickets;
	END;
	
	CREATE TABLE #tmpFraudTickets (
			TransID	BIGINT
	 );
	
	--===	2.2 GET: Fraud Tickets Insert to #tmpFraudTickets	
	--INSERT INTO #tmpFraudTickets(TransId)

	INSERT INTO	#tmpFraudTickets(TransID)
	SELECT	VAL
	FROM	dbo.SuspiciousInfo si WITH(NOLOCK)
		INNER JOIN dbo.SuspiciousCustomer c WITH(NOLOCK) ON si.Custid = c.custid
		CROSS APPLY dbo.SPU_StrSplit(si.transids, ',')
	WHERE	si.FraudCaseId = @FraudCaseId
		AND DATEADD(dd, 0, DATEDIFF(dd, 0, si.SuspiciousDate)) BETWEEN @FromDate AND @LastTimeOfToDate
		AND (@IsShowSpecialCurrencies = 1 OR c.CurrencyId NOT IN (SELECT CurrencyId FROM dbo.SpecialCurrency WITH(NOLOCK)));
	
	
	DECLARE @TotalFraudTickets INT;	
	SELECT 	@TotalFraudTickets = (SELECT COUNT(1) FROM  #tmpFraudTickets WITH(NOLOCK));
		
	IF (@TotalFraudTickets > 0)
	BEGIN			
		INSERT #tmpTicketDetails (Username,  TransId, TransDate,LeagueId,HomeId, AwayId, BetTypeId, BetTeam,  Handicap1, Handicap2, LiveHomeScore, LiveAwayScore, 
								IsLive, Odds, OddsType, Stake, WinLost, Status, IP, CurrencyName)
		SELECT b.Username
		,	b.Transid
		,	b.transdate
		,	l.LeagueId
		,	m.HomeId
		,	m.AwayId
		,	b.bettype		
		,	b.betteam
		,	b.hdp1
		,	b.hdp2
		,	ISNULL(b.livehomescore,0)
		,	ISNULL(b.liveawayscore,0)
		,	b.liveindicator [isLive]
		,	b.odds
		,	b.oddstype
		,	b.stake
		,	(CASE WHEN b.statusID IN (111,112,113) THEN (b.winlost-b.actual_stake )
				ELSE 0
				END) [Winlost]
		,	b.status
		,	ISNULL(b.IP,'') 
		,	b.currencyname
		FROM	#tmpFraudTickets ft  WITH(NOLOCK)
				INNER JOIN bodb02.dbo.bettrans b WITH (NOLOCK) ON ft.TransID = b.transid
				INNER JOIN bodb02.dbo.Match	m WITH(NOLOCK) ON b.MatchID = m.matchid
				INNER JOIN bodb02.dbo.League l WITH (NOLOCK) ON m.leagueid=l.leagueid;
	END;
	
	DECLARE @TotalTickets INT;
	SELECT @TotalTickets = (SELECT COUNT(1) FROM #tmpTicketDetails WITH (NOLOCK));
	
	IF (@TotalTickets < @TotalFraudTickets)
	BEGIN			
		INSERT #tmpTicketDetails (Username,  TransId, TransDate,LeagueId,HomeId, AwayId, BetTypeId, BetTeam,  Handicap1, Handicap2, LiveHomeScore, LiveAwayScore, 
								IsLive, Odds, OddsType, Stake, WinLost, Status, IP, CurrencyName)
		SELECT b.Username
		,	b.Transid
		,	b.transdate
		,	l.LeagueId
		,	m.HomeId
		,	m.AwayId
		,	b.bettype		
		,	b.betteam
		,	b.hdp1
		,	b.hdp2
		,	ISNULL(b.livehomescore,0)
		,	ISNULL(b.liveawayscore,0)
		,	b.liveindicator [isLive]
		,	b.odds
		,	b.oddstype
		,	b.stake
		,	(CASE WHEN b.statusID IN (111,112,113) THEN (b.winlost-b.actual_stake )
				ELSE 0
				END) [Winlost]
		,	b.status
		,	ISNULL(b.IP,'') 
		,	b.currencyname
		FROM	#tmpFraudTickets ft  WITH(NOLOCK)
				INNER JOIN bodb02.dbo.bettrans14 b WITH (NOLOCK) ON ft.TransID = b.transid
				INNER JOIN bodb02.dbo.Match14	m WITH(NOLOCK) ON b.MatchID = m.matchid
				INNER JOIN bodb02.dbo.League l WITH (NOLOCK) ON m.leagueid=l.leagueid;
	END;
	
	---RETURN FRAUD TICKETS TABLE
	SELECT	td.Username
		,	td.Transid
		,	td.transdate
		,	td.LeagueId
		,	td.HomeId
		,	td.AwayId
		,	td.BetTypeId		
		,	td.betteam
		,	td.Handicap1
		,	td.Handicap1
		,	td.LiveHomeScore
		,	td.LiveAwayScore
		,	td.IsLive
		,	td.odds
		,	td.oddstype
		,	td.stake
		,	td.WinLost
		,	td.status
		,	td.IP
		,	td.currencyname
	FROM	#tmpTicketDetails td WITH(NOLOCK)
	UNION
	SELECT	sc.Username
		,	NULL
		,	li.TransDate
		,	NULL
		,	NULL
		,	NULL
		,	NULL
		,	NULL
		,	NULL
		,	NULL
		,	NULL
		,	NULL
		,	NULL
		,	NULL
		,	NULL
		,	NULL
		,	NULL
		,	NULL
		,	li.IP
		,	ex.currency
	FROM dbo.[OfficeIPLogIn] AS li WITH(NOLOCK)
		INNER JOIN dbo.[SuspiciousCustomer] AS sc WITH(NOLOCK) ON li.CustId = sc.Custid
		INNER JOIN bodb02.dbo.[Exchange] AS ex WITH(NOLOCK) ON sc.CurrencyId = ex.exchangeid
	WHERE li.TransDate BETWEEN @FromDate AND @LastTimeOfToDate
		AND sc.CurrencyId NOT IN (20, 27, 28)
	ORDER BY Username, TransId;	
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/