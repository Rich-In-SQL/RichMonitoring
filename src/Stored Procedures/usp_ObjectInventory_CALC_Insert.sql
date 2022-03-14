CREATE PROCEDURE [App].[usp_ObjectInventory_CALC_Insert]

AS
	SET NOCOUNT ON;

	BEGIN
		
		DECLARE @Me VARCHAR(64) = CONCAT(OBJECT_SCHEMA_NAME(@@PROCID), '.',OBJECT_NAME(@@PROCID))

		BEGIN TRY
			BEGIN TRANSACTION				

				DECLARE @SqlQuery varchar(4000)				

				SET @SqlQuery =
				'USE ?

				INSERT INTO [RichMonitoring].[Inventory].[Objects] (DatabaseName,ParentObjectName,ObjectName,ObjectDefinition,SchemaName,ObjectType,ObjectTypeDescription,create_date,modify_date)
				SELECT
				DB_NAME() as DatabaseName,
				OBJECT_NAME(p.parent_object_id) ParentObjectName,
				p.name as ObjectName,
				OBJECT_DEFINITION(object_id),
				s.name as SchemaName,
				type,
				type_desc,
				create_date,
				modify_date

				FROM sys.objects p

				INNER JOIN sys.schemas s ON p.schema_id = s.schema_id

				WHERE
					is_ms_shipped = 0'

				EXEC [App].[usp_InsertRunLog] @ProcedureName = @Me, @Action = 'Inserting Data'

				EXEC sp_MSforeachdb @SqlQuery
				
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