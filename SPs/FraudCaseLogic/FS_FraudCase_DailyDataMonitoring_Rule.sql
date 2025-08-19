ALTER PROCEDURE [dbo].[FS_FraudCase_DailyDataMonitoring_Rule]
		@IsManual		BIT = 0
AS
/*
	Created: 20180607@LONG
	Task : Rule for Daily Data Monitoring fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions:	
		- 20190627@John.Ngo: Data Daily Monitor - Detect the changes within 7 days instead of 3 days [Redmine ID: 115780]
		- 20250808@John.Ngo: Only keep data 'CapturedData' within 7 days [Redmine ID: #235691]
		- 20250819@John.Ngo: Separate the archive table 'CapturedDate' [Redmine ID: #235691]

	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	

	DECLARE @NewCapturedDate		DATETIME
		,	@OldCapturedDate		DATETIME
		,	@CaptureDate			DATETIME
		,	@Today					DATE
		,	@TotalChangedMatches	INT
		,	@StoredMessageId		INT
		,	@CurrentFraudCaseId		INT;

	SELECT	@CaptureDate = GETDATE()
		,	@Today = @CaptureDate
		,	@CurrentFraudCaseId = 4;
			
	IF	OBJECT_ID('tempdb..#tmpMatchesData') IS NOT NULL
	BEGIN;
		DROP TABLE #tmpMatchesData;
	END;

	CREATE TABLE	#tmpMatchesData (
		[MatchId]					INT NOT NULL,
		[TotalCompanyTO]			MONEY NULL,
		[TotalSuperTO]				MONEY NULL,
		[TotalMasterTO]				MONEY NULL,
		[TotalAgentTO]				MONEY NULL,
		[TotalTickets]				INT NULL,
		[TotalSettledTickets]		INT NULL,
		[TotalCancelledTickets]		INT NULL,
		[CapturedDate]				DATETIME NULL
	);

	CREATE CLUSTERED INDEX	#CIX_tmpMatchesData_MatchId ON #tmpMatchesData (
		[MatchId]					ASC
	);

	IF	OBJECT_ID('tempdb..#tmpMatchesOldData') IS NOT NULL
	BEGIN;
		DROP TABLE #tmpMatchesOldData;
	END;

	CREATE TABLE	#tmpMatchesOldData (
		[MatchId]					INT NOT NULL,
		[TotalCompanyTO]			MONEY NULL,
		[TotalSuperTO]				MONEY NULL,
		[TotalMasterTO]				MONEY NULL,
		[TotalAgentTO]				MONEY NULL,
		[TotalTickets]				INT NULL,
		[TotalSettledTickets]		INT NULL,
		[TotalCancelledTickets]		INT NULL
	);

	CREATE CLUSTERED INDEX	#CIX_tmpMatchesOldData_MatchId ON #tmpMatchesOldData (
		[MatchId]					ASC
	);

	IF	OBJECT_ID('tempdb..#tmpMatchesNewData') IS NOT NULL
	BEGIN;
		DROP TABLE #tmpMatchesNewData;
	END;

	CREATE TABLE	#tmpMatchesNewData (
		[MatchId]					INT NOT NULL,
		[TotalCompanyTO]			MONEY NULL,
		[TotalSuperTO]				MONEY NULL,
		[TotalMasterTO]				MONEY NULL,
		[TotalAgentTO]				MONEY NULL,
		[TotalTickets]				INT NULL,
		[TotalSettledTickets]		INT NULL,
		[TotalCancelledTickets]		INT NULL
	);

	CREATE CLUSTERED INDEX	#CIX_tmpMatchesNewData_MatchId ON #tmpMatchesNewData (
		[MatchId]					ASC
	);

	SELECT @NewCapturedDate = MAX(cd.CapturedDate)
	FROM dbo.CapturedData AS cd WITH(NOLOCK);

	IF	OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
	BEGIN;
		DROP TABLE #tmpMatches;
	END;

	CREATE TABLE	#tmpMatches (
			MatchId				INT
	);

	CREATE CLUSTERED INDEX	#CIX_tmpMatchesIdx ON #tmpMatches (
			MatchId				ASC
	);
		
	-------- REMOVE TODAY's DATA IN CASE ACCIDENTIALLY RUN MORE THAN 1 TIME PER DAY --------
	DELETE FROM dbo.ChangedMatch WITH(ROWLOCK)
	WHERE CapturedDate >= @Today
		AND CapturedDate < DATEADD(DAY, 1, @Today);

	SELECT @StoredMessageId = m.MessageId
	FROM dbo.Message AS m WITH(NOLOCK)
	WHERE m.LogDate >= @Today		
		AND m.LogDate < DATEADD(DAY, 1, @Today)
		AND m.FraudCaseId = @CurrentFraudCaseId;

	DELETE FROM dbo.Message WITH(ROWLOCK)
	WHERE MessageId = @StoredMessageId;

	DELETE FROM dbo.UserMessage WITH(ROWLOCK)
	WHERE MessageId = @StoredMessageId;
	
	-------- START --------
	IF @IsManual = 0
	BEGIN
		SELECT @NewCapturedDate = MAX(cd.CapturedDate)
		FROM dbo.CapturedData AS cd WITH(NOLOCK);

		SELECT @OldCapturedDate = MAX(cd.CapturedDate)
		FROM dbo.CapturedData AS cd WITH(NOLOCK)
		WHERE cd.CapturedDate <> @NewCapturedDate;

		INSERT INTO #tmpMatchesData(MatchId, TotalCompanyTO, TotalSuperTO, TotalMasterTO, TotalAgentTO, TotalTickets, TotalSettledTickets, TotalCancelledTickets, CapturedDate)
		SELECT	[MatchId]					= cd.matchid
			,	[TotalCompanyTO]			= cd.TotalCompanyTO
			,	[TotalSuperTO]				= cd.TotalSuperTO
			,	[TotalMasterTO]				= cd.TotalMasterTO
			,	[TotalAgentTO]				= cd.TotalAgentTO
			,	[TotalTickets]				= cd.TotalTickets
			,	[TotalSettledTickets]		= cd.TotalSettledTickets
			,	[TotalCancelledTickets]		= cd.TotalCancelledTickets
			,	[CapturedDate]				= cd.CapturedDate
		FROM dbo.CapturedData AS cd WITH(NOLOCK)
		WHERE cd.CapturedDate = @OldCapturedDate OR cd.CapturedDate = @NewCapturedDate;

		DELETE FROM #tmpMatchesData WITH(ROWLOCK)
		WHERE MatchId IN
			(
				SELECT MatchId
				FROM #tmpMatchesData WITH(NOLOCK)
				GROUP BY MatchId
				HAVING COUNT(1) < 2
			);

		INSERT INTO #tmpMatchesOldData(MatchId, TotalCompanyTO, TotalSuperTO, TotalMasterTO, TotalAgentTO, TotalTickets, TotalSettledTickets, TotalCancelledTickets)
		SELECT	[MatchId]					= cd.matchid
			,	[TotalCompanyTO]			= cd.TotalCompanyTO
			,	[TotalSuperTO]				= cd.TotalSuperTO
			,	[TotalMasterTO]				= cd.TotalMasterTO
			,	[TotalAgentTO]				= cd.TotalAgentTO
			,	[TotalTickets]				= cd.TotalTickets
			,	[TotalSettledTickets]		= cd.TotalSettledTickets
			,	[TotalCancelledTickets]		= cd.TotalCancelledTickets
		FROM #tmpMatchesData AS cd WITH(NOLOCK)
		WHERE cd.CapturedDate = @OldCapturedDate;

		INSERT INTO #tmpMatchesNewData(MatchId, TotalCompanyTO, TotalSuperTO, TotalMasterTO, TotalAgentTO, TotalTickets, TotalSettledTickets, TotalCancelledTickets)
		SELECT	[MatchId]					= cd.matchid
			,	[TotalCompanyTO]			= cd.TotalCompanyTO
			,	[TotalSuperTO]				= cd.TotalSuperTO
			,	[TotalMasterTO]				= cd.TotalMasterTO
			,	[TotalAgentTO]				= cd.TotalAgentTO
			,	[TotalTickets]				= cd.TotalTickets
			,	[TotalSettledTickets]		= cd.TotalSettledTickets
			,	[TotalCancelledTickets]		= cd.TotalCancelledTickets
		FROM #tmpMatchesData AS cd WITH(NOLOCK)
		WHERE cd.CapturedDate = @NewCapturedDate;
	
	END;

	IF @IsManual = 1
	BEGIN
		INSERT INTO #tmpMatches(MatchId)
		SELECT	[MatchId] = cd.matchid
		FROM dbo.CapturedData AS cd WITH(NOLOCK)
		WHERE cd.CapturedDate = @NewCapturedDate;

		INSERT INTO #tmpMatchesData(MatchId, TotalCompanyTO, TotalSuperTO, TotalMasterTO, TotalAgentTO, TotalTickets, TotalSettledTickets, TotalCancelledTickets, CapturedDate)
		SELECT	[MatchId]					= cd.matchid
			,	[TotalCompanyTO]			= cd.TotalCompanyTO
			,	[TotalSuperTO]				= cd.TotalSuperTO
			,	[TotalMasterTO]				= cd.TotalMasterTO
			,	[TotalAgentTO]				= cd.TotalAgentTO
			,	[TotalTickets]				= cd.TotalTickets
			,	[TotalSettledTickets]		= cd.TotalSettledTickets
			,	[TotalCancelledTickets]		= cd.TotalCancelledTickets
			,	[CapturedDate]				= cd.CapturedDate
		FROM dbo.CapturedData AS cd WITH(NOLOCK)
		INNER JOIN #tmpMatches AS m WITH(NOLOCK) on cd.MatchId = m.MatchId
		
		DELETE FROM #tmpMatchesData WITH(ROWLOCK)
		WHERE MatchId IN
			(
				SELECT MatchId
				FROM #tmpMatchesData WITH(NOLOCK)
				GROUP BY MatchId
				HAVING COUNT(1) < 2
			);

		DELETE md FROM #tmpMatchesData AS md WITH(ROWLOCK)
		WHERE md.CapturedDate IN (
				SELECT CapturedDate
				FROM #tmpMatchesData AS t1 WITH(NOLOCK)
				WHERE t1.MatchId = md.MatchId AND t1.CapturedDate <> @NewCapturedDate
					AND t1.CapturedDate <> (SELECT MAX(CapturedDate) FROM #tmpMatchesData AS t2 WITH(NOLOCK)
											WHERE t1.MatchId = t2.MatchId AND t2.CapturedDate <> @NewCapturedDate
											GROUP BY t2.MatchId));

		INSERT INTO #tmpMatchesOldData(MatchId, TotalCompanyTO, TotalSuperTO, TotalMasterTO, TotalAgentTO, TotalTickets, TotalSettledTickets, TotalCancelledTickets)
		SELECT	[MatchId]					= cd.matchid
			,	[TotalCompanyTO]			= cd.TotalCompanyTO
			,	[TotalSuperTO]				= cd.TotalSuperTO
			,	[TotalMasterTO]				= cd.TotalMasterTO
			,	[TotalAgentTO]				= cd.TotalAgentTO
			,	[TotalTickets]				= cd.TotalTickets
			,	[TotalSettledTickets]		= cd.TotalSettledTickets
			,	[TotalCancelledTickets]		= cd.TotalCancelledTickets
		FROM #tmpMatchesData AS cd WITH(NOLOCK)
		WHERE cd.CapturedDate <> @NewCapturedDate

		INSERT INTO #tmpMatchesNewData(MatchId, TotalCompanyTO, TotalSuperTO, TotalMasterTO, TotalAgentTO, TotalTickets, TotalSettledTickets, TotalCancelledTickets)
		SELECT	[MatchId]					= cd.matchid
			,	[TotalCompanyTO]			= cd.TotalCompanyTO
			,	[TotalSuperTO]				= cd.TotalSuperTO
			,	[TotalMasterTO]				= cd.TotalMasterTO
			,	[TotalAgentTO]				= cd.TotalAgentTO
			,	[TotalTickets]				= cd.TotalTickets
			,	[TotalSettledTickets]		= cd.TotalSettledTickets
			,	[TotalCancelledTickets]		= cd.TotalCancelledTickets
		FROM #tmpMatchesData AS cd WITH(NOLOCK)
		WHERE cd.CapturedDate = @NewCapturedDate;
	
	END;

	INSERT INTO dbo.ChangedMatch(MatchId, OldTotalCompanyTO, NewTotalCompanyTO, OldTotalSuperTO, NewTotalSuperTO, OldTotalMasterTO, NewTotalMasterTO, OldTotalAgentTO, NewTotalAgentTO, OldTotalTickets, NewTotalTickets, OldTotalSettledTickets, NewTotalSettledTickets, OldTotalCancelledTickets, NewTotalCancelledTickets, CapturedDate)
	SELECT	[MatchId]					= old.MatchId
		,	[OldTotalCompanyTO]			= old.TotalCompanyTO
		,	[NewTotalCompanyTO]			= new.TotalCompanyTO
		,	[OldTotalSuperTO]			= old.TotalSuperTO
		,	[NewTotalSuperTO]			= new.TotalSuperTO
		,	[OldTotalMasterTO]			= old.TotalMasterTO
		,	[NewTotalMasterTO]			= new.TotalMasterTO
		,	[OldTotalAgentTO]			= old.TotalAgentTO
		,	[NewTotalAgentTO]			= new.TotalAgentTO
		,	[OldTotalTickets]			= old.TotalTickets
		,	[NewTotalTickets]			= new.TotalTickets
		,	[OldTotalSettledTickets]	= old.TotalSettledTickets
		,	[NewTotalSettledTickets]	= new.TotalSettledTickets
		,	[OldTotalCancelledTickets]	= old.TotalCancelledTickets
		,	[NewTotalCancelledTickets]	= new.TotalCancelledTickets
		,	[CapturedDate]				= @CaptureDate
	FROM #tmpMatchesOldData AS old WITH(NOLOCK)
		INNER JOIN #tmpMatchesNewData AS new WITH(NOLOCK) ON old.MatchId = new.MatchId
	WHERE ABS(old.TotalCompanyTO - new.TotalCompanyTO) > 0.1
		OR ABS(old.TotalMasterTO - new.TotalMasterTO) > 0.1
		OR ABS(old.TotalSuperTO - new.TotalSuperTO) > 0.1
		OR ABS(old.TotalAgentTO - new.TotalAgentTO) > 0.1
		OR old.TotalTickets <> new.TotalTickets
		OR old.TotalSettledTickets <> new.TotalSettledTickets
		OR old.TotalCancelledTickets <> new.TotalCancelledTickets;

	-------- LOG MESSAGE --------
	SELECT @TotalChangedMatches = COUNT(DISTINCT cm.MatchId)
	FROM dbo.ChangedMatch AS cm WITH(NOLOCK) 
	WHERE cm.CapturedDate = @CaptureDate;

	IF (@TotalChangedMatches > 0)
	BEGIN
		INSERT INTO dbo.[Message](FraudCaseId, MessageContent, LogDate)
		VALUES(@CurrentFraudCaseId, 'There are ' +  CAST(@TotalChangedMatches AS VARCHAR(5)) + ' matches which having data changes on ' + CONVERT(VARCHAR, @CaptureDate, 107) + ' ' + CONVERT(VARCHAR, @CaptureDate, 108), @CaptureDate);

		DECLARE @NewlyMessageId		INT;
		SELECT @NewlyMessageId = SCOPE_IDENTITY();

		INSERT INTO dbo.UserMessage(UserId, MessageId)
		SELECT	[UserId] = r.RecipientId
			,	[MessageId] = @NewlyMessageId
		FROM dbo.FraudNotificationRecipient AS r WITH(NOLOCK)
		WHERE r.FraudCaseId = @CurrentFraudCaseId;

	END;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="wsv_cts" isFunction="0" isNested="0"></info>*/
