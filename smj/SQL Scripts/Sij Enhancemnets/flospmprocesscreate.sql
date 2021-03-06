IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[flospmProcessCreate]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE  [dbo].[flospmProcessCreate]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Last modified date: <[~MODIFIED_DATE-]>
-- Last modified file: <[~MODIFIED_FILE-]>
-- Last modified file run by: <[~MODIFIED_BY-]>
-- Description: <[~DESCRIPTION-]>
-- =============================================
CREATE PROCEDURE  [dbo].[flospmProcessCreate]
(
	@myProcessDefinitionID        int = null,
	@myProcessID                  int output,
	@myProcessInsertDocument      xml,
	@myCreator					ntext,
	@myParentWorkflowName         nvarchar (256)='',
	@myParentStep                 int=NULL,
	@myParentWorkflowID           int=NULL,
	@myParentProcessID            int=NULL,
	@myWorkflowName               nvarchar(256)='',
	@ProcessDefinitionName varchar(256)=null
)
AS

	SET NOCOUNT ON

	DECLARE @myWorkflowID					int
	DECLARE	@myStartID						int
	DECLARE @myEntityID						int
	DECLARE @myProcessDefinitionName		nvarchar(256)
	DECLARE @myFlags						int
    DECLARE @myStep							int
    DECLARE @myStatus						nvarchar(256)
    DECLARE @myActivityName					nvarchar(256)
    DECLARE @myTag							nvarchar(256)
    DECLARE @myCondition					nvarchar(256)
    DECLARE @myProcessDefinitionDescription nvarchar(256)

	DECLARE @myLastError int 
	SELECT @myLastError = 0 

	IF (@myProcessDefinitionID IS NULL)
	BEGIN
		set @myProcessDefinitionID = (SELECT Min(ProcessDefinitionID) from ProcessDefinition WHERE [Name]=@ProcessDefinitionName)
	END

	BEGIN TRANSACTION

		DECLARE @XMLTable TABLE
		(
			EntityTypeID        int null,
			EntityTypeName      nvarchar(256) COLLATE database_default null,
			PropertyTypeID      int null,
			PropertyTypeName	nvarchar(256) COLLATE database_default null,
			Value				nvarchar(256) COLLATE database_default null
		)



		INSERT INTO @XMLTable
		SELECT DISTINCT
		Properties.Column1.value('@EntityTypeID', 'int'),
		Properties.Column1.value('@EntityTypeName', 'NVARCHAR(256)'),
		Properties.Column1.value('@PropertyTypeID', 'int'),
		Properties.Column1.value('@PropertyTypeName', 'NVARCHAR(256)'),
		Properties.Column1.value('@Value', 'NVARCHAR(256)')
		FROM @myProcessInsertDocument.nodes('/ChangedProperties/PropertyItem') AS Properties(Column1)


		SELECT @myLastError = @@ERROR
		IF @myLastError <> 0 GOTO THROW_ERROR_UPWARDS



-----------
-- Get process details, then insert Process and Workflow
-----------
		IF(@myWorkflowName='')
		(     
			SELECT @myProcessDefinitionName = [Name], @myWorkflowName = WorkflowName, @myProcessDefinitionDescription = [Description], @myFlags = Flags
			FROM ProcessDefinition
			WHERE ProcessDefinitionID = @myProcessDefinitionID
		)
		ELSE
		(
			SELECT @myProcessDefinitionName = [Name], @myProcessDefinitionDescription = [Description], @myFlags = Flags
			FROM ProcessDefinition
			WHERE ProcessDefinitionID = @myProcessDefinitionID
		)     

		EXEC  flospiProcess @myProcessID OUTPUT, @ProcessDefinitionID=@myProcessDefinitionID, @ProcessDefinitionName=@myProcessDefinitionName,
			@WorkflowName=@myWorkflowName, @Description=@myProcessDefinitionDescription, @Flags=@myFlags
		SELECT @myLastError = @@ERROR
		IF @myLastError <> 0 GOTO THROW_ERROR_UPWARDS

		EXEC flospiWorkflow @myWorkflowID OUTPUT, @ProcessID=@myProcessID,@ParentWorkflowName=@myParentWorkflowName, @ParentStep=@myParentStep, 
			@ParentProcessID=@myParentProcessID, @ParentWorkflowID=@myParentWorkflowID, @WorkflowName=@myWorkflowName,@Description='',@HelpFile='',@Flags='0',@Tag=''
		SELECT @myLastError = @@ERROR
		IF @myLastError <> 0 GOTO THROW_ERROR_UPWARDS

		DECLARE @Property_id int

		--Cursor Fields
		DECLARE @value nvarchar(256)
		DECLARE @propertyTypeId int
		DECLARE @ordinal int
		DECLARE @isVisible bit
		DECLARE @flags int
		DECLARE @tag nvarchar(256)
		DECLARE @label nvarchar(256)
		
		DECLARE @PTR TABLE
		(		
			value nvarchar(256) COLLATE database_default null,
			propertyTypeId int,
			ordinal int,
			isVisible bit,
			flags int,
			tag nvarchar(256) COLLATE database_default null,
			label nvarchar(256) COLLATE database_default null
		)
		
		Insert INTO @PTR
			SELECT (CASE 
                        WHEN (PropertyTypeType.Name = 'Date') AND (LEFT(upper(PropertyTypeReference.[Default]),8) = 'GETDATE(')
                              THEN dbo.flofuncRollingDate( PropertyTypeReference.[Default], getDate() )
                        ELSE PropertyTypeReference.[Default] 
                  END) AS Value, 
                  [PropertyTypeReference].[PropertyTypeID], [PropertyTypeReference].[Ordinal], [PropertyTypeReference].[IsVisible], 
                  [PropertyTypeReference].[Flags], [PropertyTypeReference].[Tag], [PropertyTypeReference].[Label]
            FROM [PropertyTypeReference] INNER JOIN [PropertyTypeReferenceInProcessDefinition] 
				ON [PropertyTypeReferenceInProcessDefinition].[PropertyTypeReferenceID] = [PropertyTypeReference].[PropertyTypeReferenceID] INNER JOIN [PropertyType]
				ON [PropertyType].[PropertyTypeID] = [PropertyTypeReference].[PropertyTypeID] INNER JOIN [PropertyTypeType]
				ON [PropertyTypeType].[PropertyTypeTypeID] = [PropertyType].[PropertyTypeTypeID]
            WHERE propertytypereferenceinprocessdefinition.processdefinitionid = @myProcessDefinitionID
        UPDATE @PTR
		  SET PTR.value = XMLTable.Value
		  FROM @PTR PTR INNER JOIN @XMLTable as XMLTable ON (XMLTable.PropertyTypeID = PTR.PropertyTypeID)
		  WHERE XmlTable.EntityTypeName=''            		
				
		--Get Data to Insert
		DECLARE myCursor CURSOR READ_ONLY
		FOR
			Select * from @PTR

		OPEN myCursor
		
		--Get First Cursor Record
		FETCH NEXT FROM myCursor
		INTO @value, @propertyTypeId, @ordinal, @isVisible, @flags, @tag, @label

		WHILE @@FETCH_STATUS = 0
		BEGIN
			  --Insert Record into Property
			  INSERT INTO dbo.Property ([Value], PropertyTypeID, Ordinal, IsVisible, Flags, Tag, Label)
			  VALUES(@value, @propertyTypeId, @ordinal, @isVisible, @flags, @tag, @label)
			  SELECT @Property_id = SCOPE_IDENTITY()

			  --Insert Record into PropertyInProcess
			  INSERT INTO dbo.PropertyInProcess(PropertyID, ProcessID)
			  VALUES ( @Property_id, @myProcessID)
		      
			  --Get Next Cursor Record
			  FETCH NEXT FROM myCursor
			  INTO @value, @propertyTypeId, @ordinal, @isVisible, @flags, @tag, @label

		END

		CLOSE myCursor
		DEALLOCATE myCursor


		--Start of Entity Cursor

		--Variables
		DECLARE @EntityTypeReferenceID int, @EntityTypeID int, @EntityID int, @PropertyID int

		--Get Entity Def
		DECLARE myEntityCursor CURSOR READ_ONLY
		FOR
		SELECT EntityTypeReference.EntityTypeReferenceID, EntityTypeReference.EntityTypeID
					FROM EntityTypeReference
					INNER JOIN EntityTypeReferenceInProcessDefinition 
						  ON (EntityTypeReferenceInProcessDefinition.EntityTypeReferenceID = EntityTypeReference.EntityTypeReferenceID)
					WHERE EntityTypeReferenceInProcessDefinition.ProcessDefinitionID = @myProcessDefinitionID

		OPEN myEntityCursor

--Get First Cursor Record
FETCH NEXT FROM myEntityCursor
INTO @EntityTypeReferenceID, @EntityTypeID

WHILE @@FETCH_STATUS = 0
BEGIN
	  --Do Stuff
		--PRINT 'Hit Entity Cursor'
	--Insert Process Entites
		INSERT INTO [Entity] ([EntityTypeID], [IsExternal], [IsGlobal], [Timestamp], [Flags], [Label], [Tag])  
            SELECT @EntityTypeID, [EntityTypeReference].[IsExternal], 0,0, [EntityTypeReference].[Flags], 
				[EntityTypeReference].[Label], [EntityTypeReference].[Tag]
            FROM [EntityTypeReference]
			WHERE [EntityTypeReference].[EntityTypeReferenceID] = @EntityTypeReferenceID

			SELECT @myLastError = @@ERROR
			IF @myLastError <> 0 GOTO THROW_ERROR_UPWARDS

			-- Get Inserted Record ID
			SELECT @EntityID = SCOPE_IDENTITY()
			
			-- Insert Entity in the BTree
			EXEC flospmEntityBTreeInsert @EntityID, NULL, NULL
			SELECT @myLastError = @@ERROR
            IF @myLastError <> 0 GOTO THROW_ERROR_UPWARDS

			-- Insert process entity EntityInProcess
			INSERT INTO EntityInProcess(EntityID, ProcessID)
			VALUES(@EntityID,@myProcessID)
			SELECT @myLastError = @@ERROR
			IF @myLastError <> 0 GOTO THROW_ERROR_UPWARDS

			-- Insert Entity properties

			--Start of ExternalEntityProperty Cursor
			DECLARE @eepValue varchar(256), @eepPropertyTypeID int, @eepOrdinal int, @eepIsVisible bit, @eepFlags int, @eepTag varchar(256), @eepLabel varchar(256)


			DECLARE myExtPropCursor CURSOR READ_ONLY
			FOR
			SELECT (CASE                         
                        WHEN (PropertyTypeType.Name = 'Date') AND (LEFT(upper(PropertyType.[Default]),8) = 'GETDATE(')
                              THEN dbo.flofuncRollingDate( PropertyType.[Default], getDate() )
                        ELSE PropertyType.[Default] 
                  END) AS Value,
                  PropertyTypeReference.PropertyTypeID, 
                  PropertyTypeReference.Ordinal, 
                  PropertyTypeReference.IsVisible, 
                  PropertyTypeReference.Flags, 
                  PropertyTypeReference.Tag, 
                  PropertyTypeReference.Label

            FROM PropertyTypeReference
            INNER JOIN PropertyTypeReferenceInExternalEntityType ON (PropertyTypeReferenceInExternalEntityType.PropertyTypeReferenceID = PropertyTypeReference.PropertyTypeReferenceID)
            INNER JOIN PropertyType ON ( PropertyType.propertytypeid =  PropertyTypeReference.propertytypeid)
            INNER JOIN PropertyTypeType ON ( PropertyTypeType.propertytypetypeid = PropertyType.propertytypetypeid)
			WHERE PropertyTypeReferenceInExternalEntityType.ExternalEntityTypeID = @EntityTypeID

			OPEN myExtPropCursor

			--Get First Cursor Record
			FETCH NEXT FROM myExtPropCursor
			INTO @eepValue, @eepPropertyTypeID, @eepOrdinal, @eepIsVisible, @eepFlags, @eepTag, @eepLabel

			WHILE @@FETCH_STATUS = 0
			BEGIN

				--PRINT 'Hit External Entity Property Cursor'
				
				INSERT INTO dbo.Property
				([Value], PropertyTypeID, Ordinal, IsVisible, Flags, Tag, Label)
				VALUES(@eepValue, @eepPropertyTypeID, @eepOrdinal, @eepIsVisible, @eepFlags, @eepTag, @eepLabel)

				SELECT @PropertyID = SCOPE_IDENTITY()

				--Property In Entity
				INSERT INTO PropertyInEntity
				(PropertyID, EntityID)
				VALUES(@PropertyID, @EntityID)

				SELECT @myLastError = @@ERROR
				IF @myLastError <> 0 GOTO THROW_ERROR_UPWARDS
				
				--Get Next Cursor Record
				FETCH NEXT FROM myExtPropCursor
				INTO @eepValue, @eepPropertyTypeID, @eepOrdinal, @eepIsVisible, @eepFlags, @eepTag, @eepLabel

			END

			CLOSE myExtPropCursor
			DEALLOCATE myExtPropCursor
			--End of ExternalEntityProperty Cursor

			--Start of InternalEntityProperty Cursor

			DECLARE myIntPropCursor CURSOR READ_ONLY
			FOR
			SELECT (CASE 
                        WHEN (PropertyTypeType.Name = 'Date') AND (LEFT(upper(PropertyType.[Default]),8) = 'GETDATE(')
                              THEN dbo.flofuncRollingDate( PropertyType.[Default], getDate() )
                        ELSE PropertyType.[Default] 
                  END) AS Value,
                  PropertyTypeReference.PropertyTypeID, 
                  PropertyTypeReference.Ordinal, 
                  PropertyTypeReference.IsVisible, 
                  PropertyTypeReference.Flags, 
                  PropertyTypeReference.Tag, 
                  PropertyTypeReference.Label
            FROM PropertyTypeReference
            INNER JOIN PropertyTypeReferenceInInternalEntityType ON (PropertyTypeReferenceInInternalEntityType.PropertyTypeReferenceID = propertytypereference.PropertyTypeReferenceID)
            INNER JOIN PropertyType ON ( PropertyType.propertytypeid =  PropertyTypeReference.propertytypeid)
            INNER JOIN PropertyTypeType ON ( PropertyTypeType.propertytypetypeid = PropertyType.propertytypetypeid)
			WHERE PropertyTypeReferenceInInternalEntityType.InternalEntityTypeID = @EntityTypeID

			OPEN myIntPropCursor

			--Get First Cursor Record
			FETCH NEXT FROM myIntPropCursor
			INTO @eepValue, @eepPropertyTypeID, @eepOrdinal, @eepIsVisible, @eepFlags, @eepTag, @eepLabel

			WHILE @@FETCH_STATUS = 0
			BEGIN

				--PRINT 'Hit Internal Entity Property Cursor'
				--Do Stuff
				INSERT INTO dbo.Property
				([Value], PropertyTypeID, Ordinal, IsVisible, Flags, Tag, Label)
				VALUES(@eepValue, @eepPropertyTypeID, @eepOrdinal, @eepIsVisible, @eepFlags, @eepTag, @eepLabel)

				SELECT @PropertyID = SCOPE_IDENTITY()

				--Property In Entity
				INSERT INTO PropertyInEntity
				(PropertyID, EntityID)
				VALUES(@PropertyID, @EntityID)

				SELECT @myLastError = @@ERROR
				IF @myLastError <> 0 GOTO THROW_ERROR_UPWARDS
				
				--Get Next Cursor Record
				FETCH NEXT FROM myIntPropCursor
				INTO @eepValue, @eepPropertyTypeID, @eepOrdinal, @eepIsVisible, @eepFlags, @eepTag, @eepLabel
			END

			CLOSE myIntPropCursor
			DEALLOCATE myIntPropCursor

			--End of InternalEntityProperty Cursor


	  --Get Next Cursor Record
      FETCH NEXT FROM myEntityCursor
      INTO @EntityTypeReferenceID, @EntityTypeID

END

CLOSE myEntityCursor
DEALLOCATE myEntityCursor
--End of Entity Cursor

      --update any properties beneath process level entities
	  IF EXISTS(SELECT	1
				FROM	@XMLTable as XMLTable
				WHERE	 XmlTable.EntityTypeName<>'')
	  BEGIN		  
		  UPDATE Property
		  SET Property.Value = XMLTable.Value
		  FROM Property
		  INNER JOIN PropertyInEntity ON (PropertyInEntity.PropertyID = Property.PropertyID)
		  INNER JOIN EntityInProcess ON (EntityInProcess.EntityID = PropertyInEntity.EntityID)
		  INNER JOIN @XMLTable as XMLTable ON (XMLTable.PropertyTypeID = Property.PropertyTypeID)
			  WHERE EntityInProcess.ProcessID = @myProcessID AND XmlTable.EntityTypeName<>''

		  SELECT @myLastError = @@ERROR
		  IF @myLastError <> 0 GOTO THROW_ERROR_UPWARDS
	  END

		--make sure result table is updated with creator information 
      DECLARE @ResultID int
      
      exec flospiResultInProcess @ResultID output, @myProcessID, @myCreator, ''

      SELECT @myLastError = @@ERROR
      IF @myLastError <> 0 GOTO THROW_ERROR_UPWARDS

      --PRINT 'result id'
      --PRINT @ResultID


/*
**********************************
End of Replacement Insert Entity Code
**********************************
*/

GOTO FINISHED_OKAY

THROW_ERROR_UPWARDS:
      ROLLBACK TRANSACTION
	IF @myLastError <> 0    
	      BEGIN
            	DECLARE @myLastErrorMessage NVARCHAR(MAX)
				SET @myLastErrorMessage = (SELECT @myProcessDefinitionID as PROCESSID,
						  		@myCreator as Creator,
								@myParentWorkflowName as ParentWorkflowName,
								@myParentStep as ParentStep,
								@myParentWorkflowID as ParentWorkflowID,
								@myParentProcessID as ParentProcessID,
								@myWorkflowName as WORKFLOWNAME
            	FOR XML PATH ('Error'))       

            	RAISERROR (@myLastErrorMessage, 16,1)
	      END
      RETURN

FINISHED_OKAY:
      COMMIT TRANSACTION      


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

