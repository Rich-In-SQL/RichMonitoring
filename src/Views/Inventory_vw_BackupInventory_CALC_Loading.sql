CREATE VIEW [App].[vw_BackupInventory_CALC_Loading]

AS

	SELECT 

		GETDATE() as CensusDate
		,CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server 
		,CASE 
			WHEN bkset.database_name IS NULL THEN 'No Backup Available'
			ELSE 'Backup Available'
		END AS backup_availability
		,d.name
		,bkset.database_version
		,CASE 
			WHEN bkset.database_version = 904 THEN 'SQL Server 2019 CTP 3.2 / RC 1 / RC 1.1 / RTM'
			WHEN bkset.database_version = 902 THEN 'SQL Server 2019 CTP 3.0 / 3.1'
			WHEN bkset.database_version = 897 THEN 'SQL Server 2019 CTP 2.3 / 2.4 / 2.5'
			WHEN bkset.database_version = 896 THEN 'SQL Server 2019 CTP 2.1 / 2.2'
			WHEN bkset.database_version = 895 THEN 'SQL Server 2019 CTP 2.0'
			WHEN bkset.database_version = 868 THEN 'SQL Server 2017'
			WHEN bkset.database_version = 869 THEN 'SQL Server 2017'
			WHEN bkset.database_version = 852 THEN 'SQL Server 2016'
			WHEN bkset.database_version = 782 THEN 'SQL Server 2014'
			WHEN bkset.database_version = 706 THEN 'SQL Server 2012'
			WHEN bkset.database_version = 684 THEN 'SQL Server 2012 CTP1'
			WHEN bkset.database_version = 661 THEN 'SQL Server 2008 R2'
			WHEN bkset.database_version = 660 THEN 'SQL Server 2008 R2'
			WHEN bkset.database_version = 655 THEN 'SQL Server 2008'
			WHEN bkset.database_version = 612 THEN 'SQL Server 2005 SP2+ with VarDecimal enabled'
			WHEN bkset.database_version = 611 THEN 'SQL Server 2005'
			WHEN bkset.database_version = 539 THEN 'SQL Server 2000'
			WHEN bkset.database_version = 515 THEN 'SQL Server 7.0'
			WHEN bkset.database_version = 408 THEN 'SQL Server 6.5'
			WHEN bkset.database_version = 406 THEN 'SQL Server 6.0' 
		END AS database_version_desc
		,bkset.recovery_model
		,is_copy_only
		,is_damaged
		,is_password_protected
		,bkset.backup_start_date 
		,bkset.backup_finish_date 
		,CASE bkset.type 
			WHEN 'D' THEN 'Database' 
			WHEN 'L' THEN 'Log' 
			WHEN 'I' THEN 'Differential database'
		END AS backup_type
		,bkset.backup_size 
		,CAST(bkset.backup_size / 1048576 AS DECIMAL(10, 2) ) AS [BackupSizeMB]
		,CAST(COALESCE(bkset.backup_size,0)/1024.00/1024.00/1024.00 AS NUMERIC(18,2))  AS [BackupSizeGB]
		,bmf.physical_device_name
		,bkset.name AS backupset_name
		,bkset.user_name
	FROM 
		master.dbo.sysdatabases d

	LEFT JOIN msdb.dbo.backupset bkset ON 
		bkset.database_name = d.name

	LEFT JOIN msdb.dbo.backupmediafamily bmf
		ON bkset.media_set_id = bmf.media_set_id

	--ORDER BY 
	--	bkset.backup_finish_date desc