CREATE PROCEDURE [App].[usp_SysAdminInventory_CALC_Insert]

AS
	SET NOCOUNT ON;

	BEGIN

		DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

		BEGIN TRY
			
			BEGIN TRANSACTION

				EXEC [App].[usp_InsertRunLog] @ProcedureName = '[dbo].[usp_DatabaseInventory_CALC_Insert]', @Action = 'Inserting Data'

				INSERT INTO Inventory.SysAdmins
				(
					CensusDate ,
					[Server_Name] ,
					[LoginName],
					[sid], 
					[Login_Type], 
					[Disabled],  
					[create_date], 
					[modify_date] 
				)
				SELECT
					CensusDate,
					[Server_Name],
					[LoginName], 
					[sid], 
					[Login_Type], 
					[Disabled],  
					[create_date], 
					[modify_date]
					FROM	
						[App].[vw_SysAdminInventory_CALC_Loading]

				EXEC [App].[usp_InsertRunLog] @ProcedureName = '[dbo].[usp_DatabaseInventory_CALC_Insert]', @Action = 'Data Inserted'

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