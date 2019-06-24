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
		- 20190419@Casey.Huynh: Archive Data Arbitrage before BU DAY  [Redmine ID: 112211]
		- 20190508@Casey.Huynh: Enhance Performance [Redmine ID: 112211]
		- 20190624@John.Ngo:	Fix 'Missing EventDate value in ArbitrageTicketDetails_bk' [Redmine ID: 115326]
	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	

	---=========INITIAL========================
	DECLARE @BUDate DATETIME;
	DECLARE @EventDate DATETIME;

	IF	OBJECT_ID('tempdb..#tmpBUMBData') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpBUMBData
	END;

	CREATE TABLE	#tmpBUMBData (
			BUDay		DATETIME
		,	MBDay		DATETIME
	);	

	---------------------------------------------------
	IF	OBJECT_ID('tempdb..#tmpMovingMatch') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMovingMatch;
	END;

	CREATE TABLE	#tmpMovingMatch (
		MatchId		INT		PRIMARY KEY CLUSTERED
	);

	---=========GET: BU DAYs==========================
	INSERT INTO #tmpBUMBData(BUDay, MBDay)
	EXECUTE bodb02.dbo.Age_SelBalanceUpDay;

	SELECT @BUDate	= (SELECT TOP(1) BUDay FROM #tmpBUMBData WITH(NOLOCK));


	WHILE EXISTS (SELECT 1 FROM	dbo.ArbitrageSuspiciousInfo AS asi WITH(NOLOCK) WHERE asi.EventDate < @BUDate)
	BEGIN
		SELECT @EventDate = (	SELECT TOP(1) EventDate 
								FROM dbo.ArbitrageSuspiciousInfo AS asi WITH(NOLOCK) 
								WHERE asi.EventDate < @BUDate);

		--========== MOVE DATA ArbitrageSuspiciousInfo
		WHILE EXISTS (SELECT 1 FROM dbo.ArbitrageSuspiciousInfo_bk WITH(NOLOCK) WHERE EventDate = @EventDate)
		BEGIN
				DELETE TOP(1000)
				FROM dbo.ArbitrageSuspiciousInfo_bk WITH(ROWLOCK)
				WHERE EventDate = @EventDate;
		END;
		
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
				
		WHILE EXISTS (SELECT 1 FROM dbo.ArbitrageSuspiciousInfo WITH(NOLOCK) WHERE EventDate = @EventDate)
		BEGIN
				DELETE TOP(1000)
				FROM dbo.ArbitrageSuspiciousInfo WITH(ROWLOCK)
				WHERE EventDate = @EventDate;
		END;
	END;


	WHILE EXISTS (SELECT 1 FROM ArbitrageTicketDetails atd WITH(NOLOCK) WHERE EventDate < @BUDate)
	BEGIN
		SELECT @EventDate = ( SELECT	TOP(1) EventDate 
							FROM	dbo.ArbitrageTicketDetails atd WITH(NOLOCK) 
							WHERE	EventDate < @BUDate);

		--========== MOVE DATA ArbitrageTicketDetails
		WHILE EXISTS (SELECT 1 FROM dbo.ArbitrageTicketDetails_bk WITH(NOLOCK) WHERE EventDate = @EventDate)
		BEGIN
				DELETE	TOP(1000)
				FROM	dbo.ArbitrageTicketDetails_bk WITH(ROWLOCK)
				WHERE	EventDate = @EventDate;
		END;

		TRUNCATE TABLE	#tmpMovingMatch;

		INSERT INTO	#tmpMovingMatch (MatchId)
		SELECT	DISTINCT
				MatchId
		FROM	dbo.ArbitrageTicketDetails WITH (NOLOCK)
		WHERE	EventDate = @EventDate;


		INSERT INTO	dbo.ArbitrageTicketDetails_bk(CustId, MatchId, GroupId, TransIds, BetType, Handicap, TicketCounter, IsIPFraud, GraphDBGroupId, LiveHomeScore, LiveAwayScore, EventDate)
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
					, atd.EventDate
		FROM		dbo.ArbitrageTicketDetails AS atd WITH(NOLOCK)
		INNER JOIN	#tmpMovingMatch AS m WITH(NOLOCK)
					ON	atd.MatchId = m.MatchId;

		WHILE EXISTS (SELECT 1 FROM dbo.ArbitrageTicketDetails WITH(NOLOCK) WHERE EventDate = @EventDate)
		BEGIN
				DELETE TOP(1000)
				FROM	dbo.ArbitrageTicketDetails WITH(ROWLOCK)
				WHERE	EventDate = @EventDate;
		END;

	END;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" isFunction="0" isNested="0"></info>*/
