CREATE PROCEDURE [App].[usp_InsertRunLog]

@ProcedureName nvarchar(128),
@Action varchar(100)

AS

BEGIN
	BEGIN TRY
		BEGIN TRANSACTION

			INSERT INTO [Inventory].[RunLog] (ProcedureName, Action)
			VALUES
			(@ProcedureName,@Action)
		
		COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION
	END CATCH
END