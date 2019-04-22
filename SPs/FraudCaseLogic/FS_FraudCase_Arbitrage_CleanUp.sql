USE [bodb_FraudSensor]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[FS_FraudCase_Arbitrage_CleanUp] 
	@Matches			VARCHAR(MAX) = NULL -- xml format
AS
/*
	Created: 20180816@Long
	Task : Clean up cached data for Arbitrage fraud case
	DB: bodb_FraudSensor
	Original:

	Revisions:

	Param's Explanation (filtered by):
*/
BEGIN
	SET NOCOUNT ON;	
	
	IF OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatches;
	END

	CREATE TABLE #tmpMatches
	(
			MatchId				INT
		,	BetType				INT
		,	Handicap			MONEY
		,	TotalScore			INT
	);
	
	CREATE NONCLUSTERED INDEX	#NCIX_tmpMatches ON #tmpMatches (
			MatchId				ASC
		,	BetType				ASC
		,	Handicap			ASC
		,	TotalScore			ASC
	);

	DECLARE @idocMatch INT;

	--Create an internal representation of the XML document
	EXEC sp_xml_preparedocument @idocMatch OUTPUT, @Matches;

	-- Execute a SELECT statement that uses the OPENXML rowset provider
	INSERT INTO #tmpMatches (MatchId, BetType, Handicap, TotalScore)
	SELECT	Data.MatchId
		,	Data.BetType
		,	Data.Handicap
		,	Data.TotalScore
	FROM OPENXML(@idocMatch, '/Root/Match', 2) WITH (
			MatchId INT '@MatchId'
		,	BetType INT	'@Bettype'
		,	Handicap MONEY '@Handicap'
		,	TotalScore INT '@TotalScore'
	) AS Data;	

	SELECT m.MatchId, m.BetType, m.Handicap, m.TotalScore
	FROM #tmpMatches AS m WITH(NOLOCK)
	EXCEPT
	SELECT DISTINCT ms.MatchId, ms.BetType, ms.Handicap, ms.TotalScores
	FROM [dbo].[ArbitrageMatchScoreHDP] AS ms WITH(NOLOCK)
	WHERE ms.HasScanned = 0;

	DELETE FROM [dbo].[ArbitrageMatchScoreHDP]
	WHERE MatchId IN	(
							SELECT m.MatchId, m.BetType, m.Handicap, m.TotalScore
							FROM #tmpMatches AS m WITH(NOLOCK)
							EXCEPT
							SELECT DISTINCT ms.MatchId, ms.BetType, ms.Handicap, ms.TotalScores
							FROM [dbo].[ArbitrageMatchScoreHDP] AS ms WITH(NOLOCK)
							WHERE ms.HasScanned = 0
						);	
END;

GO 
 GRANT EXECUTE ON [dbo].[FS_FraudCase_Arbitrage_CleanUp] TO [bodbSPUNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[FS_FraudCase_Arbitrage_CleanUp] TO [bodbSPUNet]
GO 
