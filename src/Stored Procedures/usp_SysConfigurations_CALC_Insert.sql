CREATE PROCEDURE [App].[usp_SysConfigurations_CALC_Insert]

AS

	SET NOCOUNT ON;

	BEGIN

		DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

		BEGIN TRY
			
			BEGIN TRANSACTION

				EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Inserting Data'

				INSERT INTO  [Inventory].[SysConfigurations]	
				(
					[CensusDate],
					[Configuration_ID],
					[Name],
					[value],
					[minimum], 
					[maximum], 
					[value_in_use], 
					[description], 
					[is_dynamic], 
					[is_advanced]		
				)
				SELECT
					[CensusDate], 
					[Configuration_ID],
					[Name],
					[value],
					[minimum], 
					[maximum], 
					[value_in_use], 
					[description], 
					[is_dynamic], 
					[is_advanced]
				FROM 
					[App].[vw_SysConfigurations_CALC_Loading]

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