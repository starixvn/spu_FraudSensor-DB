
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.FS_Tbl_CustomerMonitorAssignment_Update    Script Date: 5/15/2018 4:21:24 PM ******/
CREATE PROCEDURE [dbo].[FS_Tbl_CustomerMonitorAssignment_Update]
		@CustId INT
	,	@AssigneeId INT = NULL
	,	@UserId INT
	,	@ErrCode INT	=	0 OUTPUT
AS
/*
	Created: 20180504@CaseyHuynh
	Task : Update Suspicous Customer Details_Assignee
	DB: bodb_FraudSensor
	Original:
	Revisions:
	Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @LogTypeId		INT	=	10;
	DECLARE @LogData		VARCHAR(500)
			, @SPName		VARCHAR(100);

	DECLARE @LastModifiedDate DATETIME;
	SELECT @LastModifiedDate	=	GETDATE();
	SELECT @ErrCode = 0;
		
    BEGIN TRY
		UPDATE DBO.CustomerMonitorAssignment WITH(ROWLOCK)
		SET		AssigneeId			=	CASE WHEN @AssigneeId = -1 THEN NULL ELSE @AssigneeId END
			,	LastModifiedDate	=	@LastModifiedDate
			,	CreatorId			=	@UserId
		WHERE CustId	=	@CustId;
	END TRY
	BEGIN CATCH
		SELECT @ErrCode	=	ERROR_NUMBER();
	END CATCH

	------------ Write Log ------------ 
		SELECT @LogData =	'CustId	= '					+	DBO.SPU_ToString(@CustId) 
							+ ', AssigneeId	= '			+	DBO.SPU_ToString(@AssigneeId) 
							+ ', LastModifiedDate =	'	+	DBO.SPU_ToString(@LastModifiedDate) 
							+ ', CreatorId = '			+	DBO.SPU_ToString(@UserId);

		SELECT @SPName	=	OBJECT_NAME(@@ProcID);

		EXEC [dbo].[FS_UserLog_Insert]  
				@LogTypeId	=	@LogTypeId   
			,	@UserId		=	@UserId  
			,	@SPName		=	@SPName
			,	@Details	=	@LogData;
END;

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[FS_Tbl_CustomerMonitorAssignment_Update] TO [bodbSPUNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[FS_Tbl_CustomerMonitorAssignment_Update] TO [bodbSPUNet]
GO 
