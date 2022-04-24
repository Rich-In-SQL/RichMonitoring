CREATE PROCEDURE [App].[usp_BackupInventory_CALC_Insert]

AS

	SET NOCOUNT ON;

	BEGIN

		DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

		BEGIN TRY
			
			BEGIN TRANSACTION

				EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Inserting Data'

				INSERT INTO  [Inventory].[Backups]	
				(
					[CensusDate], 
					[Server], 
					[backup_availability], 
					[name], 
					[database_version], 
					[database_version_desc], 
					[recovery_model], 
					[is_copy_only], 
					[is_damaged], 
					[is_password_protected], 
					[backup_start_date], 
					[backup_finish_date], 
					[backup_type], 
					[backup_size], 
					[BackupSizeMB], 
					[BackupSizeGB], 
					[physical_device_name], 
					[backupset_name], 
					[user_name]			
				)
				SELECT
					[CensusDate], 
					[Server], 
					[backup_availability], 
					[name], 
					[database_version], 
					[database_version_desc], 
					[recovery_model], 
					[is_copy_only], 
					[is_damaged], 
					[is_password_protected], 
					[backup_start_date], 
					[backup_finish_date], 
					[backup_type], 
					[backup_size], 
					[BackupSizeMB], 
					[BackupSizeGB], 
					[physical_device_name], 
					[backupset_name], 
					[user_name]
				FROM 
					[App].[vw_BackupInventory_CALC_Loading]

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