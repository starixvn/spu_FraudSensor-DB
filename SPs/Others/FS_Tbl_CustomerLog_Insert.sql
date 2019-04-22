SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER PROCEDURE [dbo].[FS_Tbl_CustomerLog_Insert]
		@UserId			INT
	,	@CustId			INT
	,	@CustLogType	INT
	,	@CaseId			INT	=	NULL
	,	@LogDate		DATETIME	=	NULL
	,	@LogDesc		NVARCHAR(500)
	,	@ErrCode		INT	=	0 OUTPUT
	
AS
/*
	Created: 20180504@CaseyHuynh
	Task : Insert Suspicious Customer Details_LogNotes
	DB: bodb_FraudSensor
	Original:

	Revisions:
			- 20181226@John: Update logic write log [Redmine ID: #106145]			

	Param's Explanation:   
	 + @LogType: 1-Note, 2-Log
	 + @CaseId: NULL if LogType is 1-Note
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @LogTypeId		INT	=	12;
	DECLARE @LogData		VARCHAR(500)
			, @SPName		VARCHAR(100);
	
	DECLARE @InsertTime DATETIME;
	SELECT @ErrCode = 0;

	BEGIN TRY
	
		SELECT @InsertTime = ISNULL(@LogDate,GETDATE());
					
		INSERT INTO dbo.CustomerLog(CustId, CreatorId, CustLogType, CaseId, LogDesc, LogDate)
		VALUES(@CustId, @UserId, @CustLogType, @CaseId, @LogDesc, @InsertTime);
	
	END TRY
	BEGIN CATCH
		SELECT @ErrCode	=	ERROR_NUMBER();
	END CATCH;

	------------ Write Log ------------
	IF @ErrCode = 0
		BEGIN
		SELECT @LogData =	'CustId	=	'			+	DBO.SPU_ToString(@CustId) 
							+ ', CreatorId	=	' 	+	DBO.SPU_ToString(@UserId) 
							+ ', CustLogType	=	' 	+	DBO.SPU_ToString(@CustLogType) 
							+ ', CaseId	=	' 		+	DBO.SPU_ToString(@CaseId)
							+ ', LogDesc	=	' 	+	DBO.SPU_ToString(@LogDesc)
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
