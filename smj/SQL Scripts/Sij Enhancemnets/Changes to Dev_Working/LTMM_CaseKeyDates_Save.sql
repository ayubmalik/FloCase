

ALTER PROC [dbo].[LTMM_CaseKeyDates_Save]
(
	@CaseKeyDates_CaseKeyDatesID	int = 0,
	@CaseKeyDates_CaseID			int = 0,
	@CaseKeyDates_KeyDatesCode		nvarchar(10) = '',
	@CaseKeyDates_Date				smalldatetime = NULL,
	@CaseKeyDates_CaseContactsID	int = 0,
	@CaseKeyDates_OutlookObjectID	varchar(255) = '',
	@pInactive						bit = 0,
	@pUsername						nvarchar(255),
	@pMakeOtherKDSameTypeInactive	bit = 0,
	@pReturnID						bit = 1 -- GV 13/10: added to stop returning the Case Key Date ID if not required
)
AS

	--Stored Procedure to either insert a new Key Date or update an Existing one
	--Author(s) Craig Jones and GQL
	--17-07-2009
	--GQL - Completely rewriten to allow multiple keydates of the same type
	--09-09-2011
	-- ===============================================================
	-- Author:		SMJ
	-- Version:		2
	-- Modify date: 24-09-2012
	-- Description:	Changed error handling, added WITH (NOLOCK), added schema names
	-- ==============================================================	
	
		-- ===============================================================
	-- Author:		CKJ
	-- Version:		3
	-- Modify date: 04-10-2012
	-- Description:	Added History item when trial window has been removed
	-- ==============================================================	
	
	SET NOCOUNT ON
	DECLARE @AppTaskID int = 0
	DECLARE @OldCaseKeyDates_CaseKeyDatesID INT = 0
	DECLARE @MaxKeyDateID INT
	DECLARE @errNoUserName VARCHAR(50) -- SMJ	

	SET @errNoUserName = 'YOU MUST PROVIDE A @UserName.'

	BEGIN TRY
	
		---Test to see that a username has been supplied
		IF (ISNULL(@pUsername,'') = '') AND (@CaseKeyDates_KeyDatesCode <> 'NA')
			RAISERROR (@errNoUserName, 16, 1)
		
		BEGIN TRANSACTION CaseKeyDatesSave	
		
		--IF THE KEY DATE IS DATE LAST ACCESSED GET THE CaseKeyDates_CaseKeyDatesID OF TEH CURRENT LIVE VALUE FOR THAT TO PREVENT DUPLICATION
		IF ISNULL(@CaseKeyDates_KeyDatesCode, '') = 'CaseAcc'
		BEGIN
			SELECT  @CaseKeyDates_CaseKeyDatesID = CaseKeyDates_CaseKeyDatesID 
			FROM dbo.CaseKeyDates WITH (NOLOCK)
			WHERE CaseKeyDates_KeyDatesCode = 'CaseAcc' AND CaseKeyDates_Inactive = 0 AND CaseKeyDates_CaseID = @CaseKeyDates_CaseID 
		END
		
		--ENSURE THAT WE ARE NOT DUPLICATING A SPECIFIC KEY DATE FOR A SPECIFIC CONTACT
		IF ISNULL(@CaseKeyDates_CaseContactsID, 0) > 0
		BEGIN
			SELECT TOP 1 @CaseKeyDates_CaseKeyDatesID = ISNULL(CaseKeyDates_CaseKeyDatesID, 0) 
			FROM dbo.CaseKeyDates WITH (NOLOCK)
			WHERE CaseKeyDates_CaseContactsID = @CaseKeyDates_CaseContactsID 
			AND CaseKeyDates_KeyDatesCode = @CaseKeyDates_KeyDatesCode
			AND CaseKeyDates_CaseID = @CaseKeyDates_CaseID 			
			ORDER BY CaseKeyDates_CaseKeyDatesID DESC	
		END
		
		
		--RPM 5.16 START
		--if the key date is trial set trail window start and finish to inactive
		IF ISNULL(@CaseKeyDates_KeyDatesCode, '') = 'Trial'
		BEGIN
		
			--CKJ Added check for trial window and wrote history item
			IF (EXISTS (SELECT CaseKeyDates.CaseKeyDates_CaseContactsID
						FROM CaseKeyDates
						WHERE (CaseKeyDates_KeyDatesCode = 'TrlWndwSrt' OR CaseKeyDates_KeyDatesCode = 'TrlWndwEnd')
						AND CaseKeyDates_CaseID = @CaseKeyDates_CaseID ))
			BEGIN
				UPDATE dbo.CaseKeyDates 
				SET CaseKeyDates_Inactive = 1
				WHERE (CaseKeyDates_KeyDatesCode = 'TrlWndwSrt' OR CaseKeyDates_KeyDatesCode = 'TrlWndwEnd')
					AND CaseKeyDates_CaseID = @CaseKeyDates_CaseID 
				
	
				EXEC AppTask_Complete
					@UserName				= @pUserName,
					@CompletedBy			= @pUserName,
					@AppTaskDefinitionCode	= 'KeyDate',
					@pAppTaskSubTypeCode	= 'Trial',
					@CaseID					= @CaseKeyDates_CaseID,
					@Description			= 'Trial Window key dates removed as a result of Trial Date key date'
			END
				
				
			UPDATE dbo.AppTask 
			SET StatusCode='Complete', 
				CompletedBy=@pUsername,
				CompletedDate=GETDATE()
			FROM CaseKeyDates c WITH (NOLOCK)
			inner join AppTask a WITH (NOLOCK) on c.CaseKeyDates_CaseKeyDatesID = a.KeyDateID 
			WHERE c.CaseKeyDates_CaseID = @CaseKeyDates_CaseID  
				and a.AppTaskTypeCode='KeyDate'
				and (c.CaseKeyDates_KeyDatesCode = 'TrlWndwSrt' or c.CaseKeyDates_KeyDatesCode = 'TrlWndwEnd')
				
			IF @pMakeOtherKDSameTypeInactive = 1 and @pInactive = 1
				UPDATE dbo.AppTask 
				SET StatusCode='Complete', 
					CompletedBy=@pUsername,
					CompletedDate=GETDATE()
				FROM dbo.CaseKeyDates c WITH (NOLOCK)
				inner join dbo.AppTask a WITH (NOLOCK) on c.CaseKeyDates_CaseKeyDatesID = a.KeyDateID 
				WHERE c.CaseKeyDates_CaseID = @CaseKeyDates_CaseID  
					and a.AppTaskTypeCode='KeyDate'
					and c.CaseKeyDates_KeyDatesCode = 'Trial' 
				
		END
		
		IF ISNULL(@CaseKeyDates_KeyDatesCode, '') = 'TrlWndwSrt' 
		BEGIN
				UPDATE dbo.CaseKeyDates SET CaseKeyDates_Inactive = 1
				WHERE CaseKeyDates_KeyDatesCode = 'Trial' and CaseKeyDates_CaseID = @CaseKeyDates_CaseID 
				
				update dbo.AppTask set StatusCode='Complete', CompletedBy=@pUsername,CompletedDate=GETDATE()
				from dbo.CaseKeyDates c WITH (NOLOCK)
				inner join dbo.AppTask a WITH (NOLOCK) on c.CaseKeyDates_CaseKeyDatesID = a.KeyDateID 
				where c.CaseKeyDates_CaseID = @CaseKeyDates_CaseID  
				and a.AppTaskTypeCode='KeyDate'
				and c.CaseKeyDates_KeyDatesCode = 'Trial'
				
				IF @pMakeOtherKDSameTypeInactive = 1 and @pInactive = 1
					update dbo.AppTask set StatusCode='Complete', CompletedBy=@pUsername,CompletedDate=GETDATE()
					from dbo.CaseKeyDates c WITH (NOLOCK)
					inner join dbo.AppTask a WITH (NOLOCK) on c.CaseKeyDates_CaseKeyDatesID = a.KeyDateID 
					where c.CaseKeyDates_CaseID = @CaseKeyDates_CaseID  
					and a.AppTaskTypeCode='KeyDate'
					and(c.CaseKeyDates_KeyDatesCode = 'TrlWndwSrt' or c.CaseKeyDates_KeyDatesCode = 'TrlWndwEnd')
		END
		
		IF ISNULL(@CaseKeyDates_KeyDatesCode, '') = 'TrlWndwEnd' 
		BEGIN
				UPDATE dbo.CaseKeyDates SET CaseKeyDates_Inactive = 1
				WHERE CaseKeyDates_KeyDatesCode = 'Trial' and CaseKeyDates_CaseID = @CaseKeyDates_CaseID 
		END	
		--RPM 5.16 END		
			
		
		--update all other keydates of the same type so that we dont have duplicates ones
		--this was causing a problem when trying to close a case if there was already a close date active
		IF ISNULL(@pMakeOtherKDSameTypeInactive,0) > 0 
		BEGIN		
			UPDATE dbo.CaseKeyDates SET CaseKeyDates_Inactive = 1
			WHERE CaseKeyDates_KeyDatesCode = @CaseKeyDates_KeyDatesCode
			and CaseKeyDates_CaseID = @CaseKeyDates_CaseID 	
		END		
				
		--if we are adding a new keydate
		IF ISNULL(@CaseKeyDates_CaseKeyDatesID, 0) = 0 AND ISNULL(@CaseKeyDates_Date, '') <> '' --AND ISNULL(@CaseKeyDates_Date, '') <> '1900-01-01 00:00:00'
		BEGIN	
		
			INSERT INTO [dbo].[CaseKeyDates]
				([CaseKeyDates_CaseID]
				,[CaseKeyDates_KeyDatesCode]
				,[CaseKeyDates_Date]
				,[CaseKeyDates_CaseContactsID]
				,[CaseKeyDates_OutlookObjectID]
				,[CaseKeyDates_Inactive]
				,[CaseKeyDates_CreateUser]
				,[CaseKeyDates_CreateDate])
			VALUES
				(@CaseKeyDates_CaseID,
				@CaseKeyDates_KeyDatesCode,
				@CaseKeyDates_Date, 
				@CaseKeyDates_CaseContactsID, 
				@CaseKeyDates_OutlookObjectID, 
				0,
				@pUsername,
				GETDATE())
				   
			SET @CaseKeyDates_CaseKeyDatesID	= SCOPE_IDENTITY()

		END
		ELSE
		BEGIN
			
				UPDATE dbo.CaseKeyDates SET CaseKeyDates_Inactive = 1
				WHERE CaseKeyDates_CaseKeyDatesID = @CaseKeyDates_CaseKeyDatesID
				
				SELECT @AppTaskID = ISNULL(AppTask.AppTaskID,0)
				FROM dbo.AppTask WITH (NOLOCK)
				WHERE AppTask.KeyDateID = @CaseKeyDates_CaseKeyDatesID
			
			
			IF ISNULL(@pInactive, 0) = 0  AND ISNULL(@CaseKeyDates_Date, '') <> '' AND ISNULL(@CaseKeyDates_Date, '') <> '1900-01-01 00:00:00'
			BEGIN
				INSERT INTO [dbo].[CaseKeyDates]
					([CaseKeyDates_CaseID]
					,[CaseKeyDates_KeyDatesCode]
					,[CaseKeyDates_Date]
					,[CaseKeyDates_CaseContactsID]
					,[CaseKeyDates_OutlookObjectID]
					,[CaseKeyDates_Inactive]
					,[CaseKeyDates_CreateUser]
					,[CaseKeyDates_CreateDate])
				VALUES
					(@CaseKeyDates_CaseID,
					@CaseKeyDates_KeyDatesCode,
					@CaseKeyDates_Date, 
					@CaseKeyDates_CaseContactsID, 
					@CaseKeyDates_OutlookObjectID, 
					@pInactive,
					@pUsername,
					GETDATE())
				   
				set @OldCaseKeyDates_CaseKeyDatesID = @CaseKeyDates_CaseKeyDatesID
				set @CaseKeyDates_CaseKeyDatesID	= SCOPE_IDENTITY()
				
				UPDATE dbo.AppTask SET KeyDateID = @CaseKeyDates_CaseKeyDatesID WHERE KeyDateID = @OldCaseKeyDates_CaseKeyDatesID 
				
			END
			ELSE
			BEGIN
				IF ISNULL(@CaseKeyDates_CaseKeyDatesID, 0) > 0
				BEGIN
					UPDATE dbo.AppTask
					SET AppTask.StatusCode = 'Deleted',
						AppTask.CompletedBy = @pUsername,
						AppTask.CompletedDate = GETDATE()
					WHERE KeyDateID = @CaseKeyDates_CaseKeyDatesID
				END
			END
		END
	
		COMMIT TRANSACTION CaseKeyDatesSave
		
		IF @pReturnID = 1
			SELECT @CaseKeyDates_CaseKeyDatesID AS CaseKeyDates_CaseKeyDatesID		
			
	END TRY
		
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION CaseKeyDatesSave
			
		SELECT ERROR_MESSAGE() + ' SP: ' + OBJECT_NAME(@@PROCID)
	END CATCH


