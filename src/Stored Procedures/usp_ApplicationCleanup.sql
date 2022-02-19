CREATE PROCEDURE [App].[usp_ApplicationCleanup]

AS

SET NOCOUNT ON

BEGIN 
	BEGIN TRY
		BEGIN TRANSACTION

			DECLARE 
				@Me VARCHAR(64),
				@Days INT
			
			SET @Me = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))
			SET @Days = (SELECT INTValue FROM [Config].[AppConfig] WHERE ConfigName = 'Clean Up' AND Active = 1)

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Begin'

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from DatabaseFiles'

			DELETE FROM [Inventory].[DatabaseFiles] WHERE CensusDate < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from Databases'

			DELETE FROM [Inventory].[Databases] WHERE CensusDate < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from DatabaseSize'

			DELETE FROM [Inventory].[DatabaseSize] WHERE CensusDate < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from Jobs'

			DELETE FROM [Inventory].[Jobs] WHERE CensusDate < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from Logins'

			DELETE FROM [Inventory].[Logins] WHERE CensusDate < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from Objects'

			DELETE FROM [Inventory].[Objects] WHERE CensusDate < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from RunLog'

			DELETE FROM [Inventory].[RunLog] WHERE [EventDate] < DATEADD(dd,@Days,GETDATE())

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Deleting old records from SysAdmins'

			DELETE FROM [Inventory].[SysAdmins] WHERE CensusDate < DATEADD(dd,@Days,GETDATE())

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