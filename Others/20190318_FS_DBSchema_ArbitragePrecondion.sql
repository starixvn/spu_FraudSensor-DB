/*
Creator: 20190318@Casey
Task:    Implement Scanning Completed Match [Redmine ID: 110566]
Server:  bodb_FraudSensor
*/ 


ALTER TABLE ArbitrageMatchScanning
DROP COLUMN	LiveHomeScore
			,LiveAwayScore
			,MaxTransId

