ALTER PROCEDURE [dbo].[FS_Rpt_MatchMonitor_Details_Get_ScoreHDP]
		@MatchId					INT
	,	@IsShowSpecialCurrencies	BIT = 0
AS
/*
	Created: 20190403@Long.Luu
	Task : Get list of Score-HDP by Match & Fraud Case for Arbitrage
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20190403@Long.Luu: Create [Redmine ID: #111069]

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON;	
	
	SELECT  si.BetType
		,	si.Handicap
		,	si.LiveHomeScore
		,	si.LiveAwayScore
	FROM dbo.ArbitrageTicketDetails si WITH(NOLOCK)
		INNER JOIN dbo.SuspiciousCustomer c WITH(NOLOCK) ON si.CustId = c.custid
	WHERE	si.MatchId = @MatchId
		AND (@IsShowSpecialCurrencies = 1 OR c.CurrencyId NOT IN (SELECT CurrencyId FROM dbo.SpecialCurrency WITH(NOLOCK)))
	GROUP BY si.BetType
		,	si.LiveHomeScore
		,	si.LiveAwayScore
		,	si.Handicap
	ORDER BY si.BetType
		,	si.LiveHomeScore
		,	si.LiveAwayScore
		,	si.Handicap

END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/