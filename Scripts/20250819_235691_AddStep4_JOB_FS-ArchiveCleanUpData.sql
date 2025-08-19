/*
Creator: 20250819@John.Ngo
Task: Clean data for Fraud Sensor [RedmineID: #235691]
Server:  DB052/DB053

Reviewer: Sol
*/ 

USE [msdb]
GO

BEGIN TRANSACTION

/****** Object:  Add New Step [04.ArchiveData_OddsLogAndCapturedData] ******/
EXEC msdb.dbo.sp_add_jobstep 
    @job_name = N'FS-ArchiveCleanUpData',
    @step_name = N'04.ArchiveData_OddsLogAndCapturedData', 
    @step_id = 4, 
    @cmdexec_success_code = 0, 
    @on_success_action = 1,
    @on_success_step_id = 0, 
    @on_fail_action = 2,  -- Quit with failure
    @on_fail_step_id = 0, 
    @retry_attempts = 0, 
    @retry_interval = 0, 
    @os_run_priority = 0, 
    @subsystem = N'TSQL', 
    @command = N'EXECUTE FS_Task_ArchiveData_OddsLogAndCapturedData;', 
    @database_name = N'bodb_FraudSensor', 
    @flags = 0

-- Update the job so step 3 goes to step 4 on success
EXEC msdb.dbo.sp_update_jobstep 
    @job_name = N'FS-ArchiveCleanUpData',
    @step_id = 3,
    @on_success_action = 3  -- Go to next step

COMMIT TRANSACTION
GO

/*<info serverAlias="DBFS-bodb_FraudSensor"></info>*/