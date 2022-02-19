
CREATE VIEW [App].[vw_SysAdminInventory_CALC_Loading]

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
