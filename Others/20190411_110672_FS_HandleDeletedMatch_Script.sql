/*
Creator: 20190410@Casey.Huynh
Task:  Handle Deleted Match [Redmine ID: #111454]
Server:  bodb_FraudSensor

Reviewer: Billy
*/
--==============================================

DELETE	d
FROM	dbo.DelayGoalMatchScanning d WITH(NOLOCK)
WHERE	DATEDIFF(DAY, d.eventDate, GETDATE()) > 14

UPDATE	d
SET		d.eventStatus = m.eventStatus
		, d.IsScanCompleted = 0
FROM	dbo.DelayGoalMatchScanning d WITH(NOLOCK)
INNER JOIN	bodb02.dbo.match m WITH(NOLOCK)
			ON	d.MatchId = m.matchid

UPDATE	d
SET		d.eventStatus = 'Completed'
		, d.IsScanCompleted = 1
FROM	dbo.DelayGoalMatchScanning d WITH(NOLOCK)
WHERE	d.eventStatus IS NULL


GO
