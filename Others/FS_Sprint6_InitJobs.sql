/*
Creator: 20180503@LongLuu
Task:  Create jobs for Fraud Sensor - Sprint#6
Server:  bodb_FraudSensor

Reviewer: Billy
*/ 

USE	msdb;
GO

EXECUTE msdb.dbo.sp_add_job
		@job_name = N'FS-Get Tickets By IP',
		@owner_login_name = N'sputeam',
		@description = N'Get all latest Tickets By IP from bodb02.bettrans',
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
		@job_name = N'FS-Get Tickets By IP',
		@step_id = 1,
		@step_name = N'01.Get tickets by IP',
		@subsystem = N'TSQL',
		@command = N'exec dbo.FS_Task_TicketsGetByIP',
		@database_name = N'bodb_FraudSensor',
		@on_success_action = 1,
		@on_fail_action = 2;
GO

EXECUTE sp_add_jobschedule
		@job_name = N'FS-Get Tickets By IP',
		@name = N'FS_Get Tickets By IP-Schedule',
        @freq_type = 4,
        @freq_interval = 1, 
        @freq_subday_type = 0x4, 
        @freq_subday_interval = 60, 
        @freq_relative_interval = 0,
		@active_start_date = 20180505,		
        @active_end_date = 99991231,
		@active_start_time = 120000;
GO
/*
EXECUTE	msdb.dbo.sp_update_jobschedule
		@job_name = N'FS-Get Tickets By IP',
		@name = N'FS_Get Tickets By IP_Schedule',
        @freq_type = 4,
        @freq_interval = 1, 
        @freq_subday_type = 0x2, 
        @freq_subday_interval = 3600,
        @freq_relative_interval = 0;
*/
------------------------------------------------------------------------
EXECUTE msdb.dbo.sp_add_job
		@job_name = N'FS-Remove Unused Data',
		@owner_login_name = N'sputeam',
		@description = N'Remove unused data',
		@category_name = N'',
		@enabled = 1,
		@notify_level_email = 2,
		@notify_level_page = 0,
		@notify_level_netsend = 0,
		@notify_level_eventlog = 0,
		@delete_level= 0,
		@notify_email_operator_name = N'';
GO

EXECUTE	msdb.dbo.sp_add_jobstep
		@job_name			= N'FS-Remove Unused Data',
		@step_id			= 1,
		@step_name			= N'01.Remove tickets before BalanceUp',
		@subsystem			= N'TSQL',
		@command			= N'EXECUTE	FS_Task_TicketsRemoveBeforeBalanceUp;',
		@database_name		= N'bodb_FraudSensor',
		@on_success_action	= 3,
		@on_fail_action		= 2;
GO

EXECUTE	msdb.dbo.sp_add_jobstep
		@job_name			= N'FS-Remove Unused Data',
		@step_id			= 2,
		@step_name			= N'02.Remove UserLogs within 7 latest days',
		@subsystem			= N'TSQL',
		@command			= N'EXECUTE FS_Task_UserLogsRemove;',
		@database_name		= N'bodb_FraudSensor',
		@on_success_action	= 1,
		@on_fail_action		= 2;
GO

EXECUTE sp_add_jobschedule
		@job_name = N'FS-Remove Unused Data',
		@name = N'FS-Remove Unused Data-Schedule',
        @freq_type = 8,
        @freq_interval = 32, 
        @freq_subday_type = 0, 
        @freq_subday_interval = 0, 
        @freq_relative_interval = 0,
		@freq_recurrence_factor = 1,
		@active_start_date = 20180505,		
        @active_end_date = 99991231,
		@active_start_time = 40000;
GO