
ALTER PROCEDURE [dbo].[LTMM_PreTrialPrepDirections_Fetch]
	(
		@pCaseID INT =  0,
		@pPreTrialPrepCode AS nVarchar(255) = '',
		@pPreTrialPrep_CourtCaseContactID INT =  0,
		@pUserName AS nVarchar(10) = ''
	)
	
	-- ==========================================================================================
	-- GQL - CREATED - 10-10-2011
	-- Fetch court directions that are subject to pre-trial review 
	-- If an existing PreTrialPrepCode is passed existing values stored are returned 
	-- with any applicable directions added post update apended, 
	-- otherwise a blank slate is returned
	-- =========================================================================================	
	
		-- ==========================================================================================
	-- CKJ - Changed - 3-10-2012 
	-- Allowed inactive key dates to be show in list with no @pPreTrialPrepCode
	-- =========================================================================================
	-- ===============================================================
	-- Author:		SMJ
	-- Version:		3
	-- Modify date: 03-10-2012
	-- Description:	Just added WITH (NOLOCK) and schema names
	-- ===============================================================	
AS

	SET NOCOUNT ON
	
	DECLARE @errNoCaseID VARCHAR(50)
	DECLARE @errNoUser VARCHAR(50)
	DECLARE @errCourt VARCHAR(50)
	DECLARE @errInvalidCode VARCHAR(50)

	SELECT @errNoCaseID = 'No Case ID passed in.'
	SELECT @errNoUser = 'No UserCode passed in.'
	SELECT @errCourt = 'No Court CaseContactID passed in.'
	SELECT @errInvalidCode = 'The @pPreTrialPrepCode does not exist in the database'
	
	BEGIN TRY

		--Do some error checking
		IF @pCaseID <= 0
			RAISERROR(@errNoCaseID,16,1)
		
		if isnull(@pUserName, '') = ''
			RAISERROR(@errNoUser,16,1)
			
		if isnull(@pPreTrialPrep_CourtCaseContactID, '') = ''
			RAISERROR(@errCourt,16,1)
		
		IF (isnull(@pPreTrialPrepCode, '') <> '') AND (NOT EXISTS(SELECT 1 FROM dbo.PreTrialPrep WITH (NOLOCK) WHERE PreTrialPrep_PreTrialPrepCode = @pPreTrialPrepCode and PreTrialPrep_Inactive = 0))
			RAISERROR (@errInvalidCode, 16, 1)
						
		IF ISNULL(@pPreTrialPrepCode, '') <> ''
		BEGIN
			SELECT
			shape.[Direction Description],
			shape.[Due Date],
			shape.[Compied With],
			shape.CaseKeyDates_CaseKeyDatesID 
			FROM
				(SELECT t.[Description] as [Direction Description], ck.CaseKeyDates_Date as [Due Date], p.PreTrialPrepDirections_Complied as [Compied With], ck.CaseKeyDates_CaseKeyDatesID 
				  FROM dbo.PreTrialPrepDirections p WITH (NOLOCK)  inner join
				  dbo.CaseKeyDates ck WITH (NOLOCK)  on ck.CaseKeyDates_CaseKeyDatesID = p.PreTrialPrepDirections_CaseKeyDateID and p.PreTrialPrepDirections_Inactive = 0 inner join
				  dbo.KeyDatesType t WITH (NOLOCK)  on ck.CaseKeyDates_KeyDatesCode = t.Code and t.Inactive = 0
				where p.PreTrialPrepDirections_PreTrialPrepCode = @pPreTrialPrepCode 
				UNION
				SELECT t.[Description] as [Direction Description], ck.CaseKeyDates_Date as [Due Date], 0 as [Compied With], ck.CaseKeyDates_CaseKeyDatesID
				  FROM dbo.CaseKeyDates ck WITH (NOLOCK)  inner join
				  dbo.KeyDatesType t WITH (NOLOCK)  on ck.CaseKeyDates_KeyDatesCode = t.Code and t.Inactive = 0
				where ck.CaseKeyDates_CaseKeyDatesID NOT IN (select PreTrialPrepDirections_CaseKeyDateID from PreTrialPrepDirections where PreTrialPrepDirections_PreTrialPrepCode = @pPreTrialPrepCode and PreTrialPrepDirections_Inactive = 0)
				AND ck.CaseKeyDates_CaseID = @pCaseID and ck.CaseKeyDates_Inactive = 0 and ck.CaseKeyDates_CaseContactsID = @pPreTrialPrep_CourtCaseContactID
				and ck.CaseKeyDates_KeyDatesCode not in ('Trial', 'TrlWndwSrt', 'TrlWndwEnd')) AS shape
			order by shape.[Direction Description] 
		END
		ELSE
		BEGIN
			SELECT t.[Description] as [Direction Description], ck.CaseKeyDates_Date as [Due Date], 0 as [Compied With], ck.CaseKeyDates_CaseKeyDatesID
				  FROM dbo.CaseKeyDates ck WITH (NOLOCK)  inner join
				  dbo.KeyDatesType t WITH (NOLOCK)  on ck.CaseKeyDates_KeyDatesCode = t.Code --and t.Inactive = 0
				where ck.CaseKeyDates_CaseID = @pCaseID and ck.CaseKeyDates_Inactive = 0 and ck.CaseKeyDates_CaseContactsID = @pPreTrialPrep_CourtCaseContactID 
				and ck.CaseKeyDates_KeyDatesCode not in ('Trial', 'TrlWndwSrt', 'TrlWndwEnd')
			order by t.[Description]
		END
		
	END TRY	
	
	BEGIN CATCH
		SELECT ERROR_MESSAGE() + ' SP: ' + OBJECT_NAME(@@PROCID)
	END CATCH
	
