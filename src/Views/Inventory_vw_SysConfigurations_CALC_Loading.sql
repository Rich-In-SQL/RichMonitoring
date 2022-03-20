CREATE VIEW [App].vw_SysConfigurations_CALC_Loading

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