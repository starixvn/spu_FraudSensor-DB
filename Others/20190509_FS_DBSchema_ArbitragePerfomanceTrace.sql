/*
Creator: 20190509@GiangHuynh	
Task:  Write Log to trace Issue Perfomance and Data wrong
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

USE	bodb_FraudSensor;
GO
----===================A. DROP TABLES=========================
----==========================================================


----===================B. CREATE TABLES========================
----===========================================================
CREATE TABLE dbo.Trace_Log(
	TraceId			INT IDENTITY PRIMARY KEY
	, TraceGroup	INT
	, SPName		VARCHAR(200)
	, StepId		TINYINT
	, StartTime		DATETIME
	, EndTime		DATETIME
	, StepDesc		NVARCHAR(200)
	, LogInfo		NVARCHAR(500)
) ON DATA;

----===================C. ALTER TABLES=========================
----===========================================================

---=======Trace Log Info: Start=========================

	---=======Trace Log Info: End  =========================