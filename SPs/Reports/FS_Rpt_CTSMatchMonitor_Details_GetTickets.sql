
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER PROCEDURE [dbo].[FS_Rpt_CTSMatchMonitor_Details_GetTickets]
		@MatchId					INT
	,	@FraudCaseId				INT	
	,	@SiteId						INT = 0
	,	@BettypeId					SMALLINT = 0
	,	@CurrencyId					TINYINT = 0
	,	@StakeFrom					MONEY = 0
	,	@StakeTo					MONEY = 0
AS
/*
	Created: 20200520@Long.Luu
	Task : Match Monitor Details report for CTS - Get Tickets
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20200520@Long.Luu: Created [Redmine ID: #133798]
*/
BEGIN
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#tmpFraudTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTickets;
	END;
	
	CREATE TABLE #tmpFraudTickets (
			TransID		BIGINT PRIMARY KEY
	);

	IF OBJECT_ID('tempdb..#tmpCustomerSite') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomerSite;
	END;
	
	CREATE TABLE #tmpCustomerSite (
			CustId		BIGINT PRIMARY KEY
		,	SiteId		INT
		,	SiteName	NVARCHAR(50)
	 );

	 IF OBJECT_ID('tempdb..#tmpMatchInfo') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatchInfo;
	END;
	
	CREATE TABLE #tmpMatchInfo (
			MatchId				INT PRIMARY KEY
		,	LiveHomeScore		INT
		,	LiveAwayScore		INT
		,	SecondHalf75thMin	DATETIME
	 );
	
	-- START
	-- Get match info
	INSERT INTO #tmpMatchInfo(MatchId, LiveHomeScore, LiveAwayScore, SecondHalf75thMin)
	SELECT	m.matchid
		,	m.livehomescore
		,	m.liveawayscore
		,	MAX(CASE WHEN s.MatchId IS NULL THEN '9999-12-31' ELSE DATEADD(MINUTE, 30, s.CreateTime ) END)
	FROM bodb02.dbo.match AS m WITH(NOLOCK)
		LEFT JOIN DBPRO.bodb02.dbo.Match_ExtraStatus AS s WITH(NOLOCK) ON m.matchid = s.MatchId AND s.GameStatusID = 3
	WHERE m.matchid = @MatchId
	GROUP BY m.matchid
		,	m.livehomescore
		,	m.liveawayscore;

	-- Get suspicious customers
	INSERT INTO #tmpCustomerSite(CustId)
	SELECT DISTINCT si.CustId
	FROM dbo.SuspiciousInfo AS si WITH(NOLOCK)
		INNER JOIN dbo.SuspiciousCustomer AS c WITH(NOLOCK) ON si.Custid = c.custid
	WHERE si.MatchId = @MatchId
		AND si.FraudCaseId = @FraudCaseId
		AND (c.CurrencyId NOT IN (SELECT CurrencyId FROM dbo.SpecialCurrency WITH(NOLOCK)));

	-- Get Site Info
	UPDATE c WITH(ROWLOCK, UPDLOCK)
	SET c.SiteName = t.SiteName, c.SiteId = t.SiteId
	FROM #tmpCustomerSite AS c
		INNER JOIN (
			SELECT cust.custid AS CustId
				,	CASE WHEN cust.roleid = 1 THEN st.siteid ELSE st2.siteid END AS SiteId
				,	CASE WHEN cust.roleid = 1 THEN upl.site ELSE cust.site END AS SiteName
			FROM bodb02.dbo.Customer AS cust WITH (NOLOCK)
				INNER JOIN #tmpCustomerSite AS t ON cust.custid = t.CustId
				LEFT JOIN bodb02.dbo.Customer AS upl WITH (NOLOCK) ON cust.recommend = upl.custid
				LEFT JOIN bodb02.dbo.Site AS st WITH (NOLOCK) ON upl.site = st.site
				LEFT JOIN bodb02.dbo.Site AS st2 WITH (NOLOCK) ON cust.site = st2.site
			WHERE cust.roleid BETWEEN 1 AND 4
		) AS t ON c.CustId = t.CustId;
	

	-- Get all fraud tickets
	INSERT INTO #tmpFraudTickets(TransID)
	SELECT VAL
	FROM dbo.SuspiciousInfo AS si WITH(NOLOCK)
		INNER JOIN dbo.SuspiciousCustomer AS c WITH(NOLOCK) ON si.Custid = c.custid
		CROSS APPLY dbo.SPU_StrSplit(si.transids, ',')
	WHERE si.MatchId = @MatchId
		AND si.FraudCaseId = @FraudCaseId
		AND (c.CurrencyId NOT IN (SELECT CurrencyId FROM dbo.SpecialCurrency WITH(NOLOCK)));
			
	--===	2.2 GET: Homeid and AwayId
	DECLARE @homeId INT;
	DECLARE @awayId INT;
			
	SELECT	@homeId = m.homeid
		,	@awayId = m.awayid
	FROM bodb02.dbo.match m WITH(NOLOCK)
	WHERE m.matchid = @MatchId;
			
	SELECT	b.Username			AS Username
		,	s.SiteId			AS SiteId
		,	s.SiteName			AS SiteName
		,	b.bettype			AS BettypeId
		,	bt.typenamee		AS BettypeName
		,	b.Transid			AS TransId
		,	b.transdate			AS TransDate
		,	b.betteam			AS BetTeam
		,	b.hdp1				AS Handicap1
		,	b.hdp2				AS Handicap2
		,	ISNULL(b.livehomescore,0) AS LiveHomeScore
		,	ISNULL(b.liveawayscore,0) AS LiveAwayScore
		,	b.liveindicator		AS LiveIndicator
		,	b.odds				AS Odds
		,	b.oddstype			AS OddsType
		,	b.stake				AS Stake
		,	(CASE WHEN b.statusID IN (111,112,113) THEN (b.winlost - b.actual_stake )
				ELSE 0
				END) AS Winlost
		,	b.status AS TicketStatus
		,	b.statusID AS TicketStatusId
		,	ISNULL(b.IP,'')		AS [IP]
		,	b.currency			AS CurrencyId
		,	b.currencyname		AS CurrencyName
		,	CASE WHEN (b.transdate > m.SecondHalf75thMin) THEN 2 -- Ticket bet after 75th minute
				WHEN (b.livehomescore <> m.livehomescore OR b.liveawayscore <> m.liveawayscore) THEN 1 -- Different goal score
				ELSE 0 END AS HighlightStatus -- Normal case
	FROM bodb02.dbo.bettrans AS b WITH(NOLOCK)
		INNER JOIN #tmpFraudTickets AS f WITH(NOLOCK) ON b.transid = f.TransID
		INNER JOIN bodb02.dbo.bettype AS bt WITH(NOLOCK) ON b.bettype = bt.typeid
		INNER JOIN #tmpCustomerSite AS s WITH(NOLOCK) ON b.custid = s.CustId
		INNER JOIN #tmpMatchInfo as m WITH(NOLOCK) ON b.matchid = m.matchid
	WHERE (@SiteId = 0 OR s.SiteId = @SiteId)
		AND (@CurrencyId = 0 OR b.currency = @CurrencyId)
		AND (@BettypeId = 0 OR b.bettype = @BettypeId)
		AND (@StakeTo = 0 OR (b.stake >= @StakeFrom AND b.stake <= @StakeTo));
END;

GO
GRANT EXECUTE ON [dbo].[FS_Rpt_CTSMatchMonitor_Details_GetTickets] TO [bodbSPUNet];
GO
GRANT VIEW DEFINITION ON [dbo].[FS_Rpt_CTSMatchMonitor_Details_GetTickets] TO [bodbSPUNet];
GO

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/