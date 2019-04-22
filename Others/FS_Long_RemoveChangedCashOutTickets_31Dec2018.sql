IF OBJECT_ID('tempdb..#tmpChangedTickets') IS NOT NULL
BEGIN
	DROP TABLE	#tmpChangedTickets;
END

CREATE TABLE #tmpChangedTickets
(
	TransId		BIGINT PRIMARY KEY
);

IF OBJECT_ID('tempdb..#tmpChangedTicketsWithExtraInfo') IS NOT NULL
BEGIN
	DROP TABLE	#tmpChangedTicketsWithExtraInfo;
END

CREATE TABLE #tmpChangedTicketsWithExtraInfo
(
	TransId		BIGINT PRIMARY KEY,
	ExtraInfo	NVARCHAR(50)
);

INSERT INTO #tmpChangedTickets(TransId)
SELECT ct.TransId
FROM dbo.ChangedTicket ct WITH(NOLOCK)
WHERE ct.OldValue <> ct.NewValue
GROUP BY ct.TransId
HAVING COUNT(ct.TransId) = 1;

INSERT INTO #tmpChangedTicketsWithExtraInfo(TransId, ExtraInfo)
SELECT ct.TransId, ISNULL(b.ExtraInfo, b14.ExtraInfo)
FROM #tmpChangedTickets ct WITH(NOLOCK)
	LEFT JOIN bodb02.dbo.bettrans b WITH(NOLOCK) ON ct.TransId = b.transid
	LEFT JOIN bodb02.dbo.bettrans14 b14 WITH(NOLOCK) ON ct.TransId = b14.transid;

DELETE FROM #tmpChangedTicketsWithExtraInfo
WHERE ExtraInfo IS NULL OR CAST(ExtraInfo AS XML).exist('/p25/@s') <> 1;

TRUNCATE TABLE #tmpChangedTickets;

INSERT INTO #tmpChangedTickets(TransId)
SELECT DISTINCT TransId
FROM #tmpChangedTicketsWithExtraInfo WITH(NOLOCK);

DELETE FROM dbo.ChangedTicket
WHERE TransId IN (SELECT TransId FROM #tmpChangedTickets WITH(NOLOCK));

DELETE FROM dbo.ChangedTicketGeneralInfo
WHERE TransId IN (SELECT TransId FROM #tmpChangedTickets WITH(NOLOCK));