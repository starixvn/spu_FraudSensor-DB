ALTER PROCEDURE [dbo].[FS_Footprint_GetAssociationsByCustId]
	@CustId			INT = 0
AS
/*
	Created: 20191226@Long.Luu
	Task : Get footprint's associations by custid
	DB: bodb_FraudSensor

	Original:

	Revisions: 
		+ 20191226@Long.Luu: Created [Redmine ID: 125983]

	Param's Explanation (filtered by):
*/

BEGIN
	SET NOCOUNT ON;	

	IF	OBJECT_ID('tempdb..#tmpAssociatedCustId') IS NOT NULL
	BEGIN
		DROP TABLE #tmpAssociatedCustId;
	END;

	CREATE TABLE	#tmpAssociatedCustId (
			CustId			INT NOT NULL
		,	DateCreated		DATETIME NOT NULL
		,	PRIMARY KEY CLUSTERED (DateCreated, CustId)	
	);

	;WITH cte AS
	(
		SELECT f.CustId, f.DateCreated,
				ROW_NUMBER() OVER (PARTITION BY f.CustId ORDER BY f.DateCreated DESC) AS rn
		FROM dbo.FootprintHistory AS f WITH(NOLOCK)
			INNER JOIN	(
						SELECT DISTINCT FootprintId
						FROM dbo.FootprintHistory AS f1 WITH(NOLOCK)
						WHERE f1.CustId = @CustId
					) AS temp ON temp.FootprintId = f.FootprintId
	)
	INSERT INTO #tmpAssociatedCustId(CustId, DateCreated)
    SELECT	CustId, DateCreated
	FROM cte
	WHERE cte.rn = 1;

	SELECT	a.CustId
		,	c.username AS Username
		,	c.username2 AS Username2
		,	a.DateCreated AS CreatedDate
	FROM #tmpAssociatedCustId AS a WITH(NOLOCK)
		INNER JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON a.CustId = c.custid
	ORDER BY a.DateCreated DESC;
END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
