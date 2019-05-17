ALTER PROCEDURE [dbo].[FS_Rpt_CheckBetNote_Update]
		@UserId				INT
	,	@TransId			BIGINT
	,	@Note				NVARCHAR(500)

	,	@ErrCode			INT = 0 OUTPUT
AS
/*
	Created: 20190516@Long.Luu
	Task : Support Editting Note for Checkbet report
	DB: DB052.BODB02_FraudSensor
	Original:

	Revisions:
		-	20190516@Long.Luu:	Created [Redmine ID: #112982]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON;	
	
    DECLARE @LogID INT;
	DECLARE @LogData VARCHAR(500), @SPName VARCHAR(100);

	BEGIN TRY
		IF NOT EXISTS(SELECT TOP(1) 1 FROM dbo.CheckBetNote WITH(NOLOCK) WHERE TransId = @TransId)
		BEGIN				
			INSERT INTO dbo.CheckBetNote (TransId, Note, CreatedDate, CreatedBy) 
			VALUES(@TransId, @Note, GETDATE(), @UserId);
				
			SELECT @LogID = 24;
		END
		ELSE
		BEGIN
			UPDATE	dbo.CheckBetNote WITH (ROWLOCK)
			SET		Note = @Note
			WHERE	TransId = @TransId;
				
			SELECT @LogID = 25;		
		END;
	
		------------ Write Log ------------ 		
		SELECT	@LogData = 'TransId=' + DBO.SPU_ToString(@TransId) +',
				Note=' + @Note
		SELECT @SPName = OBJECT_NAME(@@ProcID);

		EXEC [dbo].[FS_UserLog_Insert]  
				@LogTypeId		= @LogID   
			,	@UserId			= @UserId  
			,	@SPName			= @SPName
			,	@Details		= @LogData;
		END TRY
	BEGIN CATCH
		SET @ErrCode = ERROR_NUMBER();
	END CATCH;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
