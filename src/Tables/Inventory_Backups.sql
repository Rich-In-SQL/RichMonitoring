CREATE TABLE [Inventory].[Backups]
(
	[CensusDate] [datetime] NOT NULL,
	[Server] [char](100) NULL,
	[backup_availability] [varchar](19) NOT NULL,
	[name] [sysname] NULL,
	[database_version] [int] NULL,
	[database_version_desc] [varchar](45) NULL,
	[recovery_model] [nvarchar](60) NULL,
	[is_copy_only] [bit] NULL,
	[is_damaged] [bit] NULL,
	[is_password_protected] [bit] NULL,
	[backup_start_date] [datetime] NULL,
	[backup_finish_date] [datetime] NULL,
	[backup_type] [varchar](21) NULL,
	[backup_size] [numeric](20, 0) NULL,
	[BackupSizeMB] [decimal](10, 2) NULL,
	[BackupSizeGB] [numeric](18, 2) NULL,
	[physical_device_name] [nvarchar](260) NULL,
	[backupset_name] [nvarchar](128) NULL,
	[user_name] [nvarchar](128) NULL
)