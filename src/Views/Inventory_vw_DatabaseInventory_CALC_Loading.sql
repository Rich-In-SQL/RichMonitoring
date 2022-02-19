CREATE VIEW [App].vw_DatabaseInventory_CALC_Loading

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