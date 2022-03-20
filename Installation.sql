SET NOCOUNT ON

Use [master]

IF DB_ID('RichMonitoring') IS NULL
BEGIN
EXEC ('CREATE DATABASE RichMonitoring')

RAISERROR('0.0 - Database Created',0,1) WITH NOWAIT

END

GO

RAISERROR('0.1 - Changing Database Context',0,1) WITH NOWAIT

Use [RichMonitoring]

DECLARE 
	@Version DECIMAL(16,2),
	@CurVersion DECIMAL(16,2),
	@VersionDate DATE,
	@Command nvarchar(MAX)

SET @Version = '0.3'
SET @VersionDate = '20220320'

/*Create Inventory Schema */
IF SCHEMA_ID('Inventory') IS NULL
BEGIN
	RAISERROR('0.2 - Creating Inventory Schema',0,1) WITH NOWAIT
	EXEC ('CREATE SCHEMA Inventory')
END

/*Create App Schema */
IF SCHEMA_ID('App') IS NULL
BEGIN
	RAISERROR('0.3 - Creating App Schema',0,1) WITH NOWAIT
	EXEC ('CREATE SCHEMA App')
END

/*Create Config Schema */
IF SCHEMA_ID('Config') IS NULL
BEGIN
	RAISERROR('0.3 - Creating Config Schema',0,1) WITH NOWAIT
	EXEC ('CREATE SCHEMA Config')
END

/*Create update log table*/
IF OBJECT_ID('[App].[UpdateLog]') IS NULL
BEGIN

	RAISERROR('0.4 - Creating UpdateLog Table',0,1) WITH NOWAIT

	CREATE TABLE [App].[UpdateLog]
	(
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[UpgradeDate] [datetime] NULL,
		[Version] [decimal](16, 2) NULL
	)

	ALTER TABLE [App].[UpdateLog] ADD CONSTRAINT PK_UpdateLog_ID PRIMARY KEY (ID)

END

RAISERROR('0.5 - Populating UpdateLog Table',0,1) WITH NOWAIT

SELECT TOP 1
	@CurVersion = Version
FROM 
	[App].[UpdateLog]
ORDER BY UpgradeDate DESC

IF(@CurVersion != @Version OR @CurVersion IS NULL)

BEGIN

/*Insert current version and date */
INSERT INTO [App].[UpdateLog] (Version,UpgradeDate)
VALUES (@Version,@VersionDate)

END

/*Create run log table*/
IF OBJECT_ID('[Inventory].[RunLog]') IS NULL
BEGIN
	
	RAISERROR('0.6 - Creating RunLog Table',0,1) WITH NOWAIT

	CREATE TABLE [Inventory].[RunLog]
	(
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[EventDate] [datetime] NULL DEFAULT GETDATE(),
		[ProcedureName] [nvarchar](128) NULL,
		[Action] [varchar](100) NULL
	)

	ALTER TABLE [Inventory].[RunLog] ADD CONSTRAINT [PK_RunLog_ID] PRIMARY KEY (ID)
END

RAISERROR('0.7 - Checking Last Installed Version',0,1) WITH NOWAIT

SELECT TOP 1
	@CurVersion = Version
FROM 
	[App].[UpdateLog]
ORDER BY UpgradeDate DESC

/*Function Created */

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[App].[DayOfWeekSunday]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
BEGIN

RAISERROR('0.8 - Creating DayOfWeekSunday Function',0,1) WITH NOWAIT

DROP FUNCTION [App].[DayOfWeekSunday]

SET @Command =

'CREATE FUNCTION [App].[DayOfWeekSunday]
(
	@Date DATETIME
)
RETURNS INT

AS

BEGIN 
	DECLARE @DOW INT

	SET @DOW = DATEPART(DW,@Date)
	SET @Date = (@DOW + @@DATEFIRST - 1) % 7

	RETURN @DOW + 1

END'

EXEC (@Command)

END
ELSE
BEGIN
	EXEC (@Command)
END

DECLARE 
	@jobId binary(16),
	@JobOwner nvarchar(max)

SET @JobOwner = SUSER_SNAME(0x01)

SELECT @jobId = job_id FROM msdb.dbo.sysjobs WHERE (name = N'RICHMONITORING - RUN INVENTORY')
IF (@jobId IS NOT NULL)
BEGIN

	RAISERROR('0.9 - SQL Job Already Exists - Dropping & Creating',0,1) WITH NOWAIT

    EXECUTE msdb.dbo.sp_delete_job @jobId
	EXECUTE msdb.dbo.sp_add_job @job_name = 'RICHMONITORING - RUN INVENTORY', @description = 'Runs the Inventory Soloution', @category_name = 'Data Collector', @owner_login_name = @JobOwner
	EXECUTE msdb.dbo.sp_add_jobstep @job_name = 'RICHMONITORING - RUN INVENTORY', @step_name = 'Execute Inventory', @subsystem = 'TSQL', @command = 'EXEC [App].[usp_RunInventory]', @database_name = 'RichMonitoring'
	EXECUTE msdb.dbo.sp_add_jobserver @job_name = 'RICHMONITORING - RUN INVENTORY'
END
ELSE
BEGIN
	RAISERROR('0.9 - SQL Job Dosen''t Exist - Creating',0,1) WITH NOWAIT

	EXECUTE msdb.dbo.sp_add_job @job_name = 'RICHMONITORING - RUN INVENTORY', @description = 'Runs the Inventory Soloution', @category_name = 'Data Collector', @owner_login_name = @JobOwner
	EXECUTE msdb.dbo.sp_add_jobstep @job_name = 'RICHMONITORING - RUN INVENTORY', @step_name = 'Execute Inventory', @subsystem = 'TSQL', @command = 'EXEC [App].[usp_RunInventory]', @database_name = 'RichMonitoring'
	EXECUTE msdb.dbo.sp_add_jobserver @job_name = 'RICHMONITORING - RUN INVENTORY'
END

/* If the soloution is already installed, perform an upgrade */
	
RAISERROR('0.10 - Starting table upgrades for any existing tables',0,1) WITH NOWAIT
		
/* [Inventory].[DatabaseFiles] */

IF OBJECT_ID('[Inventory].[DatabaseFiles]') IS NOT NULL

BEGIN

RAISERROR('1.0 - DatabaseFiles already exists',0,1) WITH NOWAIT

RAISERROR('1.1 - Backing up existing DatabaseFiles data into DatabaseFiles_OldVersion',0,1) WITH NOWAIT

SELECT * INTO Inventory.DatabaseFiles_OldVersion FROM [Inventory].[DatabaseFiles]

RAISERROR('1.2 - Dropping existing DatabaseFiles table',0,1) WITH NOWAIT

DROP TABLE [Inventory].[DatabaseFiles]

RAISERROR('1.3 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[DatabaseFiles]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CensusDate] [datetime] NULL DEFAULT GETDATE(),
	[DataBaseName] [nvarchar](128) NULL,
	[file_id] [int] NULL,
	[name] [nvarchar](128) NULL,
	[type_desc] [nvarchar](60) NULL,
	[size] [int] NULL,
	[max_size] [int] NULL,
	[State] [nvarchar](60) NULL,
	[growth] [int] NULL,
	[is_percent_growth] [bit] NULL,
	[physical_name] [nvarchar](260) NULL
)

RAISERROR('1.4 - Moving Data From Backup table to production table',0,1) WITH NOWAIT

INSERT INTO [Inventory].[DatabaseFiles] ([CensusDate], [DataBaseName], [file_id], [name], [type_desc], [size], [max_size], [State], [growth], [is_percent_growth], [physical_name])
SELECT 
[CensusDate], [DataBaseName], [file_id], [name], [type_desc], [size], [max_size], [State], [growth], [is_percent_growth], [physical_name]
FROM 
Inventory.DatabaseFiles_OldVersion

RAISERROR('1.5 - Dropping DatabaseFiles_OldVersion as no longer required',0,1) WITH NOWAIT

DROP TABLE Inventory.DatabaseFiles_OldVersion

END
ELSE
BEGIN
	
	RAISERROR('1.0 - Creating DatabaseFiles table',0,1) WITH NOWAIT

	CREATE TABLE [Inventory].[DatabaseFiles]
	(
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[CensusDate] [datetime] NULL DEFAULT GETDATE(),
		[DataBaseName] [nvarchar](128) NULL,
		[file_id] [int] NULL,
		[name] [nvarchar](128) NULL,
		[type_desc] [nvarchar](60) NULL,
		[size] [int] NULL,
		[max_size] [int] NULL,
		[State] [nvarchar](60) NULL,
		[growth] [int] NULL,
		[is_percent_growth] [bit] NULL,
		[physical_name] [nvarchar](260) NULL
	)
END


/* [Inventory].[Databases] */

IF OBJECT_ID('[Inventory].[Databases]') IS NOT NULL
BEGIN

RAISERROR('2.0 - DatabaseFiles already exists',0,1) WITH NOWAIT
RAISERROR('2.1 - Backing up existing Databases data into Databases',0,1)

SELECT * INTO Inventory.Databases_OldVersion FROM [Inventory].[Databases]

RAISERROR('2.2 - Dropping existing DatabaseFiles table',0,1) WITH NOWAIT

DROP TABLE [Inventory].[Databases]

RAISERROR('2.3 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[Databases]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CensusDate] [datetime] NULL DEFAULT GETDATE(),
	[database_id] [int] NULL,
	[database_name] [nvarchar](128) NULL,
	[create_date] [datetime] NULL,
	[compatibility_level] [int] NULL,
	[collation_name] [nvarchar](128) NULL,
	[is_read_only] [bit] NULL,
	[is_auto_close_on] [bit] NULL,
	[user_access_desc] [nvarchar](60) NULL,
	[state_desc] [nvarchar](60) NULL,
	[recovery_model_desc] [nvarchar](60) NULL,
	[log_reuse_wait_desc] [nvarchar](60) NULL
)

ALTER TABLE [Inventory].[Databases] ADD CONSTRAINT [PK_Databases_ID_ID] PRIMARY KEY (ID);

RAISERROR('2.4 - Moving Data From Backup table to production table',0,1) WITH NOWAIT

INSERT INTO [Inventory].[Databases] ([CensusDate], [database_id], [database_name], [create_date], [compatibility_level], [collation_name], [is_read_only], [is_auto_close_on], [user_access_desc], [state_desc], [recovery_model_desc], [log_reuse_wait_desc])
SELECT 
[CensusDate], [database_id], [database_name], [create_date], [compatibility_level], [collation_name], [is_read_only], [is_auto_close_on], [user_access_desc], [state_desc], [recovery_model_desc], [log_reuse_wait_desc]
FROM 
Inventory.Databases_OldVersion

RAISERROR('2.5 - Dropping DatabaseFiles_OldVersion as no longer required',0,1) WITH NOWAIT

DROP TABLE Inventory.Databases_OldVersion

END
ELSE
BEGIN

RAISERROR('2.0 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[Databases]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CensusDate] [datetime] NULL DEFAULT GETDATE(),
	[database_id] [int] NULL,
	[database_name] [nvarchar](128) NULL,
	[create_date] [datetime] NULL,
	[compatibility_level] [int] NULL,
	[collation_name] [nvarchar](128) NULL,
	[is_read_only] [bit] NULL,
	[is_auto_close_on] [bit] NULL,
	[user_access_desc] [nvarchar](60) NULL,
	[state_desc] [nvarchar](60) NULL,
	[recovery_model_desc] [nvarchar](60) NULL,
	[log_reuse_wait_desc] [nvarchar](60) NULL
)

ALTER TABLE [Inventory].[Databases] ADD CONSTRAINT [PK_Databases_ID_ID] PRIMARY KEY (ID);

END

/* [Inventory].[DatabaseSize] */

IF OBJECT_ID('[Inventory].[DatabaseSize]') IS NOT NULL
BEGIN

RAISERROR('3.0 - DatabaseFiles already exists',0,1) WITH NOWAIT
RAISERROR('3.1 - Backing up existing DatabaseFiles data into DatabaseFiles_OldVersion',0,1)

SELECT * INTO Inventory.DatabaseSize_OldVersion FROM [Inventory].[DatabaseSize]

RAISERROR('3.2 - Dropping existing DatabaseFiles table',0,1) WITH NOWAIT

DROP TABLE [Inventory].[DatabaseSize]

RAISERROR('3.3 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[DatabaseSize]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CensusDate] [datetime] NULL DEFAULT GETDATE(),
	[database_name] [nvarchar](128) NULL,
	[Size_MB] [bigint] NULL,
	[Size_GB] [bigint] NULL
)

ALTER TABLE [Inventory].[DatabaseSize] ADD CONSTRAINT [PK_DatabaseSize_ID] PRIMARY KEY (ID)

RAISERROR('3.4 - Moving Data From Backup table to production table',0,1) WITH NOWAIT

INSERT INTO [Inventory].[DatabaseSize] ([CensusDate], [database_name], [Size_MB], [Size_GB])
SELECT 
[CensusDate], [database_name], [Size_MB], [Size_GB]
FROM 
Inventory.DatabaseSize_OldVersion

RAISERROR('3.5 - Dropping DatabaseFiles_OldVersion as no longer required',0,1) WITH NOWAIT

DROP TABLE Inventory.DatabaseSize_OldVersion

END 
ELSE
BEGIN

RAISERROR('3.0 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[DatabaseSize]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CensusDate] [datetime] NULL DEFAULT GETDATE(),
	[database_name] [nvarchar](128) NULL,
	[Size_MB] [bigint] NULL,
	[Size_GB] [bigint] NULL
)

ALTER TABLE [Inventory].[DatabaseSize] ADD CONSTRAINT [PK_DatabaseSize_ID] PRIMARY KEY (ID)
END

/* [Inventory].[JobHistory_Archive] */

IF OBJECT_ID('[Inventory].[JobHistory_Archive]') IS NOT NULL
BEGIN

RAISERROR('4.0 - DatabaseFiles already exists',0,1) WITH NOWAIT
RAISERROR('4.1 - Backing up existing DatabaseFiles data into DatabaseFiles_OldVersion',0,1)

SELECT * INTO Inventory.JobHistory_Archive_OldVersion FROM [Inventory].[JobHistory_Archive]

RAISERROR('4.2 - Dropping existing DatabaseFiles table',0,1) WITH NOWAIT

DROP TABLE [Inventory].[JobHistory_Archive]

RAISERROR('4.3 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[JobHistory_Archive]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[JobName] [nvarchar](128) NULL,
	[Message] [nvarchar](4000) NULL,
	[Run_Date] [int] NULL,
	[Run_Time] [int] NULL,
	[Run_Status] [int] NULL,
	[Date_Added] [datetime] NULL DEFAULT GETDATE()
)

ALTER TABLE [Inventory].[JobHistory_Archive] ADD CONSTRAINT PK_JobHistory_ID PRIMARY KEY (ID);

RAISERROR('4.4 - Moving Data From Backup table to production table',0,1) WITH NOWAIT

INSERT INTO [Inventory].[JobHistory_Archive] ([JobName], [Message], [Run_Date], [Run_Time], [Run_Status], [Date_Added])
SELECT 
[JobName], [Message], [Run_Date], [Run_Time], [Run_Status], [Date_Added]
FROM 
Inventory.JobHistory_Archive_OldVersion

RAISERROR('4.5 - Dropping DatabaseFiles_OldVersion as no longer required',0,1) WITH NOWAIT

DROP TABLE Inventory.JobHistory_Archive_OldVersion

END 
ELSE
BEGIN

RAISERROR('4.0 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[JobHistory_Archive]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[JobName] [nvarchar](128) NULL,
	[Message] [nvarchar](4000) NULL,
	[Run_Date] [int] NULL,
	[Run_Time] [int] NULL,
	[Run_Status] [int] NULL,
	[Date_Added] [datetime] NULL DEFAULT GETDATE()
)

ALTER TABLE [Inventory].[JobHistory_Archive] ADD CONSTRAINT PK_JobHistory_ID PRIMARY KEY (ID);
END

/* [Inventory].[Jobs] */

IF OBJECT_ID('[Inventory].[Jobs]') IS NOT NULL
BEGIN

RAISERROR('5.0 - DatabaseFiles already exists',0,1) WITH NOWAIT
RAISERROR('5.1 - Backing up existing DatabaseFiles data into DatabaseFiles_OldVersion',0,1)

SELECT * INTO Inventory.Jobs_OldVersion FROM [Inventory].[Jobs]

RAISERROR('5.2 - Dropping existing DatabaseFiles table',0,1) WITH NOWAIT

DROP TABLE [Inventory].[Jobs]

RAISERROR('5.3 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[Jobs]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CensusDate] [datetime] NULL DEFAULT GETDATE(),
	[JobName] [nvarchar](128) NULL,
	[job_id] [uniqueidentifier] NULL,
	[enabled] [bit] NULL,
	[start_step_id] [int] NULL,
	[step_id] [int] NULL,
	[step_name] [nvarchar](128) NULL,
	[subsystem] [varchar](40) NULL,
	[command] [nvarchar](max) NULL,
	[On_Success] [varchar](17) NULL,
	[On_Failure] [varchar](17) NULL,
	[schedule_id] [int] NULL,
	[FrequencyType] [varchar](45) NULL,
	[Interval] [varchar](6) NULL,
	[freq_type] [varchar](24) NULL,
	[DailyFrequency] [varchar](24) NULL,
	[Interval2] [varchar](26) NULL,
	[StartTime] [varchar](8) NULL,
	[EndTime] [varchar](8) NULL
)

ALTER TABLE [Inventory].[Jobs] ADD CONSTRAINT [PK_Jobs_ID] PRIMARY KEY (ID);

RAISERROR('5.4 - Moving Data From Backup table to production table',0,1) WITH NOWAIT

INSERT INTO [Inventory].[Jobs] ([CensusDate], [JobName], [job_id], [enabled], [start_step_id], [step_id], [step_name], [subsystem], [command], [On_Success], [On_Failure], [schedule_id], [FrequencyType], [Interval], [freq_type], [DailyFrequency], [Interval2], [StartTime], [EndTime])
SELECT 
[CensusDate], [JobName], [job_id], [enabled], [start_step_id], [step_id], [step_name], [subsystem], [command], [On_Success], [On_Failure], [schedule_id], [FrequencyType], [Interval], [freq_type], [DailyFrequency], [Interval2], [StartTime], [EndTime]
FROM 
Inventory.Jobs_OldVersion

RAISERROR('5.5 - Dropping DatabaseFiles_OldVersion as no longer required',0,1) WITH NOWAIT

DROP TABLE Inventory.Jobs_OldVersion

END
ELSE
BEGIN

RAISERROR('5.0 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[Jobs]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CensusDate] [datetime] NULL DEFAULT GETDATE(),
	[JobName] [nvarchar](128) NULL,
	[job_id] [uniqueidentifier] NULL,
	[enabled] [bit] NULL,
	[start_step_id] [int] NULL,
	[step_id] [int] NULL,
	[step_name] [nvarchar](128) NULL,
	[subsystem] [varchar](40) NULL,
	[command] [nvarchar](max) NULL,
	[On_Success] [varchar](17) NULL,
	[On_Failure] [varchar](17) NULL,
	[schedule_id] [int] NULL,
	[FrequencyType] [varchar](45) NULL,
	[Interval] [varchar](6) NULL,
	[freq_type] [varchar](24) NULL,
	[DailyFrequency] [varchar](24) NULL,
	[Interval2] [varchar](26) NULL,
	[StartTime] [varchar](8) NULL,
	[EndTime] [varchar](8) NULL
)

ALTER TABLE [Inventory].[Jobs] ADD CONSTRAINT [PK_Jobs_ID] PRIMARY KEY (ID);
END

/* [Inventory].[Logins] */

IF OBJECT_ID('[Inventory].[Logins]') IS NOT NULL
BEGIN

RAISERROR('6.0 - DatabaseFiles already exists',0,1) WITH NOWAIT
RAISERROR('6.1 - Backing up existing DatabaseFiles data into DatabaseFiles_OldVersion',0,1)

SELECT * INTO Inventory.Logins_OldVersion FROM [Inventory].[Logins]

RAISERROR('6.2 - Dropping existing DatabaseFiles table',0,1) WITH NOWAIT

DROP TABLE [Inventory].[Logins]

RAISERROR('6.3 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[Logins](
[ID] [int] IDENTITY(1,1) NOT NULL,
[CensusDate] [datetime] NULL DEFAULT GETDATE(),
[Server_Name] [nvarchar](255) NULL,
[LoginName] [nvarchar](128) NULL,
[principal_id] [int] NULL,
[sid] [varbinary](85) NULL,
[Login_Type] [varchar](50) NULL,
[Disabled] [bit] NULL,
[create_date] [datetime] NULL,
[modify_date] [datetime] NULL,
[default_database_name] [nvarchar](128) NULL,
[default_language_name] [nvarchar](128) NULL,
[Sys_Admin_Flag] [bit] NULL
)

ALTER TABLE [Inventory].[Logins] ADD CONSTRAINT [PK_Logins_ID] PRIMARY KEY (ID);

RAISERROR('6.4 - Moving Data From Backup table to production table',0,1) WITH NOWAIT

INSERT INTO [Inventory].[Logins] ([CensusDate], [Server_Name], [LoginName], [principal_id], [sid], [Login_Type], [Disabled], [create_date], [modify_date], [default_database_name], [default_language_name], [Sys_Admin_Flag])
SELECT 
[CensusDate], [Server_Name], [LoginName], [principal_id], [sid], [Login_Type], [Disabled], [create_date], [modify_date], [default_database_name], [default_language_name], [Sys_Admin_Flag]
FROM 
Inventory.Logins_OldVersion

RAISERROR('6.5 - Dropping DatabaseFiles_OldVersion as no longer required',0,1) WITH NOWAIT

DROP TABLE Inventory.Logins_OldVersion

END
ELSE
BEGIN

RAISERROR('6.0 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[Logins](
[ID] [int] IDENTITY(1,1) NOT NULL,
[CensusDate] [datetime] NULL DEFAULT GETDATE(),
[Server_Name] [nvarchar](255) NULL,
[LoginName] [nvarchar](128) NULL,
[principal_id] [int] NULL,
[sid] [varbinary](85) NULL,
[Login_Type] [varchar](50) NULL,
[Disabled] [bit] NULL,
[create_date] [datetime] NULL,
[modify_date] [datetime] NULL,
[default_database_name] [nvarchar](128) NULL,
[default_language_name] [nvarchar](128) NULL,
[Sys_Admin_Flag] [bit] NULL
)

ALTER TABLE [Inventory].[Logins] ADD CONSTRAINT [PK_Logins_ID] PRIMARY KEY (ID);
END

/* [Inventory].[Objects] */

IF OBJECT_ID('[Inventory].[Objects]') IS NOT NULL
BEGIN

RAISERROR('7.0 - DatabaseFiles already exists',0,1) WITH NOWAIT
RAISERROR('7.1 - Backing up existing DatabaseFiles data into DatabaseFiles_OldVersion',0,1)

SELECT * INTO Inventory.Objects_OldVersion FROM [Inventory].[Objects]

RAISERROR('7.2 - Dropping existing DatabaseFiles table',0,1) WITH NOWAIT

DROP TABLE [Inventory].[Objects]

RAISERROR('7.3 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[Objects]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CensusDate] [datetime] NULL DEFAULT GETDATE(),
	[DatabaseName] [nvarchar](128) NULL,
	[ParentObjectName] [nvarchar](128) NULL,
	[ObjectName] [nvarchar](128) NULL,
	[ObjectDefinition] [nvarchar](max) NULL,
	[SchemaName] [nvarchar](128) NULL,
	[ObjectType] [nvarchar](128) NULL,
	[ObjectTypeDescription] [nvarchar](128) NULL,
	[create_date] [datetime] NULL,
	[modify_date] [datetime] NULL
)

ALTER TABLE [Inventory].[Objects] ADD CONSTRAINT [PK_Objects_ID] PRIMARY KEY (ID);

RAISERROR('7.4 - Moving Data From Backup table to production table',0,1) WITH NOWAIT

INSERT INTO [Inventory].[Objects] ([CensusDate], [DatabaseName], [ParentObjectName], [ObjectName], [ObjectDefinition], [SchemaName], [ObjectType], [ObjectTypeDescription], [create_date], [modify_date])
SELECT 
[CensusDate], [DatabaseName], [ParentObjectName], [ObjectName], [ObjectDefinition], [SchemaName], [ObjectType], [ObjectTypeDescription], [create_date], [modify_date]
FROM 
Inventory.Objects_OldVersion

RAISERROR('7.5 - Dropping DatabaseFiles_OldVersion as no longer required',0,1) WITH NOWAIT

DROP TABLE Inventory.Objects_OldVersion

END
ELSE
BEGIN

RAISERROR('7.0 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[Objects]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CensusDate] [datetime] NULL DEFAULT GETDATE(),
	[DatabaseName] [nvarchar](128) NULL,
	[ParentObjectName] [nvarchar](128) NULL,
	[ObjectName] [nvarchar](128) NULL,
	[ObjectDefinition] [nvarchar](max) NULL,
	[SchemaName] [nvarchar](128) NULL,
	[ObjectType] [nvarchar](128) NULL,
	[ObjectTypeDescription] [nvarchar](128) NULL,
	[create_date] [datetime] NULL,
	[modify_date] [datetime] NULL
)

ALTER TABLE [Inventory].[Objects] ADD CONSTRAINT [PK_Objects_ID] PRIMARY KEY (ID);
END

/* [Inventory].[SysAdmins] */

IF OBJECT_ID('[Inventory].[SysAdmins]') IS NOT NULL
BEGIN

RAISERROR('8.0 - DatabaseFiles already exists',0,1) WITH NOWAIT
RAISERROR('8.1 - Backing up existing DatabaseFiles data into DatabaseFiles_OldVersion',0,1)

SELECT * INTO Inventory.SysAdmins_OldVersion FROM [Inventory].[SysAdmins]

RAISERROR('8.2 - Dropping existing DatabaseFiles table',0,1) WITH NOWAIT

DROP TABLE [Inventory].[SysAdmins]

RAISERROR('8.3 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[SysAdmins]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CensusDate] [datetime] NULL DEFAULT GETDATE(),
	[Server_Name] [nvarchar](255) NULL,
	[LoginName] [nvarchar](128) NULL,
	[sid] [varbinary](85) NULL,
	[Login_Type] [varchar](50) NULL,
	[Disabled] [bit] NULL,
	[create_date] [datetime] NULL,
	[modify_date] [datetime] NULL
)

ALTER TABLE [Inventory].[SysAdmins] ADD CONSTRAINT PK_SysAdmins_ID PRIMARY KEY (ID)

RAISERROR('8.4 - Moving Data From Backup table to production table',0,1) WITH NOWAIT

INSERT INTO [Inventory].[SysAdmins] ([CensusDate], [Server_Name], [LoginName], [sid], [Login_Type], [Disabled], [create_date], [modify_date])
SELECT 
[CensusDate], [Server_Name], [LoginName], [sid], [Login_Type], [Disabled], [create_date], [modify_date]
FROM 
Inventory.SysAdmins

RAISERROR('8.5 - Dropping DatabaseFiles_OldVersion as no longer required',0,1) WITH NOWAIT

DROP TABLE Inventory.SysAdmins_OldVersion

END
ELSE
BEGIN

RAISERROR('8.0 - Creating DatabaseFiles table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[SysAdmins]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CensusDate] [datetime] NULL DEFAULT GETDATE(),
	[Server_Name] [nvarchar](255) NULL,
	[LoginName] [nvarchar](128) NULL,
	[sid] [varbinary](85) NULL,
	[Login_Type] [varchar](50) NULL,
	[Disabled] [bit] NULL,
	[create_date] [datetime] NULL,
	[modify_date] [datetime] NULL
)

ALTER TABLE [Inventory].[SysAdmins] ADD CONSTRAINT PK_SysAdmins_ID PRIMARY KEY (ID)
END

RAISERROR('9.0 - Creating Configuration tables',0,1) WITH NOWAIT

RAISERROR('9.1 - Creating [Config].[Inventory] table',0,1) WITH NOWAIT

CREATE TABLE [Config].[Inventory]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[StoredProcedure] [nvarchar](255) NULL,
	[Description] [varchar](255) NULL,
	[RunOrder] [int] NULL,
	[WeeklyUpdates] [varchar](20) NULL,
	[Active] [bit] NULL DEFAULT 1
)

ALTER TABLE [Config].[Inventory] ADD CONSTRAINT [PK_Inventory_ID] PRIMARY KEY (ID)

RAISERROR('9.2 - Creating [Config].[AppConfig] table',0,1) WITH NOWAIT

CREATE TABLE [Config].[AppConfig]
(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ConfigName] [varchar](100) NULL,
	[ConfigDescription] [varchar](500) NULL,
	[StringValue] [varchar](200) NULL,
	[INTValue] [int] NULL,
	[BoolValue] [bit] NULL,
	[DecimalValue] [decimal](16, 2) NULL,
	[DateValue] [date] NULL,
	[DateTimeValue] [datetime] NULL,
	[Active] [bit] NULL DEFAULT 1
) 

ALTER TABLE [Config].[AppConfig] ADD CONSTRAINT [PK_AppConfig_ID] PRIMARY KEY (ID)

RAISERROR('9.3 - Inserting default configuration into [Config].[Inventory]',0,1) WITH NOWAIT

SET IDENTITY_INSERT [Config].[Inventory] ON

INSERT [Config].[Inventory] ([ID], [StoredProcedure], [Description], [RunOrder], [WeeklyUpdates], [Active]) 
VALUES 
(1, N'[App].[usp_DatabaseInventory_CALC_Master]', NULL, 1, N'1|1|1|1|1|1|1', 1),
(2, N'[App].[usp_DatabaseFileInventory_CALC_Insert]', NULL, 2, N'1|1|1|1|1|1|1', 1),
(3, N'[App].[usp_DatabaseSizeInventory_CALC_Master]', NULL, 3, N'1|1|1|1|1|1|1', 1),
(4, N'[App].[usp_LoginInventory_CALC_Master]', NULL, 4, N'1|1|1|1|1|1|1', 1),
(5, N'[App].[usp_ObjectInventory_CALC_Master]', NULL, 5, N'1|1|1|1|1|1|1', 1),
(6, N'[App].[usp_SQLJobInventory_CALC_Master]', NULL, 6, N'1|1|1|1|1|1|1', 1),
(7, N'[App].[usp_SysAdminInventory_CALC_Master]', NULL, 7, N'1|1|1|1|1|1|1', 1),
(8, N'[App].[usp_ApplicationCleanup]', NULL, 8, N'1|1|1|1|1|1|1', 1),
(9, N'[App].[usp_Cleanup_Job_History]', NULL, 9, N'1|1|1|1|1|1|1', 1),
(10,'[App].[usp_DatabaseInventory_CALC_Master]',10,'1|1|1|1|1|1|1',1)

SET IDENTITY_INSERT [Config].[Inventory] OFF

RAISERROR('9.3 - Inserting default configuration into [Config].[AppConfig]',0,1) WITH NOWAIT

SET IDENTITY_INSERT [Config].[AppConfig] ON
INSERT [Config].[AppConfig] ([ID], [ConfigName], [ConfigDescription], [StringValue], [INTValue], [BoolValue], [DecimalValue], [DateValue], [DateTimeValue], [Active]) 
VALUES (1, N'Clean Up', N'The amout of days to keep records for', N'', -30, NULL, NULL, NULL, NULL, 1)
SET IDENTITY_INSERT [Config].[AppConfig] OFF

/* Sys Configurations */

/* [Inventory].[SysConfigurations] */

IF OBJECT_ID('[Inventory].[SysConfigurations]') IS NOT NULL
BEGIN

RAISERROR('10.0 - SysConfigurations already exists',0,1) WITH NOWAIT
RAISERROR('10.1 - Backing up existing SysConfigurations data into SysConfigurations_OldVersion',0,1)

SELECT * INTO Inventory.SysConfigurations_OldVersion FROM [Inventory].[SysConfigurations]

RAISERROR('10.2 - Dropping existing SysConfigurations table',0,1) WITH NOWAIT

DROP TABLE [Inventory].[SysConfigurations]

RAISERROR('10.3 - Creating SysConfigurations table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[sysconfigurations]
(
    ID INT IDENTITY(1,1) NOT NULL,
    CensusDate DATETIME,
    Configuration_ID INT,
    Name nvarchar(35),
    value SQL_VARIANT,
    [minimum] SQL_VARIANT, 
    [maximum] SQL_VARIANT, 
    [value_in_use] SQL_VARIANT, 
    [description] nvarchar(255), 
    [is_dynamic] BIT, 
    [is_advanced] BIT
)

ALTER TABLE [Inventory].[sysconfigurations] ADD CONSTRAINT PK_sysconfigurations_ID PRIMARY KEY (ID)

RAISERROR('10.4 - Moving Data From Backup table to production table',0,1) WITH NOWAIT

INSERT INTO [Inventory].[sysconfigurations] ([CensusDate], [Configuration_ID], [Name], [value], [minimum], [maximum], [value_in_use], [description], [is_dynamic], [is_advanced])
SELECT 
[CensusDate], [Configuration_ID], [Name], [value], [minimum], [maximum], [value_in_use], [description], [is_dynamic], [is_advanced]
FROM 
Inventory.sysconfigurations

RAISERROR('10.5 - Dropping SysConfigurations_OldVersion as no longer required',0,1) WITH NOWAIT

DROP TABLE Inventory.sysconfigurations_OldVersion

END
ELSE
BEGIN

RAISERROR('10.0 - Creating SysConfigurations table',0,1) WITH NOWAIT

CREATE TABLE [Inventory].[sysconfigurations]
(
    ID INT IDENTITY(1,1) NOT NULL,
    CensusDate DATETIME,
    Configuration_ID INT,
    Name nvarchar(35),
    value SQL_VARIANT,
    [minimum] SQL_VARIANT, 
    [maximum] SQL_VARIANT, 
    [value_in_use] SQL_VARIANT, 
    [description] nvarchar(255), 
    [is_dynamic] BIT, 
    [is_advanced] BIT
)

ALTER TABLE [Inventory].[sysconfigurations] ADD CONSTRAINT PK_sysconfigurations_ID PRIMARY KEY (ID)

END

/* Table Upgrade Complete */

RAISERROR('0.11 - Tables Created/Upgraded',0,1) WITH NOWAIT


/*Create the views procedures */

RAISERROR('0.12 - Creating/Upgrading Views',0,1) WITH NOWAIT

IF OBJECT_ID('[App].[vw_DatabaseInventory_CALC_Loading]') IS NULL
BEGIN
	
	RAISERROR('9.0 - Creating/Upgrading Views',0,1) WITH NOWAIT

	EXEC ('CREATE VIEW [App].[vw_DatabaseInventory_CALC_Loading] AS SELECT '''' as v')
END
GO

RAISERROR('9.1 - Creating/Upgrading Views',0,1) WITH NOWAIT
GO

ALTER VIEW [App].[vw_DatabaseInventory_CALC_Loading]

AS

SELECT 
	GETDATE() as CensusDate
	,d.database_id
	,d.NAME
	,create_date
	,compatibility_level
	,collation_name
	,d.is_read_only
	,is_auto_close_on
	,user_access_desc
	,d.state_desc
	,recovery_model_desc
	,log_reuse_wait_desc
FROM 
	msdb.sys.databases d 
WHERE 
	d.database_id > 4
GO

IF OBJECT_ID('[App].[vw_DatabaseSizeInventory_CALC_Loading]') IS NULL
BEGIN

	RAISERROR('10.0 - Creating/Upgrading Views',0,1) WITH NOWAIT

	EXEC ('CREATE VIEW [App].[vw_DatabaseSizeInventory_CALC_Loading] AS SELECT '''' as v')
END
GO

RAISERROR('10.1 - Creating/Upgrading Views',0,1) WITH NOWAIT

GO

ALTER VIEW [App].[vw_DatabaseSizeInventory_CALC_Loading]

AS

SELECT 
	GETDATE() as CensusDate
	,d.NAME as DatabaseName
	,ROUND(SUM(CAST(mf.size AS bigint)) * 8 / 1024, 0) Size_MBs
	,(SUM(CAST(mf.size AS bigint)) * 8 / 1024) / 1024 AS Size_GBs
FROM sys.master_files mf
INNER JOIN sys.databases d ON d.database_id = mf.database_id
WHERE d.database_id > 4
GROUP BY d.NAME
GO

IF OBJECT_ID('[App].[vw_LoginInventory_CALC_Loading]') IS NULL
BEGIN

RAISERROR('11.0 - Creating/Upgrading Views',0,1) WITH NOWAIT

EXEC ('CREATE VIEW [App].[vw_LoginInventory_CALC_Loading] AS SELECT '''' as v')
END
GO

RAISERROR('11.1 - Creating/Upgrading Views',0,1) WITH NOWAIT

GO

ALTER VIEW [App].[vw_LoginInventory_CALC_Loading]

AS

SELECT
	GETDATE() AS CensusDate,
	@@SERVERNAME as [Server_Name],
	[name] as [LoginName], 
	[principal_id], 
	[sid], 
	[type_desc] As [Login_Type], 
	[is_disabled] AS [Disabled],  
	[create_date], 
	[modify_date], 
	[default_database_name], 
	[default_language_name],
	IS_SRVROLEMEMBER('SysAdmin',name) as [Sys_Admin_Flag]
	FROM	
		sys.server_principals sp 
	WHERE 
	type IN ('S','U')

GO

IF OBJECT_ID('[App].[vw_SQLJobInventory_CALC_Loading]') IS NULL
BEGIN

RAISERROR('12.0 - Creating/Upgrading Views',0,1) WITH NOWAIT

EXEC ('CREATE VIEW [App].[vw_SQLJobInventory_CALC_Loading] AS SELECT '''' as v')
END
GO

RAISERROR('12.1 - Creating/Upgrading Views',0,1) WITH NOWAIT

GO

ALTER VIEW [App].[vw_SQLJobInventory_CALC_Loading]

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
GO

IF OBJECT_ID('[App].[vw_SysAdminInventory_CALC_Loading]') IS NULL
BEGIN
	RAISERROR('13.0 - Creating/Upgrading Views',0,1) WITH NOWAIT

	EXEC ('CREATE VIEW [App].[vw_SysAdminInventory_CALC_Loading] AS SELECT '''' as v')
END
GO

RAISERROR('13.1 - Creating/Upgrading Views',0,1) WITH NOWAIT

GO

ALTER VIEW [App].[vw_SysAdminInventory_CALC_Loading]

AS

SELECT
	GETDATE() AS CensusDate,
	@@SERVERNAME as [Server_Name],
	[name] as [LoginName], 
	[sid], 
	[type_desc] As [Login_Type], 
	[is_disabled] AS [Disabled],  
	[create_date], 
	[modify_date]
	FROM	
		sys.server_principals sp 
	WHERE 
	type IN ('S','U') 
	AND IS_SRVROLEMEMBER('SysAdmin',name) = 1
GO

/*Create the stored procedures */

RAISERROR('0.13 - Creating/Upgrading Stored Procedures',0,1) WITH NOWAIT

IF OBJECT_ID('[App].[usp_ApplicationCleanup]') IS NULL
BEGIN

	RAISERROR('14.0 - Creating usp_ApplicationCleanup',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_ApplicationCleanup] AS RETURN 0;')
END
GO

RAISERROR('14.1 - Amending usp_ApplicationCleanup',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_ApplicationCleanup]

AS

SET NOCOUNT ON

BEGIN 
	BEGIN TRY
		BEGIN TRANSACTION

			DECLARE 
				@Me VARCHAR(64),
				@Days INT
			
			SET @Me = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))
			SET @Days = (SELECT INTValue FROM [Config].[AppConfig] WHERE ConfigName = 'Clean Up' AND Active = 1)

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Begin'

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from DatabaseFiles'

			DELETE FROM [Inventory].[DatabaseFiles] WHERE CensusDate < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from Databases'

			DELETE FROM [Inventory].[Databases] WHERE CensusDate < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from DatabaseSize'

			DELETE FROM [Inventory].[DatabaseSize] WHERE CensusDate < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from Jobs'

			DELETE FROM [Inventory].[Jobs] WHERE CensusDate < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from Logins'

			DELETE FROM [Inventory].[Logins] WHERE CensusDate < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from Objects'

			DELETE FROM [Inventory].[Objects] WHERE CensusDate < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from RunLog'

			DELETE FROM [Inventory].[RunLog] WHERE [EventDate] < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from SysAdmins'

			DELETE FROM [Inventory].[SysAdmins] WHERE CensusDate < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'End'

		COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
	IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

			INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
			VALUES
				(
				SUSER_SNAME(),
				ERROR_NUMBER(),
				ERROR_STATE(),
				ERROR_SEVERITY(),
				ERROR_LINE(),
				ERROR_PROCEDURE(),
				ERROR_MESSAGE(),
				GETDATE()
				);
	END CATCH
END
	
GO

IF OBJECT_ID('[App].[usp_Cleanup_Job_History]') IS NULL
BEGIN

	RAISERROR('15.0 - Creating usp_Cleanup_Job_History',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_Cleanup_Job_History] AS RETURN 0;')
END
GO

RAISERROR('15.1 - Amending usp_Cleanup_Job_History',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_Cleanup_Job_History]

AS

BEGIN

	SET NOCOUNT ON;
	
	--A couple of variables that we are going to use
	DECLARE 
		@Counter INT,
		@MaxID INT,
		@JobName NVARCHAR(128),
		@Me VARCHAR(64) 
			
	SET @Me = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

	EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Begin'

	--A temp table to hold some results for us to loop through
	CREATE TABLE #Results
	(
		ID INT IDENTITY(1,1) NOT NULL,
		JobName NVARCHAR(128)
	)

	BEGIN

		BEGIN TRY

			BEGIN TRANSACTION t1
		
				--Get the job name of the jobs we want to purge the data for
				INSERT INTO #Results
				SELECT 
					[sJOB].[name] AS [JobName]
				FROM
					[msdb].[dbo].[sysjobs] AS [sJOB]
  
					LEFT JOIN [msdb].[dbo].[sysjobschedules] AS [sJOBSCH]
						ON [sJOB].[job_id] = [sJOBSCH].[job_id]
    
					LEFT JOIN [msdb].[dbo].[sysschedules] AS [sSCH]
						ON [sJOBSCH].[schedule_id] = [sSCH].[schedule_id]

					LEFT JOIN [msdb].[dbo].[sysschedules] AS [SShed]
						ON SShed.schedule_id = SSch.schedule_id

					WHERE 
					[sJOB].enabled = 1 --Make sure that the job is actually active
					AND [sSCH].[schedule_uid] IS NOT NULL --Job is scheduled
					AND [SShed].[freq_subday_type] = 4 --Jobs that run every x minutes
					AND [SShed].[freq_subday_interval] < 60 --Jobs that run less than every 60 minutes

			COMMIT TRANSACTION t1

		END TRY
		BEGIN CATCH 

		ROLLBACK TRANSACTION t1

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

		INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH

	END

	SET @Counter = 1

	--Set the MAXID from the MAXID of the results table 
	SET @MaxID = (SELECT MAX(ID) FROM #Results)

	--If the counter is less or equal to the max id keep looping
	WHILE @Counter <= @MaxID

	BEGIN

		BEGIN TRY

			BEGIN TRANSACTION t2
		
				--Get the job name from the results data set 
				SET @JobName = (SELECT JobName FROM #Results WHERE ID = @Counter)

				EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Archiving Job Data'

				--Store the history of the data we are going to remove in a table that isn't MSDB
				--that way we can add an index etc.
				INSERT INTO [RichMonitoring].[Inventory].[JobHistory_Archive](JobName,Message,Run_Date,Run_Time,Run_Status)
		
				SELECT 
					j.name,
					jh.message,
					jh.run_date,
					jh.run_time,
					jh.run_status 
		
				FROM 
					msdb..sysjobhistory jh
				LEFT JOIN msdb..sysjobs j ON
					j.job_id = jh.job_id

				WHERE 
				j.name = @JobName

				EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting Job Data'
		
				--Remove the data from the MSDB jobhistory table, we don't want any of this data keeping so we won't specify a date
				EXEC msdb..sp_purge_jobhistory @job_name = @JobName

			COMMIT TRANSACTION t2

		END TRY
		BEGIN CATCH

		ROLLBACK TRANSACTION t2

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

		INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH

		--Increment that counter and loop if we don't meet the MAX ID condition
		SET @Counter = @Counter +1

	END

	--We are done, drop the temp table
	DROP TABLE #Results

	EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'End'

END

GO

--

IF OBJECT_ID('[App].[usp_DatabaseFileInventory_CALC_Insert]') IS NULL
BEGIN

RAISERROR('16.0 - Creating usp_DatabaseFileInventory_CALC_Insert',0,1) WITH NOWAIT

EXEC ('CREATE PROCEDURE [App].[usp_DatabaseFileInventory_CALC_Insert] AS RETURN 0;')
END
GO

RAISERROR('16.1 - Amending usp_DatabaseFileInventory_CALC_Insert',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_DatabaseFileInventory_CALC_Insert]

AS

SET NOCOUNT ON;

BEGIN

	DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

	BEGIN TRY
			
		BEGIN TRANSACTION

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Begin'

			DECLARE @SqlQuery varchar(4000)	

			SET @SqlQuery =
			'USE ?

			INSERT INTO [RichMonitoring].[Inventory].[DatabaseFiles] ([DataBaseName], [file_id], [name], [type_desc], [size], [max_size], [State], [growth], [is_percent_growth], [physical_name])
			SELECT
				DB_NAME() as DataBaseName,
				file_id,
				name,
				type_desc,
				size,
				max_size,
				state_desc as [State],
				growth,
				is_percent_growth,
				physical_name
				FROM 
					sys.database_files
			WHERE type = 0'

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Inserting Data'

			EXEC sp_MSforeachdb @SqlQuery	

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Data Inserted'
				
			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'End'

		COMMIT TRANSACTION

		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

		INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH
END
	
--
GO

IF OBJECT_ID('[App].[usp_DatabaseInventory_CALC_Insert]') IS NULL
BEGIN

	RAISERROR('17.0 - Creating usp_DatabaseInventory_CALC_Insert',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_DatabaseInventory_CALC_Insert] AS RETURN 0;')
END
GO

RAISERROR('17.1 - Amending usp_DatabaseInventory_CALC_Insert',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_DatabaseInventory_CALC_Insert]

AS

SET NOCOUNT ON;

BEGIN

	DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

	BEGIN TRY
			
		BEGIN TRANSACTION

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Inserting Data'

			INSERT INTO  [Inventory].[Databases]	
			(
				[CensusDate], 
				[database_id], 
				[database_name], 
				[create_date], 
				[compatibility_level], 
				[collation_name], 
				[is_read_only], 
				[is_auto_close_on], 
				[user_access_desc], 
				[state_desc], 
				[recovery_model_desc], 
				[log_reuse_wait_desc]			
			)
			SELECT
				[CensusDate], 
				[database_id], 
				[NAME], 
				[create_date], 
				[compatibility_level], 
				[collation_name], 
				[is_read_only], 
				[is_auto_close_on], 
				[user_access_desc], 
				[state_desc], 
				[recovery_model_desc], 
				[log_reuse_wait_desc]
			FROM 
				[App].[vw_DatabaseInventory_CALC_Loading]

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Data Inserted'

		COMMIT TRANSACTION

		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION
			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

			INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH
END

--
GO

IF OBJECT_ID('[App].[usp_DatabaseInventory_CALC_Master]') IS NULL
BEGIN
	RAISERROR('18.0 - Creating usp_DatabaseInventory_CALC_Master',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_DatabaseInventory_CALC_Master] AS RETURN 0;')
END
GO

RAISERROR('18.1 - Amending usp_DatabaseInventory_CALC_Master',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_DatabaseInventory_CALC_Master]

AS
SET NOCOUNT ON;

BEGIN

	DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

	BEGIN TRY
			
		BEGIN TRANSACTION

			EXEC [App].[usp_DatabaseInventory_CALC_Insert]

		COMMIT TRANSACTION

		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION
		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

		INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH
END

GO

IF OBJECT_ID('[App].[usp_DatabaseSizeInventory_CALC_Insert]') IS NULL
BEGIN

	RAISERROR('19.0 - Creating usp_DatabaseSizeInventory_CALC_Insert',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_DatabaseSizeInventory_CALC_Insert] AS RETURN 0;')
END
GO

RAISERROR('19.1 - Amending usp_DatabaseSizeInventory_CALC_Insert',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_DatabaseSizeInventory_CALC_Insert]

AS
SET NOCOUNT ON;

BEGIN

	DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

	BEGIN TRY
			
		BEGIN TRANSACTION

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Inserting Data'

			INSERT INTO [Inventory].[DatabaseSize]
			(
				[CensusDate], 
				[Database_Name], 
				[Size_MB], 
				[Size_GB]
			)
			SELECT
				[CensusDate], 
				[databasename], 
				[Size_MBs], 
				[Size_GBs]
				FROM	
					[App].[vw_DatabaseSizeInventory_CALC_Loading]

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Data Inserted'

		COMMIT TRANSACTION

		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION
		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

		INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH
END

--
GO

IF OBJECT_ID('[App].[usp_DatabaseSizeInventory_CALC_Master]') IS NULL
BEGIN
	RAISERROR('20.0 - Creating usp_DatabaseSizeInventory_CALC_Master',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_DatabaseSizeInventory_CALC_Master] AS RETURN 0;')
END
GO

RAISERROR('20.1 - Amending usp_DatabaseSizeInventory_CALC_Master',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_DatabaseSizeInventory_CALC_Master]

AS
SET NOCOUNT ON;

BEGIN

	DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

	BEGIN TRY
			
		BEGIN TRANSACTION

			EXEC [App].[usp_DatabaseSizeInventory_CALC_Insert]


		COMMIT TRANSACTION

		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION
		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

		INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH
END

--
GO

IF OBJECT_ID('[App].[usp_InsertRunLog]') IS NULL
BEGIN

	RAISERROR('21.0 - Creating usp_InsertRunLog',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_InsertRunLog] AS RETURN 0;')
END
GO

RAISERROR('21.1 - Amending usp_InsertRunLog',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_InsertRunLog]

@ProcedureName nvarchar(128),
@Action varchar(100)

AS

BEGIN
	BEGIN TRY
		BEGIN TRANSACTION

			INSERT INTO [Inventory].[RunLog] (ProcedureName, Action)
			VALUES
			(@ProcedureName,@Action)
		
		COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION
	END CATCH
END

--
GO

IF OBJECT_ID('[App].[usp_LoginInventory_CALC_Insert]') IS NULL
BEGIN

	RAISERROR('22.0 - Creating usp_LoginInventory_CALC_Insert',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_LoginInventory_CALC_Insert] AS RETURN 0;')
END
GO

RAISERROR('22.1 - Amending usp_LoginInventory_CALC_Insert',0,1) WITH NOWAIT

GO 

ALTER PROCEDURE [App].[usp_LoginInventory_CALC_Insert]

AS
SET NOCOUNT ON;

BEGIN

	DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

	BEGIN TRY
			
		BEGIN TRANSACTION

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Inserting Data'

			INSERT INTO Inventory.Logins
			(
				CensusDate ,
				[Server_Name] ,
				[LoginName] , 
				[principal_id] , 
				[sid] , 
				[Login_Type] , 
				[Disabled] ,  
				[create_date] , 
				[modify_date] , 
				[default_database_name], 
				[default_language_name],
				[Sys_Admin_Flag]
			)
			SELECT
				CensusDate,
				[Server_Name],
				[LoginName], 
				[principal_id], 
				[sid], 
				[Login_Type], 
				[Disabled],  
				[create_date], 
				[modify_date], 
				[default_database_name], 
				[default_language_name],
				[Sys_Admin_Flag]
				FROM	
					[App].[vw_LoginInventory_CALC_Loading]

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Data Inserted'

		COMMIT TRANSACTION

		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT > 0 			
		ROLLBACK TRANSACTION

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

		INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH
END

--
GO

IF OBJECT_ID('[App].[usp_LoginInventory_CALC_Master]') IS NULL
BEGIN

	RAISERROR('23.0 - Creating usp_LoginInventory_CALC_Master',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_LoginInventory_CALC_Master] AS RETURN 0;')
END
GO

RAISERROR('23.1 - Amending usp_LoginInventory_CALC_Master',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_LoginInventory_CALC_Master]

AS
SET NOCOUNT ON;

BEGIN

	DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

	BEGIN TRY
			
		BEGIN TRANSACTION

			EXEC [App].[usp_LoginInventory_CALC_Insert]

		COMMIT TRANSACTION

		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

		INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH
END

--

GO

IF OBJECT_ID('[App].[usp_ObjectInventory_CALC_Insert]') IS NULL
BEGIN
	
	RAISERROR('24.0 - Creating usp_ObjectInventory_CALC_Insert',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_ObjectInventory_CALC_Insert] AS RETURN 0;')
END
GO

RAISERROR('24.1 - Amending usp_ObjectInventory_CALC_Insert',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_ObjectInventory_CALC_Insert]

AS
SET NOCOUNT ON;

BEGIN
		
	DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

	BEGIN TRY
		BEGIN TRANSACTION				

			DECLARE @SqlQuery varchar(4000)				

			SET @SqlQuery =
			'USE ?

			INSERT INTO [RichMonitoring].[Inventory].[Objects] (DatabaseName,ParentObjectName,ObjectName,ObjectDefinition,SchemaName,ObjectType,ObjectTypeDescription,create_date,modify_date)
			SELECT
			DB_NAME() as DatabaseName,
			OBJECT_NAME(p.parent_object_id) ParentObjectName,
			p.name as ObjectName,
			OBJECT_DEFINITION(object_id),
			s.name as SchemaName,
			type,
			type_desc,
			create_date,
			modify_date

			FROM sys.objects p

			INNER JOIN sys.schemas s ON p.schema_id = s.schema_id

			WHERE
				is_ms_shipped = 0'

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Inserting Data'

			EXEC sp_MSforeachdb @SqlQuery
				
			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Data Inserted'


		COMMIT TRANSACTION
		END TRY
		BEGIN CATCH 
			IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

			INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH
END

--
GO

IF OBJECT_ID('[App].[usp_ObjectInventory_CALC_Master]') IS NULL
BEGIN

	RAISERROR('25.0 - Creating usp_ObjectInventory_CALC_Master',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_ObjectInventory_CALC_Master] AS RETURN 0;')
END
GO

RAISERROR('25.1 - Amending usp_ObjectInventory_CALC_Master',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_ObjectInventory_CALC_Master]

AS
SET NOCOUNT ON;

BEGIN

	DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

	BEGIN TRY
			
		BEGIN TRANSACTION

			EXEC [App].[usp_ObjectInventory_CALC_Insert]

		COMMIT TRANSACTION

		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

		INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH
END

--
GO

IF OBJECT_ID('[App].[usp_RunInventory]') IS NULL
BEGIN

RAISERROR('26.0 - Creating usp_RunInventory',0,1) WITH NOWAIT

EXEC ('CREATE PROCEDURE [App].[usp_RunInventory] AS RETURN 0;')
END
GO

RAISERROR('26.1 - Amending usp_RunInventory',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_RunInventory]

AS

SET NOCOUNT ON;

DECLARE 
	@Count INT,
	@End INT,
	@Query NVARCHAR(1000),
	@Config varchar(50),
	@Run BIT,
	@WkUpdate VARCHAR(20),
	@mDay INT,
	@mWDay INT,
	@Proc varchar(100),
	@Complete BIT,
	@Date DATE

SET @Date = GETDATE()

SET @Config = '[Config].[Inventory]'

SET @Query = 'SELECT @Max = MAX(Convert(int,[RunOrder])) FROM ' + @Config + ' WHERE [Active] = 1'
EXEC sp_executesql @Query, N'@Max INT OUTPUT' , @Max = @End OUTPUT
SET @Count = 1

WHILE @Count <= @End
BEGIN
	SET @Run = 0
	SET @Complete = 0

	SET @Query = N'SELECT @r = Active, @sp = [StoredProcedure], @weekly = [WeeklyUpdates] FROM ' + @Config + ' WHERE [RunOrder] = @Count'
	EXEC sp_executesql @Query, N'@Count NVARCHAR(6), @r BIT OUTPUT, @sp varchar(100) OUTPUT, @Weekly varchar(20) OUTPUT', @Count = @Count, @r = @Run OUTPUT, @sp = @Proc OUTPUT, @weekly = @WkUpdate OUTPUT

	IF @Run = 1 AND @Complete = 0 
	BEGIN 
		
		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Proc, @Action = 'Begin'

		SET @Query = 'EXEC ' + @Proc

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Proc, @Action = 'End'

		IF DATEPART(d,@Date) = @mDay
		BEGIN
			
			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Proc, @Action = 'Begin'

			EXEC sp_executesql @Query

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Proc, @Action = 'End'

			SET @Complete = 1
		END
		IF SUBSTRING(@WkUpdate,App.DayOfWeekSunday(@Date) + App.DayOfWeekSunday(@Date)-1,1) = 1 AND @Complete = 0
		BEGIN

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Proc, @Action = 'Begin'

			EXEC sp_executesql @Query

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Proc, @Action = 'End'

			SET @Complete = 1
		END
	END 	

	SET @Count = @Count + 1

END

--
GO

IF OBJECT_ID('[App].[usp_SQLJobInventory_CALC_Insert]') IS NULL
BEGIN

RAISERROR('27.0 - Creating usp_SQLJobInventory_CALC_Insert',0,1) WITH NOWAIT

EXEC ('CREATE PROCEDURE [App].[usp_SQLJobInventory_CALC_Insert] AS RETURN 0;')
END
GO

RAISERROR('27.1 - Amending usp_SQLJobInventory_CALC_Insert',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_SQLJobInventory_CALC_Insert]

AS
SET NOCOUNT ON;

BEGIN

	DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

	BEGIN TRY
			
		BEGIN TRANSACTION

			EXEC [App].[usp_InsertRunLog] @ProcedureName = '[dbo].[usp_DatabaseInventory_CALC_Insert]', @Action = 'Inserting Data'

			INSERT INTO Inventory.Jobs
			(
				[CensusDate], 
				[JobName], 
				[job_id], 
				[enabled], 
				[start_step_id], 
				[step_id], 
				[step_name], 
				[subsystem], 
				[command], 
				[On_Success], 
				[On_Failure], 
				[schedule_id], 
				[FrequencyType], 
				[Interval], 
				[freq_type], 
				[DailyFrequency], 
				[Interval2], 
				[StartTime], 
				[EndTime]
			)
			SELECT
				[CensusDate], 
				[JobName], 
				[job_id], 
				[enabled], 
				[start_step_id], 
				[step_id], 
				[step_name], 
				[subsystem], 
				[command], 
				[On_Success], 
				[On_Failure], 
				[schedule_id], 
				[FrequencyType], 
				[Interval], 
				[freq_type], 
				[DailyFrequency], 
				[Interval2], 
				[StartTime], 
				[EndTime]
				FROM	
					App.vw_SQLJobInventory_CALC_Loading

		EXEC [App].[usp_InsertRunLog] @ProcedureName = '[dbo].[usp_DatabaseInventory_CALC_Insert]', @Action = 'Data Inserted'

		COMMIT TRANSACTION

		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

		INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH
END

--
GO

IF OBJECT_ID('[App].[usp_SQLJobInventory_CALC_Master]') IS NULL
BEGIN

RAISERROR('28.0 - Creating usp_SQLJobInventory_CALC_Master',0,1) WITH NOWAIT

EXEC ('CREATE PROCEDURE [App].[usp_SQLJobInventory_CALC_Master] AS RETURN 0;')
END
GO

RAISERROR('28.1 - Amending usp_SQLJobInventory_CALC_Master',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_SQLJobInventory_CALC_Master]

AS
SET NOCOUNT ON;

BEGIN

	DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

	BEGIN TRY
			
		BEGIN TRANSACTION

			EXEC [App].[usp_SQLJobInventory_CALC_Insert]

		COMMIT TRANSACTION

		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

		INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH
END

--
GO

IF OBJECT_ID('[App].[usp_SQLJobInventory_CALC_Master]') IS NULL
BEGIN

RAISERROR('29.0 - Creating usp_SQLJobInventory_CALC_Master',0,1) WITH NOWAIT

EXEC ('CREATE PROCEDURE [App].[usp_SQLJobInventory_CALC_Master] AS RETURN 0;')
END
GO

RAISERROR('29.1 - Amending usp_SQLJobInventory_CALC_Master',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_SQLJobInventory_CALC_Master]

AS
SET NOCOUNT ON;

BEGIN

	DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

	BEGIN TRY
			
		BEGIN TRANSACTION

			EXEC [App].[usp_SQLJobInventory_CALC_Insert]

		COMMIT TRANSACTION

		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

		INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH
END

--
GO

IF OBJECT_ID('[App].[usp_SysAdminInventory_CALC_Insert]') IS NULL
BEGIN

	RAISERROR('30.0 - Creating usp_SysAdminInventory_CALC_Insert',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_SysAdminInventory_CALC_Insert] AS RETURN 0;')
END
GO

RAISERROR('30.1 - Amending usp_SysAdminInventory_CALC_Insert',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_SysAdminInventory_CALC_Insert]

AS
SET NOCOUNT ON;

BEGIN

	DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

	BEGIN TRY
			
		BEGIN TRANSACTION

			EXEC [App].[usp_InsertRunLog] @ProcedureName = '[dbo].[usp_DatabaseInventory_CALC_Insert]', @Action = 'Inserting Data'

			INSERT INTO Inventory.SysAdmins
			(
				CensusDate ,
				[Server_Name] ,
				[LoginName],
				[sid], 
				[Login_Type], 
				[Disabled],  
				[create_date], 
				[modify_date] 
			)
			SELECT
				CensusDate,
				[Server_Name],
				[LoginName], 
				[sid], 
				[Login_Type], 
				[Disabled],  
				[create_date], 
				[modify_date]
				FROM	
					[App].[vw_SysAdminInventory_CALC_Loading]

			EXEC [App].[usp_InsertRunLog] @ProcedureName = '[dbo].[usp_DatabaseInventory_CALC_Insert]', @Action = 'Data Inserted'

		COMMIT TRANSACTION

		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

		INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH
END

--
GO

IF OBJECT_ID('[App].[usp_SysAdminInventory_CALC_Master]') IS NULL
BEGIN

	RAISERROR('31.0 - Creating usp_SysAdminInventory_CALC_Master',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_SysAdminInventory_CALC_Master] AS RETURN 0;')
END
GO

RAISERROR('31.1 - Amending usp_SysAdminInventory_CALC_Master',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_SysAdminInventory_CALC_Master]

AS
SET NOCOUNT ON;

BEGIN

	BEGIN TRY

		DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))
			
		BEGIN TRANSACTION				

			EXEC [App].[usp_SysAdminInventory_CALC_Insert]

		COMMIT TRANSACTION

		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

		INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
		VALUES
			(
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
			);

		END CATCH
END
------SYSCONFIG INSERT VIEW
GO

IF OBJECT_ID('[App].[vw_SysConfigurations_CALC_Loading]') IS NULL
BEGIN

	RAISERROR('32.0 - Creating vw_SysConfigurations_CALC_Loading',0,1) WITH NOWAIT

	EXEC ('CREATE VIEW [App].[vw_SysConfigurations_CALC_Loading] AS SELECT '''' as v')
END
GO

RAISERROR('32.1 - Amending vw_SysConfigurations_CALC_Loading',0,1) WITH NOWAIT

GO

ALTER VIEW [App].[vw_SysConfigurations_CALC_Loading]

AS

SELECT 
	GETDATE() as CensusDate
	,Configuration_ID
	,[Name]
	,[value]
	,[minimum] 
	,[maximum]
	,[value_in_use] 
	,[description] 
	,[is_dynamic] 
	,[is_advanced]
FROM 
	sys.configurations 
------SYSCONFIG INSERT
GO

IF OBJECT_ID('[App].[usp_Sysconfigurations_CALC_Insert]') IS NULL
BEGIN

	RAISERROR('33.0 - Creating usp_Sysconfigurations_CALC_Insert',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_Sysconfigurations_CALC_Insert] AS RETURN 0;')
END
GO

RAISERROR('33.1 - Amending usp_Sysconfigurations_CALC_Insert',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_SysConfigurations_CALC_Insert]

AS

	SET NOCOUNT ON;

	BEGIN

		DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

		BEGIN TRY
			
			BEGIN TRANSACTION

				EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Inserting Data'

				INSERT INTO  [Inventory].[SysConfigurations]	
				(
					[CensusDate],
					[Configuration_ID],
					[Name],
					[value],
					[minimum], 
					[maximum], 
					[value_in_use], 
					[description], 
					[is_dynamic], 
					[is_advanced]		
				)
				SELECT
					[CensusDate], 
					[Configuration_ID],
					[Name],
					[value],
					[minimum], 
					[maximum], 
					[value_in_use], 
					[description], 
					[is_dynamic], 
					[is_advanced]
				FROM 
					[App].[vw_SysConfigurations_CALC_Loading]

				EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Data Inserted'

			COMMIT TRANSACTION

			END TRY
			BEGIN CATCH
				IF @@TRANCOUNT > 0 
				ROLLBACK TRANSACTION
				EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

				INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
			VALUES
			  (
			  SUSER_SNAME(),
			   ERROR_NUMBER(),
			   ERROR_STATE(),
			   ERROR_SEVERITY(),
			   ERROR_LINE(),
			   ERROR_PROCEDURE(),
			   ERROR_MESSAGE(),
			   GETDATE()
			   );

			END CATCH
	END
------SYSCONFIG MASTER

GO

IF OBJECT_ID('[App].[usp_Sysconfigurations_CALC_Master]') IS NULL
BEGIN

	RAISERROR('34.0 - Creating usp_Sysconfigurations_CALC_Master',0,1) WITH NOWAIT

	EXEC ('CREATE PROCEDURE [App].[usp_Sysconfigurations_CALC_Master] AS RETURN 0;')
END
GO

RAISERROR('34.1 - Amending usp_Sysconfigurations_CALC_Master',0,1) WITH NOWAIT

GO

ALTER PROCEDURE [App].[usp_SysConfigurations_CALC_Master]

AS
	SET NOCOUNT ON;

	BEGIN

		DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

		BEGIN TRY
			
			BEGIN TRANSACTION

				EXEC [App].[usp_SysConfigurations_CALC_Insert]

			COMMIT TRANSACTION

			END TRY
			BEGIN CATCH
			IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION
			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

			INSERT INTO App.SQL_Errors ([Username], [Error_Number], [ERROR_STATE], [ERROR_SEVERITY], [ERROR_LINE], [stored_Procedure], [ERROR_MESSAGE], [EventDate])
			VALUES
			  (
			  SUSER_SNAME(),
			   ERROR_NUMBER(),
			   ERROR_STATE(),
			   ERROR_SEVERITY(),
			   ERROR_LINE(),
			   ERROR_PROCEDURE(),
			   ERROR_MESSAGE(),
			   GETDATE()
			   );

			END CATCH
	END
