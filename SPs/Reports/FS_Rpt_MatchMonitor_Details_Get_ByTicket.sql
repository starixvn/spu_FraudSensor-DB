
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER PROCEDURE [dbo].[FS_Rpt_MatchMonitor_Details_Get_ByTicket]
		@MatchId					INT
	,	@EventDate					DATETIME
	,	@FraudCaseId				INT	
	,	@IsShowSpecialCurrencies	BIT = 0
AS
/*
	Created: 20180312@CaseyHuynh
	Task : [US011-Fraud Case Details. By Ticket]
	DB: bodb_FraudSensor
	Original:

	Revisions:
		+ 20180523@CaseyHuynh:	Put alias for LiveHomeScore/LiveAwayScore column
		- 20181114@Long:		Adding View Permission on Special Currencies [Redmine ID: #104707]
		- 20190219@John:		Update logic Special Currencies and seperate Arbitrage [Redmine ID: #99753]
		- 20190710@John.Ngo:	Update #temp table [Redmine ID: #116619]

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON;
	
	--===	1.1 INITIAL TEMP TABLES #tmpBUMB: Include Balance Up and Move Bet Days	
	IF OBJECT_ID('tempdb..#tmpBUMB') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpBUMB;
	END;
	
	CREATE TABLE #tmpBUMB (
			BUDay		SMALLDATETIME
		,	MBDay		SMALLDATETIME
	 );
	 
	 --===	1.2 INITIAL: TEMP TABLES #tmpFraudTickets: GET Fraud Tickets
	IF OBJECT_ID('tempdb..#tmpFraudTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFraudTickets;
	END;
	
	CREATE TABLE #tmpFraudTickets (
			TransID		BIGINT
	 );

	CREATE CLUSTERED INDEX #CIX_tmpFraudTickets_TransID ON #tmpFraudTickets (
			TransID			ASC
	);

	--===	2.1 GET: Balance Up Day and Move Bet Day
	INSERT INTO #tmpBUMB(BUDay,MBDay)
	EXECUTE bodb02.dbo.Age_SelBalanceUpDay;

	DECLARE @IsAfterMoveBetDay BIT = 1;

	SELECT TOP(1) @IsAfterMoveBetDay = 0
	FROM #tmpBUMB WITH(NOLOCK)
	WHERE @EventDate BETWEEN BUDay AND MBDay;
	
	--===	2.2 GET: Fraud Tickets Insert to #tmpFraudTickets	
	--INSERT INTO #tmpFraudTickets(TransId)
	INSERT INTO #tmpFraudTickets(TransID)
	SELECT VAL
	FROM dbo.SuspiciousInfo si WITH(NOLOCK)
		INNER JOIN dbo.SuspiciousCustomer c WITH(NOLOCK) ON si.Custid = c.custid
		CROSS APPLY dbo.SPU_StrSplit(si.transids, ',')
	WHERE si.EventDate = @EventDate
		AND si.MatchId = @MatchId
		AND si.FraudCaseId = @FraudCaseId
		AND (@IsShowSpecialCurrencies = 1 OR c.CurrencyId NOT IN (SELECT CurrencyId FROM dbo.SpecialCurrency WITH(NOLOCK)));
			
	--===	2.2 GET: Homeid and AwayId
	DECLARE @homeId INT;
	DECLARE @awayId INT;
			
	--===	3.1 RETURN: Fraud Tickets Info				
	If @IsAfterMoveBetDay = 1
		BEGIN
			SELECT @homeId = m.homeid
					, @awayId = m.awayid
			FROM bodb02.dbo.match m WITH(NOLOCK)
			WHERE m.matchid = @MatchId;
			
			SELECT b.Username
				,	b.bettype [bettypeId]
				,	b.Transid
				,	b.transdate
				,	b.betid
				,	b.betteam
				,	b.hdp1	[handicap1]
				,	b.hdp2	[handicap2]
				,	ISNULL(b.livehomescore,0) [livehomescore]
				,	ISNULL(b.liveawayscore,0) [liveawayscore]
				,	b.liveindicator [isLive]
				,	b.odds
				,	b.oddstype
				,	b.stake
				,	(CASE WHEN b.statusID IN (111,112,113) THEN (b.winlost-b.actual_stake )
						ELSE 0
						END) [winlost]
				,	b.status
				,	ISNULL(b.IP,'') [IP]
				,	b.currencyname
			FROM bodb02.dbo.bettrans b WITH(NOLOCK)
					INNER JOIN #tmpFraudTickets f WITH(NOLOCK) ON b.transid = f.TransID
			WHERE b.winlostdate = @EventDate;

		END;
	ELSE
		BEGIN		
			SELECT @homeId = m.homeid
					, @awayId = m.awayid
			FROM bodb02.dbo.match14 m WITH(NOLOCK)
			WHERE m.matchid = @MatchId;
			
			SELECT b.Username
				,	b.bettype [bettypeId]
				,	b.Transid
				,	b.transdate
				,	b.betid
				,	b.betteam
				,	b.hdp1	[handicap1]
				,	b.hdp2	[handicap2]
				,	ISNULL(b.livehomescore,0) [livehomescore]
				,	ISNULL(b.liveawayscore,0) [liveawayscore]
				,	b.liveindicator [isLive]
				,	b.odds
				,	b.oddstype
				,	b.stake
				,	(CASE WHEN b.statusID IN (111,112,113) THEN (b.winlost-b.actual_stake )
						ELSE 0
					 END) [winlost]
				,	b.status
				,	ISNULL(b.IP,'') [IP]
				,	b.currencyname
			FROM bodb02.dbo.bettrans14 b WITH(NOLOCK)
					INNER JOIN #tmpFraudTickets f WITH(NOLOCK) ON b.transid = f.TransID
			WHERE b.winlostdate = @EventDate;
		END;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/