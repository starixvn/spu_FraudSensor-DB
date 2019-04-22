USE [bodb_FraudSensor]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[FS_DelayGoalAccount_GetManualAccount]
AS
/*
	Created: 20180409@CaseyHuynh
	Task :  Return Manual Account that is Active
	DB: bodb_FraudSensor
	Original: 

	Revisions:

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON;
	
	--1: Return Active Manaual Account (Custid)
	SELECT dga.custid 
	FROM DelayGoalAccount dga WITH(NOLOCK)
	WHERE dga.IsManualAdd = 1 and dga.IsActive =1
END;

/*
GO
GRANT EXECUTE ON [dbo].[FS_DelayGoalAccount_GetManualAccount] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[FS_DelayGoalAccount_GetManualAccount] TO [bodbSPUNet]
GO
*/