/*
	Created: 20190109@CaseyHuynh
	Task : CLEAR Table CheckBetScannedMatch. Only Keep data in 14 days
	DB: bodb_FraudSensor
	
	Reviewer: Billy
*/

USE	bodb_FraudSensor;
GO
-------------------------------------------------------------------------------
CREATE TABLE [dbo].[TempTrace_CheckBet] (
	transid				BIGINT, 
	bettype				INT, 
	isCashOut			BIT, 
	isVoid				BIT, 
	custid				INT, 
	matchid				INT, 
	bettrans_stake		MONEY, 
	bets_stake			MONEY, 
	isOriginal			BIT, 
	isValidTP			TINYINT, 
	isValidOdds			TINYINT, 
	isValidBetteam		TINYINT,
	Step				INT,
	TraceTime			DATETIME
) ON [DATA]
GO

CREATE CLUSTERED INDEX CIX_TempTrace_CheckBet_transid_bettype ON [dbo].[TempTrace_CheckBet] (
	transid				ASC,
	bettype				ASC
) ON IDX;
GO
------------------------------------------------------------------------------------------------------
CREATE TABLE [dbo].[TempTrace_ChangedTickets](
	transid				BIGINT, 
	bettype				INT, 
	original_stake		MONEY,
	Step				INT,
	TraceTime			DATETIME
) ON [DATA]
GO

CREATE CLUSTERED INDEX CIX_TempTrace_ChangedTickets_transid_bettype ON [dbo].[TempTrace_ChangedTickets] (
	transid				ASC,
	bettype				ASC
) ON IDX;
GO
------------------------------------------------------------------------------------------------------


