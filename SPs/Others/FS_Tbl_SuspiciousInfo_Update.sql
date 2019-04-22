
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.FS_Tbl_SuspiciousInfo_Update    Script Date: 5/15/2018 4:21:24 PM ******/

ALTER PROCEDURE [dbo].[FS_Tbl_SuspiciousInfo_Update]
		@UserId				INT
	,	@CustId				INT = NULL
	,	@MatchId			INT = NULL
	,	@FraudCaseId		TINYINT = NULL
	,	@EventDate			DATETIME = NULL
	,	@SuspiciousDate		DATETIME = NULL
	,	@TransIds			VARCHAR(MAX) = NULL
	,	@IsVerified			BIT = NULL
	,	@ViolationCounter	INT = NULL
	,	@TicketCounter		INT = NULL
	,	@ErrCode			INT = 0 OUTPUT
AS
/*
	Created: 20180504@CaseyHuynh
	Task : Update Table Suspicious Info
	DB: bodb_FraudSensor
	Original:

	Revisions:
	Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @LogTypeId		INT = 11;
	DECLARE @LogData		VARCHAR(500)
			, @SPName		VARCHAR(100);
	
	DECLARE @UpdateTime DATETIME = GETDATE();
	
	SELECT @ErrCode = 0;
		
	BEGIN TRY
		
		UPDATE [dbo].[SuspiciousInfo] WITH(ROWLOCK, UPDLOCK)
		SET 
			Custid = ISNULL(@Custid, CustId)
			, MatchId = ISNULL(@MatchId, MatchId)
			, FraudCaseId = ISNULL(@FraudCaseId, FraudCaseId)
			, EventDate = ISNULL(@EventDate,EventDate)
			, SuspiciousDate = ISNULL(@SuspiciousDate,SuspiciousDate)
			, TransIds = ISNULL(@TransIds,TransIds)		  
			, ViolationCounter = ISNULL(@ViolationCounter,ViolationCounter)
			, TicketCounter = ISNULL(@TicketCounter,TicketCounter)
			, IsVerified = ISNULL(@IsVerified,IsVerified)
			, VerifiedDate = CASE WHEN @IsVerified IS NOT NULL THEN @UpdateTime ELSE VerifiedDate END
			, VerifiedBy = CASE WHEN @IsVerified IS NOT NULL THEN @UserId ELSE VerifiedBy END
			WHERE Custid = ISNULL(@Custid,Custid)
				AND MatchId = ISNULL(@MatchId,MatchId)
				AND FraudCaseId = ISNULL(@FraudCaseId,FraudCaseId);
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER();
	END CATCH;
	------------ Write Customer Log------------------CustomerLog(CustId, CreatorId, LogType, CaseId, LogDesc, LogDate)
	
	IF (@ErrCode = 0 AND @IsVerified = 1 AND @FraudCaseId IS NOT NULL)
	BEGIN
		
		DECLARE @FraudCaseName NVARCHAR(100); 

		SELECT TOP(1) @FraudCaseName = FraudCaseName FROM dbo.FraudCase WITH(NOLOCK) WHERE FraudCaseId = @FraudCaseId;
		
		DECLARE @LogDesc NVARCHAR(50) = 'Verify Fraud Case: ' + @FraudCaseName;
			
		EXECUTE dbo.FS_Tbl_CustomerLog_Insert @CustId = @Custid, @UserId = @UserId, @CustLogType = 2 , @LogDate = @UpdateTime,  @CaseId = NULL, @LogDesc=@LogDesc;
		
		IF NOT EXISTS (SELECT TOP(1) 1 FROM dbo.SuspiciousInfo si WITH(NOLOCK) WHERE si.CustId = @CustId AND si.IsVerified = 0)
		BEGIN
			EXECUTE dbo.FS_Tbl_SuspiciousCustomer_Update @CustId = @Custid, @UserId = @UserId, @IsVerified = @IsVerified;
		END;
	END;

	------------ Write Log ------------
	IF @ErrCode = 0
	BEGIN		
		SELECT @LogData =  'UserId=' + dbo.SPU_ToString(@UserId) 
		SELECT @LogData = CASE WHEN @FraudCaseId IS NOT NULL THEN @LogData+ ', FraudCaseId ' + dbo.SPU_ToString(@FraudCaseId) ELSE @LogData END;
		SELECT @LogData = CASE WHEN @MatchId IS NOT NULL THEN @LogData+ ', MatchId=' + dbo.SPU_ToString(@MatchId) ELSE @LogData END;
		SELECT @LogData = CASE WHEN @CustId IS NOT NULL THEN @LogData+ ', CustId=' + dbo.SPU_ToString(@CustId) ELSE @LogData END;
		SELECT @LogData = CASE WHEN @EventDate IS NOT NULL THEN @LogData+ ', EventDate=' + dbo.SPU_ToString(@EventDate) ELSE @LogData END;
		SELECT @LogData = CASE WHEN @SuspiciousDate IS NOT NULL THEN @LogData+ ', SuspiciousDate=' + dbo.SPU_ToString(@SuspiciousDate) ELSE @LogData END;					
		SELECT @LogData = CASE WHEN @TransIds IS NOT NULL THEN @LogData+ ', TransIds=' + dbo.SPU_ToString(@TransIds) ELSE @LogData END;
		SELECT @LogData = CASE WHEN @ViolationCounter IS NOT NULL THEN @LogData+ ', ViolationCounter=' + dbo.SPU_ToString(@ViolationCounter) ELSE @LogData END;
		SELECT @LogData = CASE WHEN @TicketCounter IS NOT NULL THEN @LogData+ ', TicketCounter=' + dbo.SPU_ToString(@TicketCounter) ELSE @LogData END;
		SELECT @LogData = CASE WHEN @IsVerified IS NOT NULL THEN @LogData+ ', IsVerified=' + dbo.SPU_ToString(@IsVerified) ELSE @LogData END;
		SELECT @LogData = CASE WHEN @IsVerified IS NOT NULL THEN @LogData+ ', VerifiedDate=' + dbo.SPU_ToString(@UpdateTime) ELSE @LogData END;
		SELECT @LogData = CASE WHEN @IsVerified IS NOT NULL THEN @LogData+ ', VerifiedBy=' + dbo.SPU_ToString(@UserId) ELSE @LogData END;
		
	SELECT @SPName = OBJECT_NAME(@@ProcID);

	EXEC [dbo].[FS_UserLog_Insert]  
			@LogTypeId = @LogTypeId   
		,	@UserId = @UserId  
		,	@SPName = @SPName
		,	@Details = @LogData;
	END;
END;

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[FS_Tbl_SuspiciousInfo_Update] TO [bodbSPUNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[FS_Tbl_SuspiciousInfo_Update] TO [bodbSPUNet]
GO 
