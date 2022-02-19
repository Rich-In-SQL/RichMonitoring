CREATE PROCEDURE [App].[usp_SQLJobInventory_CALC_Insert]

AS
	SET NOCOUNT ON;

	BEGIN

		DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

		BEGIN TRY
			
			BEGIN TRANSACTION

				EXEC [App].[usp_InsertRunLog] @ProcedureName = '[dbo].[usp_DatabaseInventory_CALC_Insert]', @Action = 'Inserting Data'

				INSERT INTO Inventory.Jobs
				(
					[CensusDate], 
					[JobName], 
					[job_id], 
					[enabled], 
					[start_step_id], 
					[step_id], 
					[step_name], 
					[subsystem], 
					[command], 
					[On_Success], 
					[On_Failure], 
					[schedule_id], 
					[FrequencyType], 
					[Interval], 
					[freq_type], 
					[DailyFrequency], 
					[Interval2], 
					[StartTime], 
					[EndTime]
				)
				SELECT
					[CensusDate], 
					[JobName], 
					[job_id], 
					[enabled], 
					[start_step_id], 
					[step_id], 
					[step_name], 
					[subsystem], 
					[command], 
					[On_Success], 
					[On_Failure], 
					[schedule_id], 
					[FrequencyType], 
					[Interval], 
					[freq_type], 
					[DailyFrequency], 
					[Interval2], 
					[StartTime], 
					[EndTime]
					FROM	
						App.vw_SQLJobInventory_CALC_Loading

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