
ALTER PROC [dbo].[LTMM_Offers_Save]
(
	@pOffers_OfferCode					nvarchar(255) = '',		--Input A
	@pOffers_OfferSourceCode			nvarchar(10) = '',		--Input B 
	@pOffers_OfferTypeCode				nvarchar(10) = '',		--Input C
	@pOffers_OfferRelationCode			nvarchar(10) = '',		--Input D 
	@pOffers_OfferMoneyValue			money = 0,				--Input E
	@pOffers_OfferPercentageValue		int = 0,				--Input F
	@pOffers_OfferDate					smalldatetime = '',		--Input G
	@pOffers_OfferAccepted				bit = 0,				--Input H
	@pOffers_CaseContactID				int = 0,				--Input I
	@pOffers_Description				varchar(255)= '',		--Input J
	@pOffers_ExpiryDate					smalldatetime = Null,	--Input K
	@pOffers_ChaserDate					smalldatetime= '',		--Input L
	@pOffers_ProdCliRep					bit = 0,				--Input M	
	@pOffers_Inactive					bit = 0,				--Input N
	@pUserName							nvarchar(255) = '',		--Input O	
	@pOffers_CostsOfferToBLM			bit = 0,
	@pOffers_SupervisionStatus			nvarchar(50) = '',
	@pOffers_OfferLetterProduced		bit = 0,
	@pOffers_OfferReceivedDate			smalldatetime = ''
)
AS
	-- =============================================
	-- Author:		GQL
	-- Create date: 06-10-2011
	-- This stored proc is used to add edit or delete Offer details 
	-- associated with a specified Contact.
	-- To add new Offer Details pass in inputs B-O with N = 0
	-- To edit existing Offer Details pass in inputs A-O with N = 0
	-- To delete existing Offer Details pass in inputs A and N with N = 1
	-- =============================================
	
	-- =============================================
	-- Author:		SMJ
	-- Modify date: 11-10-2011
	-- Changed SP to accommodate new fields in table
	-- =============================================	
	
	-- =============================================
	-- Modified by:		GV
	-- Modify date: 11/04/2012
	-- Changed SP to accommodate new offer key date
	-- =============================================	
	
	-- =============================================
	-- Modified by:		SMJ
	-- Modify date: 23/04/2012
	-- Changed SP to make sure an Offer Date has been passed in 
	--	if updating CaseKeydates
	-- =============================================	
		-- =============================================
	-- Modified by:		GV
	-- Modify date: 13/09/2012
	-- ticket 24783: removed pending tasks from Offer workflow
	-- Pending tasks are only created once the task is approved
	-- =============================================	
	
	--Initialise error trapping
	SET NOCOUNT ON
		
	DECLARE @errInsertDD						VARCHAR (255)
	DECLARE @errInsertNoName					VARCHAR (255)
	DECLARE @errInsertNoReps					VARCHAR (255)
	DECLARE @errInvalidCode						VARCHAR (255)
	DECLARE @0FFERINT							int -- Used to generate a new Part 8 record code
	DECLARE @CaseKeyDatesID						int
	DECLARE @CaseID								int
	DECLARE @OriginalOfferAccepted				bit  -- GV 13/09/2012: ticket 247837
	DECLARE @OriginalChaserDate					smalldatetime -- GV 13/09/2012: ticket 247837
	
	--Set error messages
	SELECT	@errInsertDD =	'Couldn''t insert new record into Offers table. SP: '
			,@errInsertNoName = 'User name must be supplied. SP: '
			,@errInsertNoReps = 'CaseContactID for a Contact must be supplied. SP: '
			,@errInvalidCode = 'The Offer_Code supplied does not exist. SP: '
			,@OriginalOfferAccepted = 0 -- GV 13/09/2012: ticket 247837
			,@OriginalChaserDate = '' -- GV 13/09/2012: ticket 247837
	
	BEGIN TRANSACTION OffersSaveAll
		
	BEGIN TRY
	
	--Do some checking
	IF isnull(@pUserName, '') = ''
		RAISERROR (@errInsertNoName, 16, 1)
		
	IF isnull(@pOffers_CaseContactID, 0) = 0
		RAISERROR (@errInsertNoReps, 16, 1)
		
	IF (isnull(@pOffers_OfferCode, '') <> '') AND (NOT EXISTS(SELECT * FROM Offers WHERE Offers_OfferCode = @pOffers_OfferCode))
		RAISERROR (@errInvalidCode, 16, 1)
	
	--IF WE ARE EDITING EXISTING Offer DETAILS
	IF ISNULL(@pOffers_OfferCode, '') <> ''
	BEGIN	
		SELECT @CaseKeyDatesID = CaseKeyDatesID
			  ,@OriginalOfferAccepted = [Offers_OfferAccepted]
			  ,@OriginalChaserDate = Offers_ChaserDate
		FROM Offers
		WHERE Offers_OfferCode = @pOffers_OfferCode 
		AND Offers_Inactive = 0
		
		--SET CURRENT RECORD AS INACTIVE
		UPDATE Offers  
		SET Offers_Inactive = 1, 
		Offers_WithDrawalDate = GETDATE(),
		Offers_CreateUser = @pUserName 
		WHERE Offers_OfferCode = @pOffers_OfferCode AND Offers_Inactive = 0
		
		IF @@ROWCOUNT = 0 
		   RAISERROR (@errInsertDD,16,1)	   
	END
	--ELSE WE ARE CREATING BRAND new Offer DETAILS
	ELSE
	BEGIN		
		--GENERATE A NEW Offer DETAILS CODE IN THE FORMAT CLOfferXXXXXXXX 
		SELECT @0FFERINT = 
			ISNULL(MAX(CAST(replace(Offers_OfferCode, 'OFFER', '') AS INT)), 0) + 1 
		FROM Offers  
		
		SET @pOffers_OfferCode = 'OFFER' + RIGHT('0000000'+ CONVERT(VARCHAR,@0FFERINT),8)				
	END
	
	--IF WE ARE NOT SETTING THE CURRENT RECORD AS INACTIVE
	IF ISNULL(@pOffers_Inactive, 0) <> 1
	BEGIN
		--INSERT THE NEW RECORD		
		INSERT INTO Offers
           ([Offers_OfferCode]
           ,[Offers_OfferSourceCode]
           ,[Offers_OfferTypeCode]
           ,[Offers_OfferRelationCode]
           ,[Offers_OfferMoneyValue]
           ,[Offers_OfferPercentageValue]
           ,[Offers_OfferDate]
           ,[Offers_OfferAccepted]
           ,[Offers_CaseContactID]
           ,[Offers_Description]
           ,[Offers_ExpiryDate]
           ,[Offers_ChaserDate]
           ,[Offers_ProduceClientReport]
           ,[Offers_Inactive]           
           ,[Offers_CreateUser]
           ,[Offers_CreateDate]
           ,[Offers_CostsOfferToBLM]
           ,[Offers_SupervisionStatus]
           ,[Offers_OfferLetterProduced]
           ,[Offers_OfferReceivedDate])
     VALUES
           (@pOffers_OfferCode,
           @pOffers_OfferSourceCode,
           @pOffers_OfferTypeCode,
           @pOffers_OfferRelationCode,
           @pOffers_OfferMoneyValue,
           @pOffers_OfferPercentageValue,
           @pOffers_OfferDate,
           @pOffers_OfferAccepted,
           @pOffers_CaseContactID,
           @pOffers_Description,
           @pOffers_ExpiryDate,
           @pOffers_ChaserDate,
           @pOffers_ProdCliRep,
           @pOffers_Inactive,           
           @pUserName,
           Getdate(),
           @pOffers_CostsOfferToBLM,
           @pOffers_SupervisionStatus,
           @pOffers_OfferLetterProduced,
           @pOffers_OfferReceivedDate)
           
			
			IF @@ROWCOUNT = 0 
				RAISERROR (@errInsertDD,16,1)
	END
	
	SELECT TOP 1 @CaseID = CaseContacts_CaseID
	FROM CaseContacts
	WHERE CaseContacts_CaseContactsID = @pOffers_CaseContactID
	AND CaseContacts_Inactive = 0
		
	-->> START GV 10/10/2012: Get Client Rule for AppReqMakeOffer
	DECLARE @ClientRuleCode nvarchar(255)
	DECLARE @TLCode nvarchar(256)
	SELECT @ClientRuleCode = Case_ClientRuleCode, @TLCode = tl.UserName	
	FROM [Case] AS c LEFT JOIN dbo.AppUser AS tl ON tl.AppInstanceValue = c.Case_BLMREF AND tl.AppUserRoleCode = 'TL' AND tl.InActive = 0 
	WHERE Case_CaseID = @CaseID

	DECLARE @AppReqMakeOffer nvarchar(20)
	SELECT @AppReqMakeOffer = ClientRuleSet_Value
	FROM ClientRuleSet
	WHERE ClientRuleSet_ClientRuleCode = @ClientRuleCode
	AND ClientRuleSet_InActive = 0
	AND ClientRuleSet_ClientRuleDefinitionCode = 'AppReqMakeOffer'	
	--<< END GV 10/10/2012

	-->> START GV 11/04/2012: added code to deal with offer key date
	-->> IF @pOffers_OfferDate <> '' AND @pOffers_OfferAccepted = 1 --SMJ 23/04/2012 -- GV 14/9/12: added >>AND @pOffers_OfferAccepted = 1<<-- GV 10/10/12: replaced the IF statement
	IF  (@pOffers_OfferDate <> '' AND @pOffers_OfferAccepted = 1) OR
		(@pOffers_OfferDate <> '' AND ISNULL(@AppReqMakeOffer,'') <> 'Yes') OR
		(@pOffers_OfferDate <> '' AND @TLCode = @pUserName)
	BEGIN

		EXECUTE [LTMM_CaseKeyDates_Save] 
		   @CaseKeyDates_CaseKeyDatesID = @CaseKeyDatesID
		  ,@CaseKeyDates_CaseID = @CaseID
		  ,@CaseKeyDates_KeyDatesCode = 'OfExpDate'
		  ,@CaseKeyDates_Date = @pOffers_OfferDate
		  ,@CaseKeyDates_CaseContactsID = @pOffers_CaseContactID
		  ,@pInactive = 0
		  ,@pUsername = @pUserName
		  ,@pMakeOtherKDSameTypeInactive = 0
		  -- PBA to check for existing offers
		  ,@pOfferMultiCheck = 1
		  ,@pReturnID = 0

		SELECT TOP 1 @CaseKeyDatesID = CaseKeyDates_CaseKeyDatesID
		FROM CaseKeyDates
		WHERE CaseKeyDates_CaseContactsID = @pOffers_CaseContactID
		ORDER BY CaseKeyDates_CaseKeyDatesID DESC
		
		UPDATE Offers
		SET CaseKeyDatesID = @CaseKeyDatesID
		WHERE [Offers_OfferCode] = @pOffers_OfferCode
		AND [Offers_Inactive] = 0
		
		DECLARE @AppTaskID int
		DECLARE @AppInstanceValue nvarchar(50)			
		DECLARE @today datetime
		SELECT @today = GetDate()
		
		SELECT TOP 1 @AppInstanceValue = IdentifierValue
		FROM ApplicationInstance
		WHERE CaseID = @CaseID
		
		SELECT TOP 1 @AppTaskID = AppTaskID 
		FROM AppTask 
		WHERE AppInstanceValue = @AppInstanceValue
		AND AppTaskDefinitionCode = N'CreateReminder'
		AND StatusCode = 'Active'
		AND ContactID = @pOffers_CaseContactID
		AND KeyDateID = @CaseKeyDatesID
		AND [Description] LIKE 'Key Date: Offer Expiry Date%'
		
		DECLARE @DueDate smalldatetime
		DECLARE @CaseLawyer nvarchar(256)
		DECLARE @Description nvarchar(256)

		SELECT TOP 1 @CaseLawyer = UserName
		FROM AppUser 
		WHERE AppInstanceValue = @AppInstanceValue
		AND (AppUserRoleCode = 'FES' OR AppUserRoleCode = 'CFE')
		AND InActive = 0
		ORDER BY AppUserRoleCode
		
		if ISNULL(@pOffers_ExpiryDate, '') = ''
		begin 
			SELECT @DueDate = getdate()
		end
		else
		begin
			SELECT @DueDate = DATEADD(DAY, -7, @pOffers_ExpiryDate)
		end

		SELECT @Description = 'Key Date: Offer Expiry Date ' + isnull(CONVERT(nvarchar(30),@pOffers_ExpiryDate,103), '')
				
		-- if reminder task already exists then reschedule ELSE create pending
		IF ISNULL(@AppTaskID,0) = 0
		BEGIN
			EXEC AppTask_CreatePending
				@UserName = @pUserName,
				@AssignedTo = @CaseLawyer,
				@AppTaskDefinitionCode = N'CreateReminder',
				@AppInstanceValue = @AppInstanceValue,
				@CaseID = @CaseId,
				@CreatedBy = @pUserName,
				@Description = @Description,
				@DueDate = @DueDate,
				@CaseContactID = @pOffers_CaseContactID,
				@pAppTaskSubTypeCode = N'Offers',
				@pPriorityCode = N'Normal',
				@KeyDateID = @CaseKeyDatesID,
				@StartScheduleDate = @today,
				@EndScheduleDate = @DueDate,
				@pRoleCode = 'FES,FEJ',
				@pReturnID = 0		
		END
		ELSE
		BEGIN 
			EXEC AppTask_Reschedule
				@pAppTaskID = @AppTaskID,
				@pDescription = @Description,
				@pUserName = @pUserName,
				@pDueDate = @DueDate,
				@pStartScheduleDate = @today,
				@pEndScheduleDate = @DueDate,
				@pPriorityCode = N'Normal',
				@pReturnID = 0
		END
		
		-- ~>> START GV 13/09/2012: ticket 247837
		DECLARE @ClaimName nvarchar(250)
		SELECT @ClaimName = CaseContacts_SearchName
		FROM CaseContacts
		WHERE CaseContacts_CaseContactsID = @pOffers_CaseContactID
		AND	CaseContacts_Inactive = 0

		IF (@OriginalOfferAccepted <> @pOffers_OfferAccepted AND @pOffers_OfferAccepted = 1) OR
			(ISNULL(@AppReqMakeOffer,'') <> 'Yes')		OR
			(@pOffers_OfferDate <> '' AND @TLCode = @pUserName)
		BEGIN
			
			SELECT @Description = 'Reminder: Respond to offer made by ' + @ClaimName + ', Offer Expires on ' + isnull(CONVERT(nvarchar(30),@pOffers_ExpiryDate,103), '')
		
			IF @pOffers_OfferSourceCode = 'OFFERBLM'
			BEGIN 
				SELECT @Description = 'Check Offer Acceptance for ' + @pOffers_Description + ', Offer Expires on ' + isnull(CONVERT(nvarchar(30),@pOffers_ExpiryDate,103), '')
			END
			
			SELECT TOP 1 @AppTaskID = AppTaskID 
			FROM AppTask 
			WHERE AppInstanceValue = @AppInstanceValue
			AND AppTaskDefinitionCode = N'CreateReminder'
			AND StatusCode = 'Active'
			AND ContactID = @pOffers_CaseContactID
			AND KeyDateID = @CaseKeyDatesID
			AND [Description] LIKE '%Offer Expires on %'
			AND AppTaskSubTypeCode = 'Offers'
			
			IF ISNULL(@AppTaskID,0) = 0
			BEGIN	
				EXEC AppTask_CreatePending
					@UserName = @pUserName,
					@AssignedTo = @CaseLawyer,
					@AppTaskDefinitionCode = N'CreateReminder',
					@AppInstanceValue = @AppInstanceValue,
					@CaseID = @CaseId,
					@CreatedBy = @pUserName,
					@Description = @Description,
					@DueDate = @DueDate,
					@CaseContactID = @pOffers_CaseContactID,
					@pComment = null,
					@pAppTaskSubTypeCode = N'Offers',
					@pPriorityCode = N'Normal',
					@pReferencialCode = 'Main Console Offer History',
					@pRoleCode = 'CFE',
					@KeyDateID = @CaseKeyDatesID,
					@StartScheduleDate = @today,
					@EndScheduleDate = @DueDate,
					@pReturnID = 0	
			END
			ELSE			
			BEGIN					
				EXEC AppTask_Reschedule
					@pAppTaskID = @AppTaskID,
					@pDescription = @Description,
					@pUserName = @pUserName,
					@pDueDate = @DueDate,
					@pStartScheduleDate = @today,
					@pEndScheduleDate = @DueDate,
					@pPriorityCode = N'Normal',
					@pReturnID = 0
			END	
		END
		
		IF (@pOffers_ChaserDate <> '' AND @pOffers_OfferAccepted = 1) OR
			(@pOffers_ChaserDate <> '' AND ISNULL(@AppReqMakeOffer,'') <> 'Yes') OR
			(@pOffers_OfferDate <> '' AND @TLCode = @pUserName)
		BEGIN
			IF @pOffers_OfferMoneyValue <> 0
				SELECT @Description = ISNULL('£' + CONVERT(varchar(12),@pOffers_OfferMoneyValue,1), '')
			ELSE
				SELECT @Description = ISNULL(CONVERT(varchar(12),@pOffers_OfferPercentageValue,1) + '%', '')
			
			SELECT @Description = ISNULL(@ClaimName + ' ','') +  @Description 
			
			IF @pOffers_OfferSourceCode = 'OFFERBLM'
			BEGIN 
				SELECT @Description = 'Reminder: Chase offer made to ' + @Description
			END
			ELSE 
			BEGIN
				SELECT @Description = 'Chase Response to offer made by ' + @Description
			END
			
			SELECT TOP 1 @AppTaskID = AppTaskID 
			FROM AppTask 
			WHERE AppInstanceValue = @AppInstanceValue
			AND AppTaskDefinitionCode = N'CreateReminder'
			AND StatusCode = 'Active'
			AND ContactID = @pOffers_CaseContactID
			AND KeyDateID = @CaseKeyDatesID
			AND [Description] LIKE '%offer made%'
			AND AppTaskSubTypeCode = 'Reminder'
			
			IF ISNULL(@AppTaskID,0) = 0
			BEGIN		
				EXEC AppTask_CreatePending
					@UserName = @pUserName,
					@AssignedTo = @CaseLawyer,
					@AppTaskDefinitionCode = N'CreateReminder',
					@AppInstanceValue = @AppInstanceValue,
					@CaseID = @CaseId,
					@CreatedBy = @pUserName,
					@Description = @Description,
					@DueDate = @pOffers_ChaserDate,
					@CaseContactID = @pOffers_CaseContactID,
					@pComment = null,
					@pAppTaskSubTypeCode = N'Reminder',
					@pPriorityCode = N'Normal',
					@pReferencialCode = @pOffers_OfferCode,
					@pRoleCode = 'CFE',
					@KeyDateID = @CaseKeyDatesID,
					@StartScheduleDate = @today,
					@EndScheduleDate = @pOffers_ChaserDate,
					@pReturnID = 0	
			END
			ELSE
			BEGIN					
				EXEC AppTask_Reschedule
					@pAppTaskID = @AppTaskID,
					@pDescription = @Description,
					@pUserName = @pUserName,
					@pDueDate = @DueDate,
					@pStartScheduleDate = @today,
					@pEndScheduleDate = @DueDate,
					@pPriorityCode = N'Normal',
					@pReturnID = 0
			END	
		END 
		-- << END GV 13/09/2012: ticket 247837
	END
	--<< END GV 11/04/2012 	
	
	COMMIT TRANSACTION OffersSaveAll
			
	SELECT @pOffers_OfferCode AS Offers_OfferCode

	END TRY

	BEGIN CATCH
		SELECT (ERROR_MESSAGE() + object_name(@@procid)) AS Error
		ROLLBACK TRANSACTION OffersSaveAll
	END CATCH
	



