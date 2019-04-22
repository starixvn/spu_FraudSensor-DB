SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER PROCEDURE [dbo].[FS_Tbl_CustomerLog_Delete]
		@CustomerLogId		INT
	,	@UserId				INT
	,	@ErrCode			INT	=	0 OUTPUT
AS
/*
	Created: 20180504@CaseyHuynh
	Task : Remove Suspicous Customer Details_LogNotes
	DB: bodb_FraudSensor
	Original:

	Revisions:
				- 20181226@John: Update logic write log [Redmine ID: #106145]	

	Param's Explanation:    
*/
BEGIN
	SET NOCOUNT ON;
		
	DECLARE @LogTypeId		INT	=	13;
	DECLARE		@LogData		VARCHAR(500)
			,	@SPName		VARCHAR(100);
	
	DECLARE @DelCustId			INT
			,	@DelCusLogType	INT
			,	@DelCaseId		INT
			,	@DelLogDesc		NVARCHAR(500)
			,	@DelLogDate		DATETIME;
	
	SELECT @ErrCode = 0;
			
	BEGIN TRY		

		SELECT @DelCustId = CustId, @DelCaseId = CaseId, @DelLogDesc = LogDesc, @DelLogDate = LogDate, @DelCusLogType = CustLogType FROM dbo.CustomerLog WITH(NOLOCK)
		WHERE CustomerLogId	=	@CustomerLogId;
		
		DELETE dbo.CustomerLog WITH(ROWLOCK)
		WHERE CustomerLogId	=	@CustomerLogId;
		
	END TRY
	BEGIN CATCH
		SELECT @ErrCode	=	ERROR_NUMBER();
	END CATCH;

	------------ Write Log ------------
	IF @ErrCode = 0
		BEGIN
		SELECT @LogData =	'UserId	=	'				+	DBO.SPU_ToString(@UserId) 
							+ ',	@CustomerLogId	=	'	+	DBO.SPU_ToString(@CustomerLogId)
							+ ',	CustId	=	'			+	DBO.SPU_ToString(@DelCustId) 
							+ ',	CustLogType	=	'			+	DBO.SPU_ToString(@DelCusLogType) 
							+ ',	CaseId	=	'			+	DBO.SPU_ToString(@DelCaseId)
							+ ',	LogDesc	=	'			+	DBO.SPU_ToString(@DelLogDesc)
							+ ',	LogDate	=	'			+	DBO.SPU_ToString(@DelLogDate);

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