SET QUOTED_IDENTIFIER ON;
GO
SET ANSI_NULLS ON;
GO

ALTER PROCEDURE [dbo].[FS_CustomerInfo_Get]
		@Custid	INT
AS
/*
	Created: 20180531@CaseyHuynh
	Task : Return Customer Info
	DB: bodb_FraudSensor
	Original:

	Revisions:
	Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT	ct.Custid
			, ct.username
			, ex.currency	
	FROM	bodb02.dbo.Customer ct	WITH(NOLOCK)
			INNER JOIN	bodb02.dbo.Exchange ex WITH(NOLOCK) ON ct.currency = ex.exchangeid
	WHERE	Custid = @Custid;
	
END;
GO

 GRANT EXECUTE ON [dbo].[FS_CustomerInfo_Get] TO [bodbSPUNet];
GO

 GRANT VIEW DEFINITION ON [dbo].[FS_CustomerInfo_Get] TO [bodbSPUNet];
GO 