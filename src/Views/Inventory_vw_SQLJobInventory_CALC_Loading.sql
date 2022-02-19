CREATE VIEW [App].vw_SQLJobInventory_CALC_Loading

AS

	SELECT
	GETDATE() as CensusDate
	,[sJOB].name JobName
	,[sJOB].job_id
	,[sJOB].enabled
	, [sJOB].start_step_id
	, [sJSTP].step_id
	, [sJSTP].step_name
	, [sJSTP].subsystem
	, [sJSTP].command
	,CASE on_success_action
		WHEN 1 THEN 'Quit with success'
		WHEN 2 THEN 'Quit with failure'
		WHEN 3 THEN 'Go to next step'
		WHEN 4 THEN 'Go to step ' + CAST(on_success_step_id AS VARCHAR(3))
	END On_Success
	, CASE on_fail_action
		WHEN 1 THEN 'Quit with success'
		WHEN 2 THEN 'Quit with failure'
		WHEN 3 THEN 'Go to next step'
		WHEN 4 THEN 'Go to step ' + CAST(on_fail_step_id AS VARCHAR(3))
	END On_Failure
	--
	,[sJOBSCH].schedule_id 
	,CASE freq_type
		WHEN 1   THEN 'One time only'
		WHEN 4   THEN 'Daily'
		WHEN 8   THEN 'Weekly'
		WHEN 16  THEN 'Monthly'
		WHEN 32  THEN 'Monthly'
		WHEN 64  THEN 'Runs when the SQL Server Agent service starts'
		WHEN 128 THEN 'Runs when the computer is idle'
	END AS FrequencyType
	,CASE WHEN freq_type = 32 AND freq_relative_interval <> 0 THEN 
		CASE freq_relative_interval 
		  WHEN 1  THEN 'First'
		  WHEN 2  THEN 'Second'
		  WHEN 4  THEN 'Third'
		  WHEN 8  THEN 'Fourth'
		  WHEN 16 THEN 'Last'
		END
		ELSE 'UNUSED' 
	END Interval
	,CASE freq_type
		WHEN 1 THEN 'Not In Use'
		WHEN 4 THEN 'Every ' + CAST(freq_interval AS VARCHAR(3)) + ' Day(s)'
		WHEN 8 THEN 
							CASE 
									WHEN freq_interval &  1 =  1 THEN  'Sunday'
									WHEN freq_interval &  2 =  2 THEN ', Monday'
									WHEN freq_interval &  4 =  4 THEN ', Tuesday'
									WHEN freq_interval &  8 =  8 THEN ', Wednesday'
									WHEN freq_interval & 16 = 16 THEN ', Thursday'
									WHEN freq_interval & 32 = 32 THEN ', Friday'
									WHEN freq_interval & 64 = 64 THEN ', Saturday'
								END
		WHEN 16 THEN 'On day ' + CAST(freq_interval AS VARCHAR(3)) + ' of the month.'
		WHEN 32 THEN CASE freq_interval
						WHEN 1 THEN 'Sunday'
						WHEN 2 THEN 'Monday'
						WHEN 3 THEN 'Tuesday'
						WHEN 4 THEN 'Wednesday'
						WHEN 5 THEN 'Thursday'
						WHEN 6 THEN 'Friday'
						WHEN 7 THEN 'Saturday'
						WHEN 8 THEN 'Day'
						WHEN 9 THEN 'Weekday'
						WHEN 10 THEN 'Weekend day'
					  END
		WHEN 64 THEN 'Not In Use'
		WHEN 128 THEN 'Not In Use'
	END as [freq_type]
	,CASE WHEN freq_subday_interval <> 0 THEN 
		CASE freq_subday_type
			WHEN 1 THEN 'At ' + CAST(freq_subday_interval AS VARCHAR(3))
			WHEN 2 THEN 'Repeat every ' + CAST(freq_subday_interval  AS VARCHAR(3)) + ' Seconds'
			WHEN 4 THEN 'Repeat every ' + CAST(freq_subday_interval  AS VARCHAR(3)) + ' Minutes'
			WHEN 8 THEN 'Repeat every ' + CAST(freq_subday_interval  AS VARCHAR(3)) + ' Hours'
		END 
		ELSE 'Not In Use'
	END DailyFrequency
	,CASE 
			WHEN freq_type = 8 THEN 'Repeat every ' + CAST(freq_recurrence_factor AS VARCHAR(3)) + ' week(s).'
			WHEN freq_type IN (16,32) THEN 'Repeat every ' + CAST(freq_recurrence_factor AS VARCHAR(3)) + ' month(s).'
			ELSE 'Not In Use'
	END Interval2
	,STUFF(STUFF(RIGHT('00000' + CAST(active_start_time AS VARCHAR(6)),6),3,0,':'),6,0,':')StartTime
	,STUFF(STUFF(RIGHT('00000' + CAST(active_end_time AS VARCHAR(6)),6),3,0,':'),6,0,':') EndTime
	FROM
		[msdb].[dbo].[sysjobs] AS [sJOB]

		LEFT JOIN [msdb].[sys].[servers] AS [sSVR]
			ON [sJOB].[originating_server_id] = [sSVR].[server_id]

		LEFT JOIN [msdb].[dbo].[syscategories] AS [sCAT]
			ON [sJOB].[category_id] = [sCAT].[category_id]

		LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sJSTP]
			ON [sJOB].[job_id] = [sJSTP].[job_id]

		LEFT JOIN [msdb].[sys].[database_principals] AS [sDBP]
			ON [sJOB].[owner_sid] = [sDBP].[sid]

		LEFT JOIN [msdb].[dbo].[sysjobschedules] AS [sJOBSCH]
			ON [sJOB].[job_id] = [sJOBSCH].[job_id]

		LEFT JOIN [msdb].[dbo].[sysschedules] AS [sSCH]
			ON [sJOBSCH].[schedule_id] = [sSCH].[schedule_id]