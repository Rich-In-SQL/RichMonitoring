
CREATE VIEW [App].[vw_DatabaseSizeInventory_CALC_Loading]

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
