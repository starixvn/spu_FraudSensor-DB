
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER PROCEDURE [dbo].[FS_Tbl_UserMessage_GetUnreadCount]
	@CustId		INT
AS
/*
	Created: 20180604@Long
	Task : Get Unread Message counter by CustId
	DB: bodb_FraudSensor
	Original:
	Revisions:
	Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT [UnreadMessageCounter] = COUNT(1)
	FROM dbo.[UserMessage] AS um WITH(NOLOCK)
	WHERE um.UserId = @CustId 
		AND um.IsViewed = 0;
END;

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[FS_Tbl_UserMessage_GetUnreadCount] TO [bodbSPUNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[FS_Tbl_UserMessage_GetUnreadCount] TO [bodbSPUNet]
GO 
