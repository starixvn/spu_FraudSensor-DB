SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER PROCEDURE [dbo].[FS_FraudCase_GroupBetting_Rule] 
		@MatchIds					VARCHAR(MAX) = NULL
	,	@GroupBettingAccountsXML	VARCHAR(MAX)
AS
/*
	Created: 20200519@Long.Luu
	Task : PreCondition for Group Betting fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20200519@Long.Luu: Created [Redmine ID: #133514]

	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	

	DECLARE @CurrentFraudCaseId TINYINT = 13;
	DECLARE @idoc INT;

	IF OBJECT_ID('tempdb..#tmpBettypes') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpBettypes;
	END;

	CREATE TABLE #tmpBettypes(
			BettypeId		INT	NOT	NULL PRIMARY KEY CLUSTERED
	);

	IF OBJECT_ID('tempdb..#tmpSports') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSports;
	END;

	CREATE TABLE #tmpSports(
			SportId			TINYINT NOT NULL PRIMARY KEY CLUSTERED
	);
	
	IF OBJECT_ID('tempdb..#tmpGroupBettingAccounts') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpGroupBettingAccounts;
	END
	
	CREATE TABLE #tmpGroupBettingAccounts(
			CustId				INT
		,	CategoryId			SMALLINT
		,	CategoryName		NVARCHAR(50)
	);

	CREATE CLUSTERED INDEX	#CIX_tmpGroupBettingAccountsIdx ON #tmpGroupBettingAccounts (
			CustId				ASC
	);

	IF OBJECT_ID('tempdb..#tmpFraudTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTickets;
	END
	
	CREATE TABLE #tmpFraudTickets(
			CustId				INT		NOT NULL
		,	MatchId				INT		NOT NULL
		,	TransId				BIGINT	NOT NULL
		,	Username			NVARCHAR(50)
		,	CurrencyId			TINYINT
		,	CurrencyName		NVARCHAR(50)		
		,	EventDate			DATETIME
		,	PRIMARY KEY CLUSTERED (
				CustId			ASC
			,	MatchId			ASC
			,	TransId			ASC
		)		
	);

	IF OBJECT_ID('tempdb..#tmpFraudTicketsCustInfo') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTicketsCustInfo;
	END
	
	CREATE TABLE #tmpFraudTicketsCustInfo(
			CustId				INT	NOT	NULL PRIMARY KEY CLUSTERED
		,	Username			NVARCHAR(50)
		,	CurrencyId			TINYINT
	);

	IF OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatches;
	END;

	CREATE TABLE #tmpMatches
	(
		MatchId INT	NOT	NULL PRIMARY KEY CLUSTERED
	);

	IF	OBJECT_ID('tempdb..#tmpDangerousCustomer') IS NOT NULL
		DROP TABLE	#tmpDangerousCustomer;

	CREATE TABLE #tmpDangerousCustomer(
		[CustId]			INT NOT NULL PRIMARY KEY
	);

	-- START
	-- Init sports and bettypes
	INSERT INTO #tmpBettypes(BettypeId)
	SELECT val FROM SPU_StrSplit('1,3,7,8,20,21,153,154,155,156,609,610,612,701,704,705,9001,9003,9004', ',');

	INSERT INTO #tmpSports(SportId)
	SELECT DISTINCT m.SportType
	FROM bodb02.dbo.SportBettypeMatrix AS m WITH(NOLOCK)
		INNER JOIN #tmpBettypes AS b WITH(NOLOCK) ON m.BetType = b.BettypeId;

	-- Get AI Ghost Accounts
	INSERT INTO #tmpDangerousCustomer(CustId)
	SELECT a.CustId
	--FROM DBONUSER.ON_USER.dbo.AbnormalUsers AS a WITH(NOLOCK)
	FROM ON_USER.dbo.AbnormalUsers AS a WITH(NOLOCK)
	WHERE (flags & 4) = 4;

	-- Insert flagged accounts	
	EXEC sp_xml_preparedocument @idoc OUTPUT, @GroupBettingAccountsXML;

	INSERT	INTO #tmpGroupBettingAccounts(CustId)
	SELECT	Data.CustId
	FROM	OPENXML (@idoc, '/Root/CustomerCategory', 1)
			WITH (CustId INT, CategoryId SMALLINT, CategoryName NVARCHAR(50)) AS Data;

	-- Remove group betting accounts that donot exist in the AIGhost Account
	DELETE g WITH(ROWLOCK)
	FROM #tmpGroupBettingAccounts AS g
		LEFT JOIN #tmpDangerousCustomer AS d WITH(NOLOCK) ON g.CustId = d.CustId
	WHERE d.CustId IS NULL;

	-- Retrive matches for scanning
	INSERT INTO #tmpMatches(MatchId)
	SELECT val FROM SPU_StrSplit(@MatchIds, ',');

	-- Get fraud tickets
	INSERT INTO #tmpFraudTickets(CustId, Username, CurrencyId, CurrencyName, MatchId, EventDate, TransId)
	SELECT	DISTINCT [CustId]	= ans.custid
		,	[Username]			= ans.Username
		,	[CurrencyId]		= ans.currency
		,	[CurrencyName]		= ans.CurrencyName
		,	[MatchId]			= ans.matchid
		,	[EventDate]			= sm.EventDate
		,	[TransId]			= ans.transid
	FROM	dbo.ScanningMatch AS sm WITH (NOLOCK)
		INNER JOIN #tmpMatches AS m WITH(NOLOCK) ON sm.MatchId = m.MatchId AND sm.FraudCaseId = @CurrentFraudCaseId
		INNER JOIN bodb02.dbo.bettrans AS ans WITH (NOLOCK) ON m.matchid = ans.matchid
		INNER JOIN #tmpBettypes AS b WITH(NOLOCK) ON ans.bettype = b.BettypeId
		INNER JOIN #tmpGroupBettingAccounts AS fa WITH (NOLOCK) ON fa.custid = ans.custid
	WHERE ans.currency <> 20
	OPTION (MAXDOP 1);

	-- UPDATE match info for ScannedMatch table
	DELETE FROM dbo.ScannedMatch WITH (ROWLOCK)
	WHERE FraudCaseId = @CurrentFraudCaseId
		AND MatchId IN (SELECT MatchId FROM #tmpMatches WITH (NOLOCK));

	-- Insert new ones
	INSERT INTO dbo.ScannedMatch(MatchId, FraudCaseId, ScannedDate, SuspiciousTicketsCount)
	SELECT	[MatchId]					= m.MatchId
		,	[FraudCaseId]				= @CurrentFraudCaseId
		,	[ScannedDate]				= GETDATE()
		,	[SuspiciousTicketsCount]	= COUNT(ft.TransId)
	FROM #tmpMatches m WITH (NOLOCK)
		LEFT JOIN #tmpFraudTickets ft WITH (NOLOCK) ON m.MatchId = ft.MatchId
	GROUP BY m.MatchId, ft.MatchId;

	-- Check the results and store/return data
	IF(SELECT COUNT(1) FROM #tmpFraudTickets WITH (NOLOCK)) > 0
	BEGIN
		INSERT INTO #tmpFraudTicketsCustInfo (CustId, Username, CurrencyId)
		SELECT DISTINCT ft.Custid, ft.Username, ft.CurrencyId
		FROM #tmpFraudTickets ft WITH (NOLOCK);

		UPDATE sc WITH (ROWLOCK, UPDLOCK)
		SET sc.IsVerified = 0, sc.Username = t.Username
		FROM dbo.SuspiciousCustomer sc 
			INNER JOIN #tmpFraudTicketsCustInfo t ON sc.Custid = t.CustId;
	
		INSERT INTO dbo.SuspiciousCustomer(Custid, Username, CurrencyId, IsDelinquent, IsHedge, IsDirty, IsVerified)
		SELECT ft.CustId, ft.Username, ft.CurrencyId, 0, 0, 0, 0
		FROM #tmpFraudTicketsCustInfo ft WITH (NOLOCK)
		WHERE ft.CustId NOT IN (SELECT sc.CustId 
								FROM dbo.SuspiciousCustomer sc WITH (NOLOCK));
					
		DELETE FROM dbo.SuspiciousInfo WITH (ROWLOCK)
		WHERE FraudCaseId = @CurrentFraudCaseId
			AND MatchId IN (SELECT MatchId FROM #tmpMatches WITH (NOLOCK));

		INSERT INTO dbo.SuspiciousInfo(CustId, MatchId, EventDate, FraudCaseId, SuspiciousDate, TransIds, ViolationCounter, TicketCounter)
		SELECT [CustId]				= ft.CustId
			,	[MatchId]			= ft.MatchId
			,	[EventDate]			= ft.EventDate
			,	[FraudCaseId]		= @CurrentFraudCaseId
			,	[SuspiciousDate]	= GETDATE()
			,	[TransIds]			= STUFF((SELECT ',', CONVERT(VARCHAR(15), t1.TransId) 
										 FROM #tmpFraudTickets AS t1 WITH (NOLOCK)
										 WHERE t1.CustId = ft.CustId AND t1.MatchId = ft.MatchId 
										 FOR XML PATH('')), 1, 1, '')
			,	[ViolationCounter]	= 1
			,	[TicketCounter]		= COUNT(ft.TransId)
		FROM #tmpFraudTickets ft WITH (NOLOCK)
		GROUP BY ft.CustId, ft.MatchId, ft.EventDate;		

	END;
	
	-- Update table ScanningMatch
	UPDATE m  WITH(ROWLOCK, UPDLOCK)
	SET	m.IsScanCompleted = 1
	FROM dbo.ScanningMatch AS m
		INNER JOIN	#tmpMatches AS mi WITH (NOLOCK) ON mi.MatchId = m.MatchId AND m.FraudCaseId = @CurrentFraudCaseId
	WHERE m.IsScanCompleted = 0
		AND m.EventStatus = 'Completed';

	EXEC sp_xml_removedocument @idoc;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/