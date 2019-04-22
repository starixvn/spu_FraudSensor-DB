/*
	Created: 20190109@CaseyHuynh
	Task : CLEAR Table CheckBetScannedMatch. Only Keep data in 14 days
	DB: bodb_FraudSensor
	
	Reviewer: Billy
*/

USE	bodb_FraudSensor;
GO

DECLARE @deleteDate DATE;

IF	OBJECT_ID('tempdb..#temp_ScannedDate') IS NOT NULL
BEGIN
	DROP TABLE	#temp_ScannedDate;
END; 

CREATE TABLE #temp_ScannedDate
(
	ScannedDate DATE PRIMARY KEY
);


INSERT INTO #temp_ScannedDate(ScannedDate)
SELECT DISTINCT c.ScannedDate
FROM dbo.CheckBetScannedMatch c WITH(NOLOCK)
WHERE DATEDIFF(DD, c.ScannedDate, GETDATE()) >= 15;

WHILE EXISTS(SELECT TOP(1) 1 FROM #temp_ScannedDate)
BEGIN
	SELECT TOP(1) @deleteDate = s.ScannedDate 
	FROM #temp_ScannedDate s WITH(NOLOCK);

	DELETE FROM dbo.CheckBetScannedMatch WITH(ROWLOCK)
	WHERE ScannedDate = @deleteDate;

	DELETE FROM	#temp_ScannedDate WITH(ROWLOCK)
	WHERE	ScannedDate = @deleteDate;
END;

