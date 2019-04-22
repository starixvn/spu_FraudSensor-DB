SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[FS_FraudCase_Arbitrage_Rule] 
		@Matches			VARCHAR(MAX) = NULL -- xml format
	,	@Associations		VARCHAR(MAX) = NULL -- xml format
AS
/*
	Created: 20180816@Long
	Task : Rule for Arbitrage fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20180815@LONG: Implement Rule for Arbitrage fraud case
		- 20180924@LONG: Remove the XML Documents after usage
		- 20180926@LONG: Remove redundant fraud tickets [Redmine ID: 99753]
		- 20180926@LONG: Fix issue of livehomescore [Redmine ID: 000000]
		- 20180926@LONG: Performance tunning [Redmine ID: 000000]

	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	

	-- ARRANGE
	DECLARE @CurrentFraudCaseId		TINYINT
		,	@MaxStakeToBeChecked	MONEY;
	SET		@CurrentFraudCaseId		= 10; -- Arbitrage
	SET		@MaxStakeToBeChecked	= 500;
	
	DECLARE @ScannedDate		DATETIME;
	SET	@ScannedDate			= GETDATE();
	
	IF OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatches;
	END

	CREATE TABLE #tmpMatches
	(
			MatchId				INT
		,	CustId				INT
		,	BetType				INT
		,	Handicap			MONEY
		,	LiveHomeScore		INT
		,	LiveAwayScore		INT
	);

	CREATE CLUSTERED INDEX	#CIX_tmpMatches ON #tmpMatches (
			MatchId				ASC
		,	BetType				ASC
		,	CustId				ASC
		,	LiveHomeScore		ASC
		,	LiveAwayScore		ASC
	);

	CREATE NONCLUSTERED INDEX	#NCIX_tmpMatches_MatchId ON #tmpMatches (
			MatchId				ASC
	);

	IF OBJECT_ID('tempdb..#tmpMaxTransId') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMaxTransId;
	END

	CREATE TABLE #tmpMaxTransId
	(
			MatchId				INT
		,	BetType				INT
		,	Handicap			MONEY
		,	TotalScores			INT
		,	MaxTransId			BIGINT
	);

	CREATE NONCLUSTERED INDEX	#NCIX_tmpMaxTransId ON #tmpMaxTransId (
			MatchId				ASC
		,	BetType				ASC
		,	Handicap			ASC
		,	TotalScores			ASC
	);

	IF	OBJECT_ID('tempdb..#tmpAssociation') IS NOT NULL
	BEGIN;
		DROP TABLE #tmpAssociation;
	END;

	CREATE TABLE	#tmpAssociation (
			[CustId]			INT NOT NULL PRIMARY KEY
		,	[GroupId]			INT NOT NULL
	);

	CREATE NONCLUSTERED INDEX	#NCIX_tmpAssociation_GroupID ON #tmpAssociation (
			[GroupId]			ASC
	);

	IF OBJECT_ID('tempdb..#tmpBettrans') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpBettrans;
	END

	CREATE TABLE #tmpBettrans
	(
			CustId				INT
		,	TransId				BIGINT
		,	MatchId				INT
		,	Bettype				INT
		,	TotalLiveScore		INT
		,	Betteam				NVARCHAR(50)
		,	Handicap			SMALLMONEY
		,	Stake				MONEY
		,	EventDate			DATETIME
	);

	CREATE NONCLUSTERED INDEX	#NCIX_tmpBettrans ON #tmpBettrans (
			MatchId				ASC
		,	Bettype				ASC
		,	TotalLiveScore		ASC
		,	Betteam				ASC
		,	Handicap			ASC
	);

	IF OBJECT_ID('tempdb..#tmpArbitrageGroups') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpArbitrageGroups;
	END

	CREATE TABLE #tmpArbitrageGroups
	(
			MatchId				INT PRIMARY KEY
		,	GroupId				INT
	);

	CREATE NONCLUSTERED INDEX	#NCIX_tmpArbitrageGroups_GroupID ON #tmpArbitrageGroups (
			[GroupId]			ASC
	);

	IF OBJECT_ID('tempdb..#tmpFraudTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTickets;
	END
	
	CREATE TABLE #tmpFraudTickets(
			CustId				INT
		,	MatchId				INT
		,	GroupId				INT
		,	Bettype				INT
		,	EventDate			DATETIME
		,	TransId				BIGINT
		,	TotalLiveScore		INT
		,	Handicap			SMALLMONEY
	);

	CREATE CLUSTERED INDEX	#CIX_tmpFraudTicketsIdx ON #tmpFraudTickets (
			MatchId				ASC
		,	Bettype				ASC
		,	Handicap			ASC
		,	TotalLiveScore		ASC
		,	CustId				ASC
		,	GroupId				ASC
	);

	CREATE NONCLUSTERED INDEX	#NCIX_tmpFraudTicketsIdx ON #tmpFraudTickets (
			MatchId				ASC
		,	CustId				ASC
	);

	IF OBJECT_ID('tempdb..#tmpMatchBettypeBetteamSumStake') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatchBettypeBetteamSumStake;
	END
	
	CREATE TABLE #tmpMatchBettypeBetteamSumStake(
			GroupId				INT
		,	MatchId				INT
		,	Bettype				INT
		,	Handicap			SMALLMONEY
		,	TotalLiveScore		INT
		,	TotalStakeH			MONEY
		,	TotalStakeA			MONEY
	);

	CREATE CLUSTERED INDEX	#CIX_tmpMatchBettypeBetteamSumStakeIdx ON #tmpMatchBettypeBetteamSumStake (
			GroupId				ASC
		,	MatchId				ASC
		,	Bettype				ASC
		,	Handicap			ASC
		,	TotalLiveScore		ASC
	);

	-- INIT	
	DECLARE @idocMatch INT
		,	@idocAssociation INT;

	--Create an internal representation of the XML document
	EXEC sp_xml_preparedocument @idocMatch OUTPUT, @Matches;
	EXEC sp_xml_preparedocument @idocAssociation OUTPUT, @Associations;

	-- Execute a SELECT statement that uses the OPENXML rowset provider
	INSERT INTO #tmpMatches (MatchId, CustId, BetType, Handicap, LiveHomeScore, LiveAwayScore)
	SELECT	Data.MatchId
		,	Data.CustId
		,	Data.BetType
		,	Data.Handicap
		,	Data.LiveHomeScore
		,	Data.LiveAwayScore
	FROM OPENXML(@idocMatch, '/Root/Match', 2) WITH (
			MatchId INT '@MatchId'
		,	BetType INT	'@BetType'
		,	CustId INT '@CustId'
		,	Handicap MONEY '@Handicap'
		,	LiveHomeScore INT '@LiveHomeScore'
		,	LiveAwayScore INT '@LiveAwayScore'
	) AS Data;

	-- Execute a SELECT statement that uses the OPENXML rowset provider
	INSERT INTO #tmpAssociation (CustId, GroupId)
	SELECT	Data.CustId
		,	Data.GroupId
	FROM OPENXML(@idocAssociation, '/Root/Association', 2) WITH (
			CustId INT '@CustId'	
		,	GroupId INT '@GroupId'
	) AS Data;

	-- START
	INSERT INTO #tmpBettrans(CustId, MatchId, TransId, Bettype, TotalLiveScore, Betteam, Handicap, Stake, EventDate)
	SELECT	[CustId]			= b.custid
		,	[MatchId]			= b.matchid
		,	[TransId]			= b.transid
		,	[Bettype]			= b.bettype
		,	[TotalLiveScore]	= (b.livehomescore + b.liveawayscore)
		,	[Betteam]			= b.betteam
		,	[Handicap]			= (b.hdp1 - b.hdp2)
		,	[stake]				= (b.stake * b.actualrate)
		,	[EventDate]			= b.winlostdate	
	FROM bodb02.dbo.bettrans AS b WITH(NOLOCK)
		INNER JOIN #tmpMatches AS m WITH(NOLOCK) ON b.matchid = m.MatchId AND b.bettype = m.BetType
			AND b.custid = m.CustId AND (b.hdp1 - b.hdp2) = m.Handicap AND b.livehomescore = m.LiveHomeScore AND b.liveawayscore = m.LiveAwayScore
	WHERE b.matchId > 0
		AND b.bettype IN (1, 3, 7, 8)
		AND b.Currency NOT IN (20, 27, 28);

	INSERT INTO #tmpMatchBettypeBetteamSumStake(GroupId, MatchId, Bettype, Handicap, TotalLiveScore, TotalStakeH, TotalStakeA)
	SELECT DISTINCT a.GroupId
		,	b.MatchId
		,	b.Bettype
		,	b.Handicap
		,	b.TotalLiveScore
		,	SumH.TotalStakeH
		,	SumA.TotalStakeA
	FROM #tmpBettrans AS b WITH(NOLOCK)
		INNER JOIN #tmpAssociation AS a WITH(NOLOCK) ON b.CustId = a.CustId
		CROSS APPLY(
			SELECT SUM(bb.Stake) AS TotalStakeH
			FROM #tmpBettrans AS bb WITH(NOLOCK)
				INNER JOIN #tmpAssociation AS aa WITH(NOLOCK) ON bb.CustId = aa.CustId
			WHERE bb.MatchId = b.MatchId AND bb.Bettype = b.Bettype AND bb.Handicap = b.Handicap
				AND bb.TotalLiveScore = b.TotalLiveScore AND aa.GroupId = a.GroupId AND bb.Betteam = 'h'
			GROUP BY bb.MatchId, bb.Bettype, bb.TotalLiveScore, bb.Handicap
		) AS SumH
		CROSS APPLY(
			SELECT SUM(bb.Stake) AS TotalStakeA
			FROM #tmpBettrans AS bb WITH(NOLOCK)
				INNER JOIN #tmpAssociation AS aa WITH(NOLOCK) ON bb.CustId = aa.CustId
			WHERE bb.MatchId = b.MatchId AND bb.Bettype = b.Bettype AND bb.Handicap = b.Handicap
				AND bb.TotalLiveScore = b.TotalLiveScore AND aa.GroupId = a.GroupId AND bb.Betteam = 'a'
			GROUP BY bb.MatchId, bb.Bettype, bb.TotalLiveScore, bb.Handicap
		) AS SumA
	GROUP BY a.GroupId, b.MatchId, b.Bettype, b.TotalLiveScore, b.Handicap,	SumH.TotalStakeH, SumA.TotalStakeA
	HAVING COUNT(DISTINCT b.Betteam) > 1;

	-- Get fraud tickets
	INSERT INTO #tmpFraudTickets (CustId, MatchId, GroupId, Bettype, EventDate, TransId, TotalLiveScore, Handicap)
	SELECT  [CustId]			= bb.CustId
		,	[MatchId]			= r.matchid
		,	[GroupId]			= r.GroupId
		,	[Bettype]			= bb.Bettype
		,	[EventDate]			= bb.EventDate
		,	[TransId]			= bb.TransId
		,	[TotalLiveScore]	= r.TotalLiveScore
		,	[Handicap]			= r.Handicap
	FROM #tmpMatchBettypeBetteamSumStake AS r WITH(NOLOCK)
		INNER JOIN #tmpAssociation AS a WITH(NOLOCK) ON r.GroupId = a.GroupId
		INNER JOIN #tmpBettrans AS bb WITH(NOLOCK) ON a.CustId = bb.CustId AND r.MatchId = bb.MatchId
			AND r.Bettype = bb.Bettype AND r.Handicap = bb.Handicap AND r.TotalLiveScore = bb.TotalLiveScore
	WHERE r.TotalStakeH > @MaxStakeToBeChecked AND r.TotalStakeA > @MaxStakeToBeChecked;

	-- Check the results and store/return data
	IF EXISTS (SELECT TOP(1) 1 FROM #tmpFraudTickets WITH (NOLOCK))
	BEGIN		
		DELETE si
		FROM dbo.ArbitrageTicketDetails si WITH(ROWLOCK)
			INNER JOIN #tmpFraudTickets ft WITH(NOLOCK) ON si.MatchId = ft.MatchId AND si.BetType = ft.BetType
				 AND si.Handicap = ft.Handicap AND si.TotalScores = ft.TotalLiveScore AND si.CustId = ft.CustId;

		-- Insert new records for table ArbitrageTicketDetails
		INSERT INTO dbo.ArbitrageTicketDetails(CustId, MatchId, GroupId, BetType, Handicap, TotalScores, TransIds, TicketCounter)
		SELECT	[CustId]			= ft.CustId
			,	[MatchId]			= ft.MatchId
			,	[GroupId]			= ft.GroupId
			,	[Bettype]			= ft.Bettype
			,	[Handicap]			= ft.Handicap
			,	[TotalScores]		= ft.TotalLiveScore
			,	[TransIds]			= STUFF((SELECT ',', CONVERT(VARCHAR(15), t1.TransId) 
											FROM #tmpFraudTickets AS t1 WITH(NOLOCK)
											WHERE t1.MatchId = ft.MatchId AND t1.BetType = ft.BetType AND t1.Handicap = ft.Handicap 
												AND t1.TotalLiveScore = ft.TotalLiveScore AND t1.CustId = ft.CustId AND t1.GroupId = ft.GroupId												
											FOR XML PATH('')), 1, 1, '')
			,	[TicketCounter]		= (SELECT COUNT(t2.TransId) 
										FROM #tmpFraudTickets t2 WITH (NOLOCK)
										WHERE t2.MatchId = ft.MatchId AND t2.BetType = ft.BetType AND t2.Handicap = ft.Handicap 
												AND t2.TotalLiveScore = ft.TotalLiveScore AND t2.CustId = ft.CustId AND t2.GroupId = ft.GroupId)
		FROM #tmpFraudTickets ft WITH (NOLOCK)
				LEFT JOIN dbo.ArbitrageTicketDetails si WITH (NOLOCK) 
					ON si.MatchId = ft.MatchId AND si.BetType = ft.BetType AND si.Handicap = ft.Handicap 
					AND si.TotalScores = ft.TotalLiveScore AND si.CustId = ft.CustId AND  si.GroupId = ft.GroupId					
		WHERE si.CustId IS NULL AND si.MatchID IS NULL AND si.GroupId IS NULL
		GROUP BY ft.CustId, ft.MatchId, ft.GroupId, ft.Bettype, ft.Handicap, ft.TotalLiveScore;		

		-- Update table SuspiciousInfo if existed
		UPDATE si WITH (ROWLOCK, UPDLOCK)
		SET		si.SuspiciousDate	=	GETDATE()
			,	si.TransIds			=	STUFF((SELECT DISTINCT ',', CONVERT(VARCHAR(MAX), t1.TransIds) 
										FROM dbo.ArbitrageTicketDetails t1 WITH (NOLOCK)
										WHERE t1.MatchId = ft.MatchId AND t1.CustId = ft.CustId
										FOR XML PATH('')), 1, 1, '')
			,	si.TicketCounter	=	(SELECT SUM(t2.TicketCounter) 
										FROM dbo.ArbitrageTicketDetails t2 WITH (NOLOCK)
										WHERE t2.MatchId = ft.MatchId AND t2.CustId = ft.CustId)
			,	si.IsVerified		=	0
			,	si.ViolationCounter =	(SELECT COUNT(1)
										FROM (SELECT DISTINCT t2.Bettype, t2.TotalScores, t2.Handicap
										FROM dbo.ArbitrageTicketDetails AS t2 WITH (NOLOCK)
										WHERE t2.MatchId = ft.MatchId AND t2.CustId = ft.CustId) AS A)
		FROM dbo.SuspiciousInfo si
				INNER JOIN dbo.ArbitrageTicketDetails ft WITH (NOLOCK)
					ON si.MatchId = ft.MatchId AND si.CustId = ft.CustId AND si.FraudCaseId = @CurrentFraudCaseId
		WHERE ft.MatchId IN (SELECT DISTINCT MatchId FROM #tmpMatches WITH(NOLOCK));
		
							
		-- Insert new records for table SuspiciousInfo
		INSERT INTO dbo.SuspiciousInfo(CustId, MatchId, EventDate, FraudCaseId, SuspiciousDate, TransIds, ViolatiONCounter, TicketCounter)
		SELECT	[CustId]			= ft.CustId
			,	[MatchId]			= ft.MatchId
			,	[EventDate]			= ft.EventDate
			,	[FraudCaseId]		= @CurrentFraudCaseId
			,	[SuspiciousDate]	= GETDATE()
			,	[TransIds]			= STUFF((SELECT DISTINCT ',', CONVERT(VARCHAR(MAX), t1.TransIds) 
										FROM dbo.ArbitrageTicketDetails t1 WITH (NOLOCK)
										WHERE t1.MatchId = ft.MatchId AND t1.CustId = ft.CustId
										FOR XML PATH('')), 1, 1, '')
			,	ViolationCounter	= (SELECT COUNT(1)
										FROM (SELECT DISTINCT t2.Bettype, t2.TotalScores, t2.Handicap
										FROM dbo.ArbitrageTicketDetails AS t2 WITH (NOLOCK)
										WHERE t2.MatchId = ft.MatchId AND t2.CustId = ft.CustId) AS A)
			,	[TicketCounter]		= (SELECT SUM(t2.TicketCounter) 
										FROM dbo.ArbitrageTicketDetails t2 WITH (NOLOCK)
										WHERE t2.MatchId = ft.MatchId AND t2.CustId = ft.CustId)
		FROM #tmpFraudTickets ft WITH (NOLOCK)
				LEFT JOIN dbo.SuspiciousInfo si WITH (NOLOCK) 
					ON si.MatchId = ft.MatchId AND si.CustId = ft.CustId  AND si.FraudCaseId = @CurrentFraudCaseId
		WHERE si.MatchID IS NULL AND si.FraudCaseId IS NULL AND si.CustId IS NULL
			AND ft.MatchId IN (SELECT DISTINCT MatchId FROM #tmpMatches WITH(NOLOCK))
		GROUP BY ft.CustId, ft.MatchId, ft.EventDate;
			
		-- Update table SuspiciousCustomer if existed
		UPDATE sc WITH (ROWLOCK, UPDLOCK)
		SET sc.IsVerified = 0
		FROM dbo.SuspiciousCustomer sc 
		WHERE sc.Custid IN (SELECT DISTINCT(Custid)
							FROM #tmpFraudTickets ft WITH (NOLOCK)
							WHERE sc.Custid = ft.CustId);

		-- Insert new records for table SuspiciousCustomer
		INSERT INTO dbo.SuspiciousCustomer(Custid, IsDelinquent, IsHedge, IsDirty, IsVerified)
		SELECT DISTINCT ft.CustId, 0, 0, 0, 0
		FROM #tmpFraudTickets ft WITH (NOLOCK)
		WHERE ft.CustId NOT IN (
				SELECT sc.CustId 
				FROM dbo.SuspiciousCustomer sc WITH (NOLOCK)
			);
	END;	
	
	-- Update table ScannedMatch if existed
	UPDATE	sm WITH (ROWLOCK, UPDLOCK)
	SET		sm.ScannedDate				= GETDATE()
		,	sm.SuspiciousTicketsCount	= ISNULL((SELECT SUM(t1.TicketCounter)
											FROM dbo.ArbitrageTicketDetails t1 WITH (NOLOCK)
											WHERE t1.MatchId = m.MatchId 
											GROUP BY t1.MatchId ),0)
	FROM dbo.ScannedMatch sm
		INNER JOIN #tmpMatches m WITH (NOLOCK) ON sm.MatchId = m.MatchId AND sm.FraudCaseId = @CurrentFraudCaseId;
	
	-- Insert new records for table ScannedMatch
	INSERT INTO dbo.ScannedMatch (Matchid, FraudCaseId, ScannedDate, SuspiciousTicketsCount)  
	SELECT	DISTINCT [MatchId]			= m.matchid 
		,	[FraudCaseId]				= @CurrentFraudCaseId
		,	[ScannedDate]				= GETDATE() 
		,	[SuspiciousTicketsCount]	= ISNULL((SELECT SUM(t1.TicketCounter)
											FROM dbo.ArbitrageTicketDetails t1 WITH (NOLOCK)
											WHERE t1.MatchId = m.MatchId 
											GROUP BY t1.MatchId ),0)
	FROM #tmpMatches m
		LEFT JOIN dbo.ScannedMatch sm WITH (NOLOCK)ON m.matchid = sm.matchid AND sm.FraudCaseId = @CurrentFraudCaseId
	WHERE sm.Matchid IS NULL 
		AND sm.FraudCaseId IS NULL; 
		
	--Remove the XML documents
	EXEC sp_xml_removedocument @idocMatch;
	EXEC sp_xml_removedocument @idocAssociation;
END;


GO 
 GRANT EXECUTE ON [dbo].[FS_FraudCase_Arbitrage_Rule] TO [bodbSPUNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[FS_FraudCase_Arbitrage_Rule] TO [bodbSPUNet]
GO 

GO
/*<info serverAlias="DBSPU-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/