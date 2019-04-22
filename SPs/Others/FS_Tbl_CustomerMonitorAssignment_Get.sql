
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.FS_Tbl_CustomerMonitorAssignment_Get    Script Date: 5/15/2018 4:21:24 PM ******/
CREATE PROCEDURE [dbo].[FS_Tbl_CustomerMonitorAssignment_Get]
		@CustId INT
AS
/*
	Created: 20180504@CaseyHuynh
	Task : Get Suspicous Customer Details_Assignee
	DB: bodb_FraudSensor
	Original:
	Revisions:
	Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT [Assignee]	=	ct.username
	FROM dbo.CustomerMonitorAssignment AS ca WITH(NOLOCK)
			INNER JOIN bodb02.dbo.Customer AS ct WITH(NOLOCK)
				ON ca.AssigneeId = ct.custid
	WHERE ca.custid = @CustId;
  
END;

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[FS_Tbl_CustomerMonitorAssignment_Get] TO [bodbSPUNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[FS_Tbl_CustomerMonitorAssignment_Get] TO [bodbSPUNet]
GO 
