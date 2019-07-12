ALTER PROCEDURE [dbo].[FS_Rpt_CheckBetNote_Update]
		@UserId				INT
	,	@TransIds			NVARCHAR(MAX)
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
		-	20190710@John.Ngo:	Check Bet - Allow copy Note to all tickets [Redmine ID: #116619]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON;	
	
    DECLARE @LogID INT
		,	@TransId BIGINT
		,	@LogData VARCHAR(500)
		,	@SPName VARCHAR(100);

	IF OBJECT_ID('tempdb..#tmpTransId') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpTransId;
	END;
	
	CREATE TABLE #tmpTransId (
			TransId		BIGINT
	 );

	CREATE CLUSTERED INDEX #CIX_tmpTransId_TransId ON #tmpTransId (
			TransId			ASC
	);

	--INSERT INTO #tmpTransId(TransId)
	INSERT INTO #tmpTransId(TransID)
	SELECT VAL FROM dbo.SPU_StrSplit(@TransIds, ',');	

	BEGIN TRY
	WHILE	EXISTS (SELECT TOP(1) 1 FROM #tmpTransId WITH (NOLOCK))
		BEGIN
		SELECT TOP(1) @TransId = TransId FROM #tmpTransId WITH (NOLOCK) 
			IF NOT EXISTS(SELECT TOP(1) 1 FROM dbo.CheckBetNote WITH(NOLOCK) WHERE TransId = @TransId)
				BEGIN				
					INSERT INTO dbo.CheckBetNote (TransId, Note, CreatedDate, CreatedBy) 
					VALUES(@TransId, @Note, GETDATE(), @UserId);
				
					DELETE #tmpTransId WHERE TransId = @TransId
				
					------------ Write Log ------------ 		
					SELECT @LogID = 24;
					SELECT @LogData = 'TransId=' + DBO.SPU_ToString(@TransId) +';
						   Note=' + @Note
					SELECT @SPName = OBJECT_NAME(@@ProcID);

					EXEC [dbo].[FS_UserLog_Insert]  
							@LogTypeId		= @LogID   
						,	@UserId			= @UserId  
						,	@SPName			= @SPName
						,	@Details		= @LogData;

				END
			ELSE
				BEGIN
					UPDATE	dbo.CheckBetNote WITH (ROWLOCK)
					SET		Note = @Note
					WHERE	TransId = @TransId;
				
					DELETE #tmpTransId WHERE TransId = @TransId
								
					------------ Write Log ------------ 		
					SELECT @LogID = 25;		
					SELECT @LogData = 'TransId=' + DBO.SPU_ToString(@TransId) +';
						   Note=' + @Note
					SELECT @SPName = OBJECT_NAME(@@ProcID);

					EXEC [dbo].[FS_UserLog_Insert]  
							@LogTypeId		= @LogID   
						,	@UserId			= @UserId  
						,	@SPName			= @SPName
						,	@Details		= @LogData;
				END;
		END;
	END TRY
	BEGIN CATCH
		SET @ErrCode = ERROR_NUMBER();
	END CATCH;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
