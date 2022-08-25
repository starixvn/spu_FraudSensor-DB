/*
Creator: 20220810@John.Ngo
Task: FS - Scale Out DBTrans [RedmineID: #176471]
Server:  bodb_FraudSensor
Revision:

Reviewer: Patrick
*/ 

USE bodb_FraudSensor;

UPDATE tp WITH(ROWLOCK, UPDLOCK)
	SET tp.SequenceID = b.SequenceID
FROM dbo.TicketsByIP AS tp
	INNER JOIN bodb02.dbo.bettrans b WITH (NOLOCK) ON b.transid = tp.TransId
WHERE tp.TransId >= 115971572029;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor"></info>*/
