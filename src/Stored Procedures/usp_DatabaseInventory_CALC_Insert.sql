CREATE PROCEDURE [App].[usp_DatabaseInventory_CALC_Insert]

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