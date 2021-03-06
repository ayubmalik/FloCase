IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[flospiPropertyInEntity]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[flospiPropertyInEntity]
GO

-- =============================================
-- Last modified date: <11/Jul/2012 14:53:02>
-- Last modified file: <7.2.960.002.core.flospipropertyinentity>
-- Last modified file run by: <rpm>
-- Description: insert a property into an entity
-- =============================================
CREATE PROCEDURE [dbo].[flospiPropertyInEntity]	
(
	@PropertyID			int=NULL OUTPUT,
	@EntityID			int,
	@PropertyTypeName	nvarchar(256)=NULL,
	@PropertyTypeID		int=NULL,
	@Value				ntext='',
	@Ordinal			int=0,
	@IsVisible			bit=0,
	@Flags				int=0,
	@Label				nvarchar(256)='',
	@Tag				nvarchar(256)=''
)
																	
AS
	SET NOCOUNT ON
	
	SET @PropertyID = NULL

	DECLARE @myLastError int 
	SET @myLastError = 0 
	
DECLARE @RetryCount INT
SET @RetryCount = 0
	
RETRY_INSERT:--Retry Label
	BEGIN TRANSACTION
	BEGIN TRY
		EXEC flospmGetPropertyTypeInfo @PropertyTypeName=@PropertyTypeName OUTPUT, @PropertyTypeID=@PropertyTypeID OUTPUT
		SELECT @myLastError = @@ERROR
		IF @myLastError <> 0 GOTO THROW_ERROR_UPWARDS

		/* Validate whether or not the record exists */
		IF NOT EXISTS(SELECT 1 FROM Entity	
					INNER JOIN [PropertyInEntity] ON [PropertyInEntity].[EntityID] = [Entity].[EntityID] 
					INNER JOIN [Property] ON [Property].[PropertyID] = [PropertyInEntity].[PropertyID] 
					INNER JOIN [PropertyType] ON [Property].[PropertyTypeID] = [PropertyType].[PropertyTypeID]
					WHERE [PropertyInEntity].[EntityID] = @EntityID AND [PropertyType].[Name] = @PropertyTypeName)
		BEGIN
			EXEC flospiProperty @PropertyID=@PropertyID OUTPUT, @PropertyTypeName=@PropertyTypeName, @PropertyTypeID=@PropertyTypeID OUTPUT, @Value=@Value, @Ordinal=@Ordinal, @IsVisible=@IsVisible, @Flags=@Flags, @Label=@Label, @Tag=@Tag

			INSERT INTO PropertyInEntity	(PropertyID,  EntityID)
			VALUES (@PropertyID,  @EntityID)
			SELECT @myLastError = @@ERROR
		END
	COMMIT TRANSACTION
	
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		IF ((ERROR_NUMBER() = 1205) AND (@RetryCount <= 5)) --Deadlock error
		BEGIN
			SET @RetryCount = @RetryCount + 1
			WAITFOR DELAY '00:00:00:05'--Wait for 5ms
			GOTO RETRY_INSERT--Goto retry label
		END
	END CATCH

THROW_ERROR_UPWARDS:
IF @myLastError <> 0    
      BEGIN
        	DECLARE @myLastErrorMessage NVARCHAR(MAX)
			SET @myLastErrorMessage = (SELECT @EntityID as EntityID,
					 @PropertyTypeName as PropertyTypeName,
					 @PropertyTypeID as PropertyTypeID,
					 @IsVisible as IsVisible,
					 @Ordinal as Ordinal,
					 @Flags as Flags,
					 @Label as Label,
					 @Tag as Tag
        	FOR XML PATH ('Error'))       

        	RAISERROR (@myLastErrorMessage, 16,1)
      END



GO




