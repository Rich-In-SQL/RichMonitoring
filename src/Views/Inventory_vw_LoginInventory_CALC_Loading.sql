CREATE VIEW [App].vw_LoginInventory_CALC_Loading

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