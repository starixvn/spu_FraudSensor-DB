USE bodb_FraudSensor
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE dbo.FS_Tbl_OfficeIP_GetAll

AS
/*
	Created: 20180605@CaseyHuynh
	Task : Get All Office IP
	DB: bodb_FraudSensor

	Original:

	Revisions: 

	Param's Explanation (filtered by):

*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT	FromIP = oi.IPRange + '.' + dbo.SPU_ToString(oi.FromNumber)
			,ToIP = oi.IPRange + '.' + dbo.SPU_ToString(oi.ToNumber)			
	FROM	dbo.OfficeIP oi WITH(NOLOCK)
	ORDER BY oi.IPRange, oi.FromNumber;
END;
GO 
 GRANT EXECUTE ON dbo.FS_Tbl_OfficeIP_GetAll TO bodbSPUNet;
GO 
 GRANT VIEW DEFINITION ON dbo.FS_Tbl_OfficeIP_GetAll TO bodbSPUNet;
GO 