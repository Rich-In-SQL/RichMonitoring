CREATE PROCEDURE [App].[usp_RunInventory]

AS

SET NOCOUNT ON;

DECLARE 
	@Count INT,
	@End INT,
	@Query NVARCHAR(1000),
	@Config varchar(50),
	@Run BIT,
	@WkUpdate VARCHAR(20),
	@mDay INT,
	@mWDay INT,
	@Proc varchar(100),
	@Complete BIT,
	@Date DATE

SET @Date = GETDATE()

SET @Config = '[Config].[Inventory]'

SET @Query = 'SELECT @Max = MAX(Convert(int,[RunOrder])) FROM ' + @Config + ' WHERE [Active] = 1'
EXEC sp_executesql @Query, N'@Max INT OUTPUT' , @Max = @End OUTPUT
SET @Count = 1

WHILE @Count <= @End
BEGIN
	SET @Run = 0
	SET @Complete = 0

	SET @Query = N'SELECT @r = Active, @sp = [StoredProcedure], @weekly = [WeeklyUpdates] FROM ' + @Config + ' WHERE [RunOrder] = @Count'
	EXEC sp_executesql @Query, N'@Count NVARCHAR(6), @r BIT OUTPUT, @sp varchar(100) OUTPUT, @Weekly varchar(20) OUTPUT', @Count = @Count, @r = @Run OUTPUT, @sp = @Proc OUTPUT, @weekly = @WkUpdate OUTPUT

	IF @Run = 1 AND @Complete = 0 
	BEGIN 
		
		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Proc, @Action = 'Begin'

		SET @Query = 'EXEC ' + @Proc

		EXEC [App].[usp_InsertRunLog] @ProcedureName = @Proc, @Action = 'End'

		IF DATEPART(d,@Date) = @mDay
		BEGIN
			
			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Proc, @Action = 'Begin'

			EXEC sp_executesql @Query

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Proc, @Action = 'End'

			SET @Complete = 1
		END
		IF SUBSTRING(@WkUpdate,App.DayOfWeekSunday(@Date) + App.DayOfWeekSunday(@Date)-1,1) = 1 AND @Complete = 0
		BEGIN

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Proc, @Action = 'Begin'

			EXEC sp_executesql @Query

			EXEC [App].[usp_InsertRunLog] @ProcedureName = @Proc, @Action = 'End'

			SET @Complete = 1
		END
	END 	

	SET @Count = @Count + 1

END

