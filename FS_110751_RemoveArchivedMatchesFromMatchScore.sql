/*
Creator: 20190322@Long
Task:    Remove Archived Matches from MatchScore table for not scanning in BSNG [Redmine ID: 110751]
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

DELETE ms WITH(ROWLOCK)
FROM dbo.MatchScore AS ms
	LEFT JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON ms.MatchId = m.matchid
WHERE	ms.HasScanned = 0
	AND m.matchid IS NULL;