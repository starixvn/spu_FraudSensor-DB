SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER PROCEDURE [dbo].[FS_Tbl_SuspiciousCustomer_Get]
		@Custid						INT
	,	@IsDelinquent				BIT = NULL
	,	@IsHedge					BIT = NULL
	,	@IsDirty					BIT = NULL
	,	@IsShowSpecialCurrencies	BIT = 0
AS
/*
	Created: 20180504@CaseyHuynh
	Task : Update Suspicous Customer Details_Classification
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20181114@Long: Adding View Permission on Special Currencies [Redmine ID: #104707]
		- 20190219@John: Update logic Special Currencies and seperate Arbitrage [Redmine ID: #99753]

	Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT sc.Custid, sc.IsDelinquent, sc.IsDirty, sc.IsHedge, sc.IsVerified
	FROM dbo.SuspiciousCustomer sc WITH(NOLOCK)
	WHERE sc.Custid				=	ISNULL(@Custid,sc.Custid)
		  AND sc.[IsDelinquent]	=	ISNULL(@IsDelinquent,sc.IsDelinquent)
		  AND sc.[IsHedge]		=	ISNULL(@IsHedge,sc.IsHedge)
		  AND sc.[IsDirty]		=	ISNULL(@IsDirty,sc.IsDirty)
		  AND (@IsShowSpecialCurrencies = 1 OR sc.CurrencyId NOT IN (SELECT CurrencyId FROM dbo.SpecialCurrency WITH(NOLOCK)));
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/