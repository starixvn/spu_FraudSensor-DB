ALTER PROCEDURE [dbo].[VRModel_Sportsbook_Soccer_4_BuildDataTrend]
AS
/*
	Created: 20200212@Long.Luu
	Task : 
	DB: bodb_FraudSensor
	Original:

	Revisions:
		- 20200212@Long.Luu: Created [Redmine ID: #127584]

	Param's Explanation:
*/
BEGIN

	SET NOCOUNT ON;

	-- Calc Slope and Intercept from the raw ChangeOfDanger table
	TRUNCATE TABLE dbo.[VR2Model_HorizontalSlopeIntercept];
	TRUNCATE TABLE dbo.[VR2Model_VerticalSlopeInterceptWinner];
	TRUNCATE TABLE dbo.[VR2Model_VerticalSlopeInterceptLoser];
	TRUNCATE TABLE dbo.[VR2Model_ChanceOfDangerSmoothHorizontal];
	TRUNCATE TABLE dbo.[VR2Model_ChanceOfDangerSmoothVertical];
	
	INSERT INTO dbo.[VR2Model_HorizontalSlopeIntercept](MarginRange, Slope, Intercept)
	SELECT	c.MarginRange
		,	SUM((LOG(c.WeekOrder) - c.AVG_WeekOrder) * (c.PercentageOfWin - c.AVG_PercentageOfWin))/SUM(POWER(LOG(c.WeekOrder) - c.AVG_WeekOrder, 2)) 
		,	AVG(c.PercentageOfWin) - SUM((LOG(c.WeekOrder) - c.AVG_WeekOrder) * (c.PercentageOfWin - c.AVG_PercentageOfWin))/SUM(POWER(LOG(c.WeekOrder) - c.AVG_WeekOrder, 2)) * AVG(LOG(c.WeekOrder))		
	FROM (
		SELECT	t.MarginRange
			,	t.WeekOrder
			,	t.PercentageOfWin
			,	[AVG_WeekOrder] = AVG(LOG(t.WeekOrder)) OVER (PARTITION BY t.MarginRange)
			,	[AVG_PercentageOfWin] = AVG(t.PercentageOfWin)  OVER (PARTITION BY t.MarginRange)
		FROM dbo.[VR2Model_RawChanceOfDanger] AS t WITH(NOLOCK)
		WHERE t.MarginRange <> 0
	) AS c
	GROUP BY c.MarginRange;

	INSERT INTO dbo.[VR2Model_HorizontalSlopeIntercept](MarginRange, Slope, Intercept)
	SELECT	c.MarginRange
		,	SUM((c.WeekOrder - c.AVG_WeekOrder_NoLN) * (c.PercentageOfWin - c.AVG_PercentageOfWin))/SUM(POWER(c.WeekOrder - c.AVG_WeekOrder_NoLN, 2))
		,	AVG(c.PercentageOfWin) - AVG(c.WeekOrder) * SUM((c.WeekOrder - c.AVG_WeekOrder_NoLN) * (c.PercentageOfWin - c.AVG_PercentageOfWin))/SUM(POWER(c.WeekOrder - c.AVG_WeekOrder_NoLN, 2))
	FROM (
		SELECT	t.MarginRange
			,	t.WeekOrder
			,	t.PercentageOfWin
			,	[AVG_WeekOrder] = AVG(LOG(t.WeekOrder)) OVER (PARTITION BY t.MarginRange)
			,	[AVG_WeekOrder_NoLN] = AVG(t.WeekOrder) OVER (PARTITION BY t.MarginRange)
			,	[AVG_PercentageOfWin] = AVG(t.PercentageOfWin)  OVER (PARTITION BY t.MarginRange)
		FROM dbo.[VR2Model_RawChanceOfDanger] AS t WITH(NOLOCK)
		WHERE t.MarginRange = 0
	) AS c
	GROUP BY c.MarginRange;

	INSERT INTO dbo.[VR2Model_VerticalSlopeInterceptWinner](WeekOrder, Slope, Intercept)
	SELECT	c.WeekOrder
		,	 SUM((c.PercentageOfWin - c.AVG_PercentageOfWin) * (LOG(c.MarginRange) - c.AVG_MarginRange))/SUM(POWER(LOG(c.MarginRange) - c.AVG_MarginRange, 2)) 
		,	 AVG((c.PercentageOfWin)) - SUM((c.PercentageOfWin - c.AVG_PercentageOfWin) * (LOG(c.MarginRange) - c.AVG_MarginRange))/SUM(POWER(LOG(c.MarginRange) - c.AVG_MarginRange, 2)) * AVG(LOG(c.MarginRange)) 
	FROM (
		SELECT	t.MarginRange
			,	t.WeekOrder
			,	t.PercentageOfWin
			,	[AVG_MarginRange] = AVG(LOG(t.MarginRange)) OVER (PARTITION BY t.WeekOrder)
			,	[AVG_PercentageOfWin] = AVG(t.PercentageOfWin)  OVER (PARTITION BY t.WeekOrder)
		FROM dbo.[VR2Model_RawChanceOfDanger] AS t WITH(NOLOCK)
		WHERE t.MarginRange > 0 
	) AS c
	GROUP BY c.WeekOrder;

	INSERT INTO dbo.[VR2Model_VerticalSlopeInterceptLoser](WeekOrder, Slope, Intercept)
	SELECT	c.WeekOrder
		,	 SUM((c.PercentageOfWin - c.AVG_PercentageOfWin) * (LOG(-c.MarginRange) - c.AVG_MarginRange))/SUM(POWER(log(-c.MarginRange) - c.AVG_MarginRange, 2)) 
		,	 AVG((c.PercentageOfWin)) - SUM((c.PercentageOfWin - c.AVG_PercentageOfWin) * (LOG(-c.MarginRange) - c.AVG_MarginRange))/SUM(POWER(LOG(-c.MarginRange) - c.AVG_MarginRange, 2)) * AVG(LOG(-c.MarginRange)) 
	FROM (
		SELECT	t.MarginRange
			,	t.WeekOrder
			,	t.PercentageOfWin
			,	[AVG_MarginRange] = AVG(LOG(-t.MarginRange)) OVER (PARTITION BY t.WeekOrder)
			,	[AVG_PercentageOfWin] = AVG(t.PercentageOfWin)  OVER (PARTITION BY t.WeekOrder)
		FROM dbo.[VR2Model_RawChanceOfDanger] AS t WITH(NOLOCK)
		WHERE t.MarginRange < 0
	) AS c
	GROUP BY c.WeekOrder;

	-- Create Smoothing tables
	INSERT INTO dbo.[VR2Model_ChanceOfDangerSmoothHorizontal](MarginRange, WeekOrder, PercentageOfWin)
	SELECT	r.MarginRange
		,	r.WeekOrder
		,	(h.Slope * LOG(r.WeekOrder) + h.Intercept)
	FROM dbo.[VR2Model_RawChanceOfDanger] AS r WITH(NOLOCK)
		INNER JOIN dbo.[VR2Model_HorizontalSlopeIntercept] AS h WITH(NOLOCK) ON r.MarginRange = h.MarginRange
	WHERE r.MarginRange <> 0;

	INSERT INTO dbo.[VR2Model_ChanceOfDangerSmoothHorizontal](MarginRange, WeekOrder, PercentageOfWin)
	SELECT	r.MarginRange
		,	r.WeekOrder
		,	(h.Slope * (r.WeekOrder) + h.Intercept)
	FROM dbo.[VR2Model_RawChanceOfDanger] AS r WITH(NOLOCK)
		INNER JOIN dbo.[VR2Model_HorizontalSlopeIntercept] AS h WITH(NOLOCK) ON r.MarginRange = h.MarginRange
	WHERE r.MarginRange = 0;

	INSERT INTO dbo.[VR2Model_ChanceOfDangerSmoothVertical](MarginRange, WeekOrder, PercentageOfWin)
	SELECT	r.MarginRange
		,	r.WeekOrder
		,	(w.Slope * LOG(r.MarginRange) + w.Intercept)
	FROM dbo.[VR2Model_RawChanceOfDanger] AS r WITH(NOLOCK)
		INNER JOIN dbo.[VR2Model_VerticalSlopeInterceptWinner] AS w WITH(NOLOCK) ON r.WeekOrder = w.WeekOrder
	WHERE r.MarginRange > 0;

	INSERT INTO dbo.[VR2Model_ChanceOfDangerSmoothVertical](MarginRange, WeekOrder, PercentageOfWin)
	SELECT	h.MarginRange
		,	h.WeekOrder
		,	h.PercentageOfWin
	FROM dbo.[VR2Model_ChanceOfDangerSmoothHorizontal] AS h WITH(NOLOCK)
	WHERE h.MarginRange = 0;

	INSERT INTO dbo.[VR2Model_ChanceOfDangerSmoothVertical](MarginRange, WeekOrder, PercentageOfWin)
	SELECT	r.MarginRange
		,	r.WeekOrder
		,	(l.Slope * LOG(-r.MarginRange) + l.Intercept)
	FROM dbo.[VR2Model_RawChanceOfDanger] AS r WITH(NOLOCK)
		INNER JOIN dbo.[VR2Model_VerticalSlopeInterceptLoser] AS l WITH(NOLOCK) ON r.WeekOrder = l.WeekOrder
	WHERE r.MarginRange < 0;

END;

/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/