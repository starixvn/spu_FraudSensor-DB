USE bodb_FraudSensor
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
ALTER PROCEDURE dbo.FS_Tbl_OfficeIP_Delete
	@UserId		INT
	, @IPRange		VARCHAR(11)
	, @FromNumber	SMALLINT
	, @ToNumber		SMALLINT
	, @ErrCode		INT	= 0		OUTPUT
AS
/*
	Created: 20180605@CaseyHuynh
	Task : Delete Office IP
	DB: bodb_FraudSensor

	Original:

	Revisions: 

	Param's Explanation (filtered by):
	 + @IPRange: a first three part of IP Address
	 + @FromNumber: from 0 to 255
	 + @ToNumber: from 0 to 255	
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @LogTypeId		INT	= 16
			, @LogData		VARCHAR(500)
			, @SPName		VARCHAR(100);	

	IF EXISTS (SELECT TOP(1) 1 FROM dbo.OfficeIP WITH(NOLOCK) WHERE IPRange = @IPRange AND FromNumber = @FromNumber AND ToNumber = @ToNumber)
	BEGIN
		BEGIN TRY	
			DELETE dbo.OfficeIP WITH(ROWLOCK)
			WHERE IPRange = @IPRange AND FromNumber = @FromNumber AND ToNumber = @ToNumber;			
		END TRY
		BEGIN CATCH
			SELECT @ErrCode	= ERROR_NUMBER();
			IF (@ErrCode = 2627)
				SELECT @ErrCode = 0;
		END CATCH;
		--================ Write Log ================ 
		IF (@ErrCode = 0) 
		BEGIN
			SELECT @LogData =	'@UserId = '			+	DBO.SPU_ToString(@UserId)  
								+ ', IPRange = ' 	+	DBO.SPU_ToString(@IPRange) 
								+ ', FromNumber = ' 		+	DBO.SPU_ToString(@FromNumber)
								+ ', ToNumber = ' 	+	DBO.SPU_ToString(@ToNumber);

			SELECT @SPName	=	OBJECT_NAME(@@ProcID);

			EXEC [dbo].[FS_UserLog_Insert]  
					@LogTypeId	=	@LogTypeId   
				,	@UserId		=	@UserId  
				,	@SPName		=	@SPName
				,	@Details	=	@LogData;
		END;
	END;	
END;
GO 
 GRANT EXECUTE ON dbo.FS_Tbl_OfficeIP_Delete TO bodbSPUNet;
GO 
 GRANT VIEW DEFINITION ON dbo.FS_Tbl_OfficeIP_Delete TO bodbSPUNet;
GO 