CREATE PROCEDURE [App].[usp_DatabaseSizeInventory_CALC_Insert]

AS
	SET NOCOUNT ON;

	BEGIN

		DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

		BEGIN TRY
			
			BEGIN TRANSACTION

				EXEC [Inventory].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Inserting Data'

				INSERT INTO [Inventory].[DatabaseSize]
				(
					[CensusDate], 
					[Database_Name], 
					[Size_MB], 
					[Size_GB]
				)
				SELECT
					[CensusDate], 
					[databasename], 
					[Size_MBs], 
					[Size_GBs]
					FROM	
						[App].[vw_DatabaseSizeInventory_CALC_Loading]

			EXEC [Inventory].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Data Inserted'

			COMMIT TRANSACTION

			END TRY
			BEGIN CATCH
			IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION
			EXEC [Inventory].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'ERROR'

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