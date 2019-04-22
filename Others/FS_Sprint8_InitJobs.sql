/*
Creator: 20180607@LongLuu
Task:  Create jobs for Fraud Sensor - Sprint#8
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

USE	msdb;
GO

EXECUTE msdb.dbo.sp_add_job
		@job_name = N'FS-Daily Data Capturing',
		@owner_login_name = N'sputeam',
		@description = N'Daily sum data for each match from bodb02.bettrans',
		@category_name = N'',
		@enabled = 1,
		@notify_level_email = 2,
		@notify_level_page = 0,
		@notify_level_netsend = 0,
		@notify_level_eventlog = 0,
		@delete_level= 0,
		@notify_email_operator_name = N'';
GO

EXECUTE msdb.dbo.sp_add_jobstep 
		@job_name = N'FS-Daily Data Capturing',
		@step_id = 1,
		@step_name = N'01.Capture Data',
		@subsystem = N'TSQL',
		@command = N'exec FS_Task_MatchDailyDataCapture',
		@database_name = N'bodb_FraudSensor',
		@on_success_action = 1,
		@on_fail_action = 2;
GO

EXECUTE sp_add_jobschedule
		@job_name = N'FS-Daily Data Capturing',
		@name = N'FS-Daily Data Capturing-Schedule',
        @freq_type = 4,
        @freq_interval = 1, 
        @freq_subday_type = 0x1, 
        @freq_subday_interval = 0, 
        @freq_relative_interval = 0,
		@active_start_date = 20180607,		
        @active_end_date = 99991231,
		@active_start_time = 010000;
GO