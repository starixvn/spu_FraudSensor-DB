SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[FS_ArchiveData_Arbitrage] 
AS
/*
	Created: 20190419@CaseyHuynh
	Task : ArchiveData before BU DAY
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20190419@Casey.Huynh: Archive Data Arbitrage before BU DAY [#112211]

	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	
	---=========INITIAL========================
	DECLARE @BUDate DATETIME;
	DECLARE @IsMoved BIT;

	IF	OBJECT_ID('tempdb..#tmpBUMBData') IS NOT NULL
	BEGIN;
		DROP TABLE	#tmpBUMBData
	END;

	CREATE TABLE	#tmpBUMBData (
			BUDay	DATETIME
		,	MBDay	DATETIME
	);	

	IF	OBJECT_ID('tempdb..#tmpEventDate') IS NOT NULL
	BEGIN;
		DROP TABLE	#tmpEventDate
	END;

	CREATE TABLE	#tmpEventDate (
			EventDate	DATETIME NOT NULL PRIMARY KEY
	);
	---=========GET: BU DAYs==========================
	INSERT INTO #tmpBUMBData(BUDay,MBDay)
	EXECUTE bodb02.dbo.Age_SelBalanceUpDay;

	SELECT @BUDate	= (SELECT TOP(1) BUDAY FROM #tmpBUMBData WITH(NOLOCK))

	--========== MOVE DATA ArbitrageSuspiciousInfo
	INSERT INTO	#tmpEventDate(EventDate)
	SELECT		DISTINCT asi.EventDate
	FROM		dbo.ArbitrageSuspiciousInfo asi WITH(NOLOCK)
	WHERE		asi.EventDate < @BUDate;

	IF EXISTS (SELECT 1 FROM #tmpEventDate WITH(NOLOCK))
	BEGIN
		DELETE		asi_bk
		FROM		dbo.ArbitrageSuspiciousInfo_bk asi_bk WITH(ROWLOCK)
		INNER JOIN	#tmpEventDate ed WITH(NOLOCK)
					ON asi_bk.EventDate = ed.EventDate
		
		INSERT INTO	dbo.ArbitrageSuspiciousInfo_bk(CustId, MatchId, FraudCaseId, EventDate, SuspiciousDate, TransIds, IsVerified, ViolationCounter, TicketCounter, VerifiedDate, VerifiedBy)
		SELECT		CustId
					, asi.MatchId
					, asi.FraudCaseId
					, asi.EventDate
					, asi.SuspiciousDate
					, asi.TransIds
					, asi.IsVerified
					, asi.ViolationCounter
					, asi.TicketCounter
					, asi.VerifiedDate
					, asi.VerifiedBy
		FROM		dbo.ArbitrageSuspiciousInfo asi WITH(NOLOCK)
		INNER JOIN	#tmpEventDate ed WITH(NOLOCK)
					ON ed.EventDate = asi.EventDate;

		DELETE		asi
		FROM		dbo.ArbitrageSuspiciousInfo asi WITH(ROWLOCK)
		INNER JOIN	#tmpEventDate ed WITH(NOLOCK)
					ON asi.EventDate = ed.EventDate;

	END;

	--========== MOVE DATA ArbitrageTicketDetails
	TRUNCATE TABLE #tmpEventDate;

	INSERT INTO	#tmpEventDate(EventDate)
	SELECT		DISTINCT atd.EventDate
	FROM		dbo.ArbitrageTicketDetails atd WITH(NOLOCK)
	WHERE		atd.EventDate < @BUDate;

	IF EXISTS (SELECT 1 FROM #tmpEventDate WITH(NOLOCK))
	BEGIN
		DELETE		atd_bk
		FROM		dbo.ArbitrageTicketDetails_bk atd_bk WITH(ROWLOCK)
		INNER JOIN	#tmpEventDate ed WITH(NOLOCK)
					ON atd_bk.EventDate = ed.EventDate
		
		INSERT INTO	dbo.ArbitrageTicketDetails_bk(CustId, MatchId, GroupId, TransIds, BetType, Handicap, TicketCounter, IsIPFraud, GraphDBGroupId, LiveHomeScore, LiveAwayScore)
		SELECT		atd.CustId
					, atd.MatchId
					, atd.GroupId
					, atd.TransIds
					, atd.BetType
					, atd.Handicap
					, atd.TicketCounter
					, atd.IsIPFraud
					, atd.GraphDBGroupId
					, atd.LiveHomeScore
					, atd.LiveAwayScore
		FROM		dbo.ArbitrageTicketDetails atd WITH(NOLOCK)
		INNER JOIN	#tmpEventDate ed WITH(NOLOCK)
					ON ed.EventDate = atd.EventDate;

		DELETE		atd
		FROM		dbo.ArbitrageTicketDetails atd WITH(ROWLOCK)
		INNER JOIN	#tmpEventDate ed WITH(NOLOCK)
					ON atd.EventDate = ed.EventDate;

	END;

END;
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
