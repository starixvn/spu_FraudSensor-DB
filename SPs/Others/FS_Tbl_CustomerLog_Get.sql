
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.FS_Tbl_CustomerLog_Get    Script Date: 5/15/2018 4:21:24 PM ******/
CREATE PROCEDURE [dbo].[FS_Tbl_CustomerLog_Get]
		@CustId	INT
AS
/*
	Created: 20180504@CaseyHuynh
	Task : Get Suspicious Customer Details_LogNotes
	DB: bodb_FraudSensor
	Original:

	Revisions:
	Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;

    SELECT	[CustomerLogId]	=	cl.CustomerLogId
		,	[Date]			=	cl.LogDate
		,	[Description]	=	cl.LogDesc
		,	[CreatorId]		=	cl.CreatorId
		,	[Author]		=	(SELECT Username FROM bodb02.dbo.Customer ct WITH(NOLOCK) WHERE ct.custid = cl.CreatorId) 
		,	[Type]			=	(CASE WHEN cl.CustLogType = 1 THEN 'Note' ELSE 'Log' END) 
    FROM	dbo.CustomerLog cl WITH(NOLOCK)
    WHERE	cl.CustId = @CustId
    ORDER BY Date DESC;
    
END;

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[FS_Tbl_CustomerLog_Get] TO [bodbSPUNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[FS_Tbl_CustomerLog_Get] TO [bodbSPUNet]
GO 
