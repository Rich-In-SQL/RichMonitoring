CREATE PROCEDURE [App].[usp_DatabaseFileInventory_CALC_Insert]

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