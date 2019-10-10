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
		- 20191002@Long: Update logic [Redmine ID: #118117]

	Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @__custId INT
	SET @__custId = @Custid

	IF @__custId IS NOT NULL
	BEGIN
		SELECT sc.Custid, sc.IsDelinquent, sc.IsDirty, sc.IsHedge, sc.IsVerified
		FROM dbo.SuspiciousCustomer AS sc WITH(NOLOCK)
		WHERE sc.Custid = @__custId
			  AND (@IsDelinquent IS NULL OR sc.[IsDelinquent] = @IsDelinquent)
			  AND (@IsHedge IS NULL OR sc.[IsHedge] = @IsHedge)
			  AND (@IsDirty IS NULL OR sc.[IsDirty] = @IsDirty)
			  AND (@IsShowSpecialCurrencies = 1 OR sc.CurrencyId NOT IN (SELECT CurrencyId FROM dbo.SpecialCurrency WITH(NOLOCK)))
	END
	ELSE
	BEGIN
		SELECT sc.Custid, sc.IsDelinquent, sc.IsDirty, sc.IsHedge, sc.IsVerified
		FROM dbo.SuspiciousCustomer AS sc WITH(NOLOCK)
		WHERE (@IsDelinquent IS NULL OR sc.[IsDelinquent] = @IsDelinquent)
			  AND (@IsHedge IS NULL OR sc.[IsHedge] = @IsHedge)
			  AND (@IsDirty IS NULL OR sc.[IsDirty] = @IsDirty)
			  AND (@IsShowSpecialCurrencies = 1 OR sc.CurrencyId NOT IN (SELECT CurrencyId FROM dbo.SpecialCurrency WITH(NOLOCK)))
	END
	
END

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/