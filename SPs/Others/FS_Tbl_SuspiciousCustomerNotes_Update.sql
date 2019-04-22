SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER PROCEDURE [dbo].[FS_Tbl_SuspiciousCustomerNotes_Update]
		@UserId			INT 
	,	@CustId			INT
	,	@Notes			NVARCHAR(500) = NULL
 
	,	@ErrCode		INT = 0 OUTPUT  
AS
/*
	Created: 20181226@Long
	Task : Update Notes for SuspiciousCustomer table
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20181226@Long: Created [Redmine ID: #106145]

	Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @LogTypeId				INT	=	11
		,	@LogData				VARCHAR(500)
		,	@SPName					VARCHAR(100)
		,	@CurrentFraudCaseId		TINYINT
		,	@CustLogType			TINYINT = 1 -- CustLogType = 1: Note
		,	@InsertTime				DATETIME;

	SELECT	@CurrentFraudCaseId		= 11; -- Bets Near Goal
	SELECT @ErrCode = 0;
	
	BEGIN TRY  
		UPDATE	dbo.SuspiciousCustomer WITH(ROWLOCK)
		SET		Notes = @Notes
		WHERE	CustId = @CustId;

		------------ Write CustomerLog ------------
		SELECT @InsertTime = GETDATE();     
		SELECT @LogData = @Notes;

		INSERT INTO dbo.CustomerLog(CustId, CreatorId, CustLogType, CaseId, LogDesc, LogDate)
		VALUES(@CustId, @UserId, @CustLogType, @CurrentFraudCaseId, @LogData, @InsertTime);
	
	END TRY  
	BEGIN CATCH  
		SET @ErrCode = ERROR_NUMBER();  
	END CATCH;
	
	------------ Write Log ------------
	IF @ErrCode = 0
		BEGIN 
		SELECT @LogData =	'CustId	=	'			+	DBO.SPU_ToString(@CustId) 
							+ ', CreatorId	=	' 	+	DBO.SPU_ToString(@UserId) 
							+ ', CustLogType	=	' 	+	DBO.SPU_ToString(@CustLogType)
							+ ', CaseId	=	' 		+	DBO.SPU_ToString(@CurrentFraudCaseId)
							+ ', LogDesc	=	' 	+	DBO.SPU_ToString(@LogData)
							+ ', LogDate	=	' 	+	DBO.SPU_ToString(@InsertTime);

		SELECT @SPName	=	OBJECT_NAME(@@ProcID);

		EXEC [dbo].[FS_UserLog_Insert]  
				@LogTypeId	=	@LogTypeId   
			,	@UserId		=	@UserId  
			,	@SPName		=	@SPName
			,	@Details	=	@LogData;

		END;
END;

GO
/*<info serverAlias="DBSPU-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/

