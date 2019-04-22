ALTER PROCEDURE [dbo].[FS_FraudCase_Arbitrage_PreCondition]
AS
/*
	Created: 20180815@LONG
	Task : PreCondition for Arbitrage fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions: 
		- 20180815@LONG: Implement PreCondition for Arbitrage fraud case
		- 20180926@LONG: Remove redundant fraud tickets
		- 20190312@Casey.Huynh: Enhance Performance, define PRIMARY KEY in table [110060]
		- 20190314@Casey.Huynh: Implement, scan for completed Match [110566]
		- 20190408@Casey.Huynh: Update "Rowlock" to "Nolock" for table ArbitrageMatchScanning, Insert to ArbitrageMatchScoreHDP handicap=hdp1-hdp2 [111069]		
		- 20190403@Long.Luu: Adding LiveHomeScore, LiveAwayScore for ArbitrageTicketDetails table [Redmine ID: 111069]

	Param's Explanation (filtered by):  
	
*/
BEGIN
	SET NOCOUNT ON;	

	-- INIT
	DECLARE @CurrentTime DATETIME;
	
	SET @CurrentTime = GETDATE();

	IF OBJECT_ID('tempdb..#tmpCustomerList') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomerList;
	END

	CREATE TABLE #tmpCustomerList
	(
			MatchId				INT	NOT	NULL
		,   LiveHomeScore		INT	NOT	NULL
		,	LiveAwayScore		INT	NOT	NULL
		,	Bettype				INT	NOT	NULL
		,	Handicap			SMALLMONEY NOT	NULL		
		,	CustId				INT	NOT	NULL
		,	PRIMARY KEY CLUSTERED (
			MatchId			ASC
			, LiveHomeScore	ASC
			, LiveAwayScore	ASC
			, Bettype		ASC
			, Handicap		ASC			
			, CustId		ASC
			)
	);	

	IF OBJECT_ID('tempdb..#tmpCompletedMatch') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCompletedMatch;
	END

	CREATE TABLE #tmpCompletedMatch
	(
			MatchId	INT	NOT	NULL PRIMARY KEY CLUSTERED
	);	
	--======UPDATE Match Complete Status
	UPDATE		ams
	SET			ams.IsMatchCompleted = 1, ams.CapturedDate = @CurrentTime
	FROM		dbo.ArbitrageMatchScanning	ams WITH(ROWLOCK)
	INNER JOIN	bodb02.dbo.match m WITH(NOLOCK)
				ON	ams.MatchId = m.matchid
	WHERE		m.eventstatus = 'Completed'
				AND ams.IsMatchCompleted = 0;

	--==INSERT:	NEW MATCH
	INSERT INTO dbo.ArbitrageMatchScanning(MatchId, IsMatchCompleted, IsScanCompleted, CapturedDate)
	SELECT		m.Matchid
				, (CASE WHEN m.eventstatus = 'Completed' THEN 1 ELSE 0 END) AS IsMatchCompleted
				, 0 AS IsScanCompleted
				, @CurrentTime AS CapturedDate				
	FROM		bodb02.dbo.League l WITH(NOLOCK)
	INNER JOIN	bodb02.dbo.match m WITH(NOLOCK)
				ON l.leagueid = m.leagueid
	LEFT JOIN	dbo.ArbitrageMatchScanning a WITH(NOLOCK)
				ON a.MatchId = m.matchid
	WHERE		m.sporttype	= 1
				AND (m.eventstatus = 'Running' OR m.eventstatus = 'Completed')
				AND m.MatchCode	NOT LIKE '%hedge%'
				AND m.kickofftime <= @CurrentTime	
				AND l.isTest = 0
				AND a.MatchId IS NULL;

	--==2. INSERT:	Customer List that has not scanned completed
	INSERT INTO #tmpCustomerList(MatchId, LiveHomeScore, LiveAwayScore, Bettype, Handicap, CustId)
	SELECT		b.MatchId
				, b.LiveHomeScore
				, b.LiveAwayScore
				, b.Bettype
				, b.hdp1 - b.hdp2 AS Handicap				
				, b.CustId
	FROM		bodb02.dbo.bettrans b WITH(NOLOCK)
	INNER JOIN	dbo.ArbitrageMatchScanning m WITH(NOLOCK)
				ON	b.matchid = m.matchid
	LEFT JOIN	dbo.ArbitrageMatchScoreHDP sh WITH(NOLOCK)
				ON	b.matchid = sh.MatchId
				AND b.livehomescore = sh.LiveHomeScore
				AND b.liveawayscore = sh.LiveAwayScore
				AND b.bettype = sh.BetType
				AND b.hdp1 - b.hdp2 = sh.Handicap
				AND sh.HasScanned = 1
	WHERE		m.IsScanCompleted = 0  --Match not yet Scanned Completed							
				AND b.bettype IN (1, 3, 7, 8)
				AND b.Currency NOT IN (20, 27, 28)
				AND	sh.MatchId IS NULL -- HDC IS NOT SCANNED				
	GROUP BY	b.MatchId, b.livehomescore, b.liveawayscore, b.betType, b.hdp1, b.hdp2, b.CustId;

	--==3. UPDATE: COMPLETED MATCHED IF MATCH.EVENTSTATUS IS COMPLETED AND ALL BETTYPE (1,3,5,7,8) IS SCANNED

	UPDATE		sh
	SET			sh.HasScanned = 1, sh.UpdatedDate = @CurrentTime
	FROM		dbo.ArbitrageMatchScoreHDP sh WITH(ROWLOCK)
	INNER JOIN	dbo.ArbitrageMatchScanning m WITH(NOLOCK)
				ON sh.MatchId = m.MatchId
	LEFT JOIN	(	SELECT	DISTINCT MatchId
					FROM	#tmpCustomerList c	WITH(NOLOCK)
				) sm 
				ON	m.MatchId = sm.MatchId
	WHERE		m.IsMatchCompleted = 1
				AND m.IsScanCompleted = 0
				AND sm.MatchId IS NULL
				AND	sh.HasScanned = 0;	
	
	UPDATE		ams
	SET			ams.IsScanCompleted = 1, ams.CapturedDate = @CurrentTime
	FROM		dbo.ArbitrageMatchScanning ams WITH(ROWLOCK)
	LEFT JOIN	(	SELECT	DISTINCT MatchId
					FROM	#tmpCustomerList c	WITH(NOLOCK)
				) sm 
				ON	ams.MatchId = sm.MatchId
	WHERE		ams.IsMatchCompleted = 1
				AND ams.IsScanCompleted = 0
				AND sm.MatchId IS NULL;
					
	--==4. RETURN Scanning GROUP BY (MATCH, LiveHomeScore, LiveAwayScore, Bettype, Handicap, CustId)
	SELECT		MatchId
				, LiveHomeScore
				, LiveAwayScore
				, Bettype
				, Handicap
				, CustId
	FROM		#tmpCustomerList c WITH(NOLOCK);
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/	