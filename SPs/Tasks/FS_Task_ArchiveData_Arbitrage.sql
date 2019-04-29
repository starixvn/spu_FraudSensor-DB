SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[FS_Task_ArchiveData_Arbitrage] 
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
	DECLARE @EventDate DATETIME;

	IF	OBJECT_ID('tempdb..#tmpBUMBData') IS NOT NULL
	BEGIN;
		DROP TABLE	#tmpBUMBData
	END;

	CREATE TABLE	#tmpBUMBData (
			BUDay		DATETIME
		,	MBDay		DATETIME
	);	

	IF	OBJECT_ID('tempdb..#tmpEventDate') IS NOT NULL
	BEGIN;
		DROP TABLE	#tmpEventDate
	END;

	CREATE TABLE	#tmpEventDate (
			EventDate	DATETIME NOT NULL PRIMARY KEY
	);

	---=========GET: BU DAYs==========================
	INSERT INTO #tmpBUMBData(BUDay, MBDay)
	EXECUTE bodb02.dbo.Age_SelBalanceUpDay;

	SELECT @BUDate	= (SELECT TOP(1) BUDay FROM #tmpBUMBData WITH(NOLOCK));

	INSERT INTO	#tmpEventDate(EventDate)
	SELECT		DISTINCT asi.EventDate
	FROM		dbo.ArbitrageSuspiciousInfo AS asi WITH(NOLOCK)
	WHERE		asi.EventDate < @BUDate;

	WHILE EXISTS (SELECT 1 FROM #tmpEventDate WITH(NOLOCK))
	BEGIN
		SELECT @EventDate = EventDate FROM #tmpEventDate WITH(NOLOCK);

		--========== MOVE DATA ArbitrageSuspiciousInfo
		DELETE FROM	dbo.ArbitrageSuspiciousInfo_bk WITH(ROWLOCK)
		WHERE		EventDate = @EventDate;
		
		INSERT INTO	dbo.ArbitrageSuspiciousInfo_bk(CustId, MatchId, FraudCaseId, EventDate, SuspiciousDate, TransIds, IsVerified, ViolationCounter, TicketCounter, VerifiedDate, VerifiedBy)
		SELECT		asi.CustId
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
		FROM		dbo.ArbitrageSuspiciousInfo AS asi WITH(NOLOCK)
		WHERE		asi.EventDate = @EventDate;

		DELETE FROM	dbo.ArbitrageSuspiciousInfo WITH(ROWLOCK)
		WHERE		EventDate = @EventDate;

		DELETE FROM #tmpEventDate WITH(ROWLOCK)
		WHERE		EventDate = @EventDate;
	END;

	INSERT INTO	#tmpEventDate(EventDate)
	SELECT		DISTINCT atd.EventDate
	FROM		dbo.ArbitrageTicketDetails AS atd WITH(NOLOCK)
	WHERE		atd.EventDate < @BUDate;

	WHILE EXISTS (SELECT 1 FROM #tmpEventDate WITH(NOLOCK))
	BEGIN
		SELECT @EventDate = EventDate FROM #tmpEventDate WITH(NOLOCK);

		--========== MOVE DATA ArbitrageTicketDetails
		DELETE FROM dbo.ArbitrageTicketDetails_bk WITH(ROWLOCK)
		WHERE		EventDate = @EventDate;
		
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
		FROM		dbo.ArbitrageTicketDetails AS atd WITH(NOLOCK)
		WHERE		atd.EventDate = @EventDate;

		DELETE FROM dbo.ArbitrageTicketDetails WITH(ROWLOCK)
		WHERE		EventDate = @EventDate;

		DELETE FROM #tmpEventDate WITH(ROWLOCK)
		WHERE		EventDate = @EventDate;
	END;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
