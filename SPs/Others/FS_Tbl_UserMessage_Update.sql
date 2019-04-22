
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER PROCEDURE [dbo].[FS_Tbl_UserMessage_Update]
		@CustId			INT	
	,	@ErrCode		INT	= 0 OUTPUT
AS
/*
	Created: 20180604@Long
	Task : Update unread message for a CustId
	DB: bodb_FraudSensor
	Original:
	Revisions:
	Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;
		
    BEGIN TRY
		UPDATE	dbo.UserMessage WITH(ROWLOCK, UPDLOCK)
		SET		IsViewed			=	1
		WHERE	UserId	=	@CustId AND IsViewed = 0;
	END TRY
	BEGIN CATCH
		SELECT @ErrCode	=	ERROR_NUMBER();
	END CATCH
END;

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[FS_Tbl_UserMessage_Update] TO [bodbSPUNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[FS_Tbl_UserMessage_Update] TO [bodbSPUNet]
GO 
