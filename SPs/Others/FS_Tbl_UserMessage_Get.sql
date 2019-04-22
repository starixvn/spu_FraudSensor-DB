
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER PROCEDURE [dbo].[FS_Tbl_UserMessage_Get]
	@CustId		INT
AS
/*
	Created: 20180604@Long
	Task : Get Message by CustId
	DB: bodb_FraudSensor
	Original:
	Revisions:
	Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;

	SELECT TOP (20)
			[FraudCaseName]		= fc.FraudCaseName
		,	[MessageContent]	= m.MessageContent
		,	[LogDate]			= m.LogDate
		,	[IsViewed]			= um.IsViewed
	FROM dbo.[UserMessage] AS um WITH(NOLOCK)
		INNER JOIN dbo.[Message] AS m WITH(NOLOCK) ON um.MessageId = m.MessageId
		INNER JOIN dbo.FraudCase AS fc WITH(NOLOCK) ON fc.FraudCaseId = m.FraudCaseId
	WHERE um.UserId = @CustId
	ORDER BY m.LogDate DESC;

	UPDATE	dbo.UserMessage WITH(ROWLOCK, UPDLOCK)
	SET		IsViewed = 1
	WHERE	UserId	= @CustId AND IsViewed = 0;  
END;

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[FS_Tbl_UserMessage_Get] TO [bodbSPUNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[FS_Tbl_UserMessage_Get] TO [bodbSPUNet]
GO 
