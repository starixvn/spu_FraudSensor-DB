ALTER PROCEDURE [dbo].[FS_Rpt_ChangedMatchNote_Update]
		@UserId				INT
	,	@MatchIds			NVARCHAR(MAX)
	,	@Note				NVARCHAR(500)

	,	@ErrCode			INT = 0 OUTPUT
AS
/*
	Created: 20191010@Long.Luu
	Task : Support Editting Note for Daily Data Monitoring report
	DB: DB054.BODB02_FraudSensor
	Original:

	Revisions:
		-	20191010@Long.Luu:	Created [Redmine ID: #120481]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON;	
	
    DECLARE @LogID		INT
		,	@MatchId	INT
		,	@LogData	VARCHAR(500)
		,	@SPName		VARCHAR(100);

	IF OBJECT_ID('tempdb..#tmpMatch') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatch;
	END;
	
	CREATE TABLE #tmpMatch (
			MatchId		INT PRIMARY KEY
	 );

	--INSERT INTO #tmpMatch(TransId)
	INSERT INTO #tmpMatch(MatchId)
	SELECT VAL FROM dbo.SPU_StrSplit(@MatchIds, ',');	

	BEGIN TRY
	WHILE	EXISTS (SELECT TOP(1) 1 FROM #tmpMatch WITH (NOLOCK))
		BEGIN
			SELECT TOP(1) @MatchId = MatchId 
			FROM #tmpMatch WITH (NOLOCK);

			UPDATE dbo.ChangedMatch WITH(ROWLOCK, UPDLOCK)
			SET Note = @Note
			WHERE MatchId = @MatchId;		
				
			DELETE #tmpMatch 
			WHERE MatchId = @MatchId;
				
			------------ Write Log ------------ 		
			SELECT @LogID = 26;
			SELECT @LogData = 'MatchId=' + DBO.SPU_ToString(@MatchId) +';
					Note=' + @Note
			SELECT @SPName = OBJECT_NAME(@@ProcID);

			EXEC [dbo].[FS_UserLog_Insert]  
					@LogTypeId		= @LogID   
				,	@UserId			= @UserId  
				,	@SPName			= @SPName
				,	@Details		= @LogData;
		END;
	END TRY
	BEGIN CATCH
		SET @ErrCode = ERROR_NUMBER();
	END CATCH;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
