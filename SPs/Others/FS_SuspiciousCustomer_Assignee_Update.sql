
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.FS_SuspiciousCustomer_Assignee_Update    Script Date: 5/15/2018 4:21:24 PM ******/
ALTER PROCEDURE [dbo].[FS_SuspiciousCustomer_Assignee_Update]
		@CustId		INT
	,	@AssigneeId INT = NULL
	,	@UserId		INT
	,   @ErrCode	INT = 0 OUTPUT
AS
/*
	Created: 20180504@CaseyHuynh
	Task : Suspicious Customer Assignee Update
	DB: bodb_FraudSensor
	Original:
	Revisions:
	Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrCodeOutput	INT;
			
	IF EXISTS (SELECT TOP(1) CustId FROM dbo.CustomerMonitorAssignment	WITH(NOLOCK) WHERE CustId = @CustId)
	BEGIN
		EXECUTE dbo.FS_Tbl_CustomerMonitorAssignment_Update @Custid = @CustId, @AssigneeId = @AssigneeId, @UserId = @UserId, @ErrCode= @ErrCodeOutput OUTPUT;
	END;
	ELSE
	BEGIN
		EXECUTE dbo.FS_Tbl_CustomerMonitorAssignment_Insert @Custid = @CustId, @AssigneeId = @AssigneeId, @UserId = @UserId, @ErrCode= @ErrCodeOutput OUTPUT;
	END;

END;

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[FS_SuspiciousCustomer_Assignee_Update] TO [bodbSPUNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[FS_SuspiciousCustomer_Assignee_Update] TO [bodbSPUNet]
GO 
