USE [Flosuite_Data_Dev]
GO
/****** Object:  StoredProcedure [dbo].[LTMM_CaseConsoleLight_Fetch]    Script Date: 09/12/2012 16:00:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[LTMM_CaseConsoleLight_Fetch]	
	@caseID int = null,
	@UserName varchar(255) = ''
AS

	-- =============================================
	-- Author:		GQL
	-- Create date: 26/08/2009
	-- Description:	TO FETCH THE VARIOUS DETAILS REQUIRED BY THE CASE CONSOLE LANDING PAGE
	-- =============================================

	-- ===============================================================
	-- Author:		SMJ
	-- Version:		2
	-- Modify date: 21-09-2012
	-- Description:	Changed error handling, added WITH (NOLOCK), added schema names
	-- ===============================================================

	--INITIALISE TESTING
	SET NOCOUNT ON
  	DECLARE @errNoUserID VARCHAR(50)
  	DECLARE @errNoCaseID VARCHAR(50)
  	DECLARE @Client_Uno INT = 0
	DECLARE @Name_Uno INT = 0
  	
  	SET @errNoUserID = 'No @UserName passed in.'
  	SET @errNoCaseID = 'No @Caseid supplied passed in.'
  	  	
	--SET DATE FORMAT TO UK FORMAT
  	SET DATEFORMAT DMY

	BEGIN TRY
		IF (@UserName = '')
			RAISERROR (@errNoUserID, 16,1)
		
		IF (@Caseid = 0)
			RAISERROR (@errNoCaseID, 16,1)	

		--CREATE TEMPORY TABLE TO HOLD RESULT SET 
		DECLARE @CaseConsoleDetails TABLE
		(
			ID [int] NOT NULL,
			Panel nvarchar(256) COLLATE DATABASE_DEFAULT NULL, 
			Column1 nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Column2 nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Column3 nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Column4 nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Column5 smalldatetime,
			Column6 nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Column7 nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Column8 nvarchar(256) COLLATE DATABASE_DEFAULT NULL	
		)

		--INSERT THE CONSOLE LITE INFO THAT CAN BE REACHED USING INNER JOINS INTO TEMP TABLE
		INSERT INTO @CaseConsoleDetails(ID, Panel, Column1, Column2, Column3, Column4, Column5, Column6, Column7, Column8)
		SELECT ID, Panel, Column1, Column2, Column3, Column4, Column5, Column6, Column7, Column8
		FROM (
		SELECT 
			cc.CaseContacts_CaseContactsID		AS ID,
			'Contacts' as Panel,	
			cc.CaseContacts_RoleCode AS Column1,
			CASE WHEN (isnull(c.Contact_Corporate,'')  = 'N')
				THEN c.[Contact_Title] + ' ' + c.[Contact_Forename] + ' ' + c.[Contact_Surname]
				ELSE c.[Contact_CompanyName]
			END as Column2,
			NULL AS Column3, 
			NULL AS Column4,					
			NULL as Column5,
			isnull(cc.CaseContacts_Reference,'') as Column6,
			L.[Description] AS Column7,
			NULL AS Column8	
		FROM dbo.CaseContacts cc WITH (NOLOCK)
			 INNER JOIN dbo.Contact c WITH (NOLOCK) ON (c.Contact_ContactID = cc.CaseContacts_ContactID) AND (c.Contact_Inactive=0)
			 INNER JOIN dbo.lookupcode L WITH (NOLOCK) ON (cc.CaseContacts_RoleCode = L.Code)
		WHERE	(cc.CaseContacts_Inactive = 0) and (cc.CaseContacts_CaseID = @CaseID)
		
		UNION 
		SELECT TOP 1
			cc.CaseContacts_CaseContactsID		AS ID,
			'Contacts' as Panel,
			'Client' AS Column1,	
			cc.CaseContacts_SearchName as Column2,
			NULL AS Column3, 
			NULL AS Column4,						
			NULL as Column5,
			ISNULL(cc.CaseContacts_Reference,'') as Column6,
			L.[Description] AS Column7,
			NULL AS Column8	
		FROM dbo.CaseContacts cc WITH (NOLOCK)
			 INNER JOIN dbo.lookupcode L WITH (NOLOCK) ON (cc.CaseContacts_RoleCode = L.Code)
		WHERE (cc.CaseContacts_Inactive = 0) and (cc.CaseContacts_CaseID = @CaseID)
		and L.Code = 'Client'
		
		UNION 
		SELECT 
			cc.CaseContacts_CaseContactsID AS ID,
			'Contacts' as Panel,
			CASE WHEN (ISNULL(c.[MatterContact_ContactType],'')) = ''
				THEN cc.CaseContacts_RoleCode
				ELSE c.MatterContact_ContactType
			END AS Column1,
			CASE WHEN (ISNULL(c.MatterContact_Corporate,'') = 'N')
				THEN c.[MatterContact_Title] + ' ' + c.[MatterContact_Forename] + ' ' + c.[MatterContact_Surname]
				ELSE c.[MatterContact_CompanyName]
			END AS Column2,
			NULL AS Column3, 
			NULL AS Column4,
			NULL as Column5,
			ISNULL(cc.CaseContacts_Reference,'') as Column6,
			L.[Description] AS Column7,
			NULL AS Column8	
		FROM	dbo.CaseContacts cc WITH (NOLOCK)
			INNER JOIN dbo.MatterContact c WITH (NOLOCK) ON (c.MatterContact_MatterContactID = cc.CaseContacts_MatterContactID) AND (ISNULL(c.MatterContact_Inactive, 0)=0)
			INNER JOIN dbo.lookupcode L WITH (NOLOCK) ON (cc.CaseContacts_RoleCode = L.Code)
		WHERE (cc.CaseContacts_Inactive = 0) and (cc.CaseContacts_CaseID = @CaseID)  
		UNION ALL	
		SELECT  TOP 20
			AppTask.AppTaskID as ID,
			'Pending' as Panel,
			AppTaskDefinition.WorkflowName as Column1,
			AssignedTo as Column2,
			AppTask.[Description] as Column3,
			AppTaskDefinition.ProcessName as Column4,
			DueDate as Column5,
			MatterPayments_Code  as Column6,	
			Apptask.Referencial_Code  as Column7,
			null as Column8
		FROM dbo.AppTask WITH (NOLOCK)
		INNER JOIN dbo.AppTaskDefinition WITH (NOLOCK) ON (AppTaskDefinition.AppTaskDefinitionCode = AppTask.AppTaskDefinitionCode)
		INNER JOIN dbo.ApplicationInstance WITH (NOLOCK) ON (ApplicationInstance.IdentifierValue = AppTask.AppInstanceValue)
		INNER JOIN dbo.AppTaskSchedule WITH (NOLOCK) ON (AppTask.AppTaskID = AppTaskSchedule.AppTaskID)
		WHERE  (AppTask.StatusCode = 'Active') AND (ApplicationInstance.CaseID = @CaseID)
		ORDER BY AppTask.DueDate 
		UNION ALL
		SELECT TOP 20
			AppTask.AppTaskID as ID,
			'History' as Panel,
			'' as Column1,
			CASE WHEN (isnull(CompletedBy,'') = '')
				THEN DeletedBy  
				ELSE CompletedBy
			END AS Column2,
			CASE WHEN (AppTask.StatusCode = 'Deleted')
				THEN 'No longer required: ' + AppTask.[Description]
				ELSE 
					AppTask.[Description]
			END AS Column3,
			'' as Column4,
			CASE WHEN (isnull(CompletedDate,'') = '')
				THEN DeletedDate   
				ELSE CompletedDate
			END AS Column5,
			null as Column6,	
			null as Column7,
			null as Column8
		FROM dbo.AppTask WITH (NOLOCK)
		INNER JOIN dbo.AppTaskDefinition WITH (NOLOCK) ON (AppTaskDefinition.AppTaskDefinitionCode = AppTask.AppTaskDefinitionCode)
		INNER JOIN dbo.ApplicationInstance WITH (NOLOCK) ON (ApplicationInstance.IdentifierValue = AppTask.AppInstanceValue)
		INNER JOIN dbo.AppTaskSchedule WITH (NOLOCK) ON (AppTask.AppTaskID = AppTaskSchedule.AppTaskID)
		WHERE  (AppTask.StatusCode = 'Complete' or AppTask.StatusCode = 'Deleted') AND (ApplicationInstance.CaseID = @CaseID) and (AppTask.DocumentID = 0)
		ORDER BY Column5  DESC,ID desc
		) AS List

		--UPDATE RESULT SET WITH CONATCT RELATIONSHIP INFO (PREVIOUSLY LEFT OUTER JOIN)
		UPDATE @CaseConsoleDetails 
		SET Column7 = r.CaseContactRelationships_CaseContactRelationshipsID,
		Column8 =	CASE 
						WHEN (x.ID = ISNULL(r.CaseContactRelationships_ParentCaseContactID,0))
						THEN 'Parent'
						WHEN (x.ID = ISNULL(r.CaseContactRelationships_ChildCaseContactID,0))
						THEN 'Child'
						ELSE NULL
					END
		FROM @CaseConsoleDetails x
		INNER JOIN CaseContactRelationships r WITH (NOLOCK) ON (x.ID = r.CaseContactRelationships_ParentCaseContactID or x.ID = r.CaseContactRelationships_ChildCaseContactID) AND r.CaseContactRelationships_Inactive = 0

		--UPDATE RESULT SET WITH CONATCT EMAIL INFO (PREVIOUSLY LEFT OUTER JOIN)
		UPDATE @CaseConsoleDetails 
		SET Column3 = ema.ContactComs_ComDetails 
		FROM @CaseConsoleDetails x
		INNER JOIN dbo.CaseContacts cc ON x.ID = cc.CaseContacts_CaseContactsID  
		INNER JOIN dbo.ContactComs ema ON cc.CaseContacts_ContactID = ema.ContactComs_ContactID and ema.ContactComs_ComType = 'PriEma' and ema.ContactComs_InActive = 0

		--UPDATE RESULT SET WITH CONATCT TELEPHONE INFO (PREVIOUSLY LEFT OUTER JOIN)
		UPDATE @CaseConsoleDetails 
		SET Column4 = tel.ContactComs_ComDetails 
		FROM @CaseConsoleDetails x
		INNER JOIN dbo.CaseContacts cc WITH (NOLOCK) ON x.ID = cc.CaseContacts_CaseContactsID 
		INNER JOIN dbo.ContactComs tel WITH (NOLOCK) ON cc.CaseContacts_ContactID = tel.ContactComs_ContactID and tel.ContactComs_ComType = 'PriTel' and tel.ContactComs_InActive = 0

		--UPDATE RESULT SET WITH CLIENT EMAIL AND TELEPHONE INFO (PREVIOUSLY LEFT OUTER JOIN)
		UPDATE @CaseConsoleDetails 
		SET Column3 = ISNULL(a._EMAIL_ADDRESS, ''),
			Column4 = ISNULL(a.PHONE_NUMBER, '') 
		FROM @CaseConsoleDetails x
		INNER JOIN dbo.CaseContacts cc WITH (NOLOCK) ON x.ID = cc.CaseContacts_CaseContactsID 
		INNER JOIN dbo.HBM_Client c WITH (NOLOCK) ON (c.CLIENT_UNO = cc.CaseContacts_ClientID) AND (c.CLIENT_UNO = @Client_Uno) --Added by CKJ 
		INNER JOIN dbo.HBM_ADDRESS a WITH (NOLOCK) ON (a.ADDRESS_UNO = c.ADDRESS_UNO)		

		--UPDATE RESULT SET WITH MATTER CONATCT EMAIL INFO (PREVIOUSLY LEFT OUTER JOIN)
		UPDATE @CaseConsoleDetails 
		SET Column3 = ema.MatterContactComs_ComDetails 
		FROM @CaseConsoleDetails x
		INNER JOIN dbo.CaseContacts cc WITH (NOLOCK) ON x.ID = cc.CaseContacts_CaseContactsID 
		INNER JOIN dbo.MatterContactComs ema WITH (NOLOCK) ON cc.CaseContacts_MatterContactID = ema.MatterContactComs_MatterContactID and ema.MatterContactComs_ComType = 'PriEma' and ema.MatterContactComs_InActive = 0

		--UPDATE RESULT SET WITH MATTER CONATCT TELEPHONE INFO (PREVIOUSLY LEFT OUTER JOIN)
		UPDATE @CaseConsoleDetails 
		SET Column4 = tel.MatterContactComs_ComDetails
		FROM @CaseConsoleDetails x
		INNER JOIN dbo.CaseContacts cc WITH (NOLOCK) ON x.ID = cc.CaseContacts_CaseContactsID 
		INNER JOIN dbo.MatterContactComs tel WITH (NOLOCK) ON cc.CaseContacts_MatterContactID = tel.MatterContactComs_MatterContactID and tel.MatterContactComs_ComType = 'PriTel' and tel.MatterContactComs_InActive = 0
			
		--RETURN FINAL DATASET
		SELECT ID, Panel, Column1, Column2, Column3, Column4, cast(Column5 as nvarchar(256)) as Column5, Column6, Column7, Column8
		FROM @CaseConsoleDetails
		ORDER BY Panel, cast(Column5 as smalldatetime)
	END TRY

	BEGIN CATCH		
		SELECT ERROR_MESSAGE() + ' SP: ' + OBJECT_NAME (@@PROCID)
	END CATCH
