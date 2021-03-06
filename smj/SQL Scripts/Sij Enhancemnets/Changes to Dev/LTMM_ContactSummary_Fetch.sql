USE [Flosuite_Data_Dev]
GO
/****** Object:  StoredProcedure [dbo].[LTMM_ContactSummary_Fetch]    Script Date: 09/11/2012 16:10:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[LTMM_ContactSummary_Fetch] 

	@CaseContactID int = 0,
	@MatterContactID int = 0,
	@ContactID int = 0,
	@ClientID int = 0,
	@UserName nvarchar(255) = null
AS

	-- =============================================
	-- Author:		SSCF
	-- Create date: 31/08/2012
	-- Description:	Depending on the input the information will come from different sources
	--				If MatterContactID or ContactID are used, matter specific info is not avaialable
	--				It is a CaseContact that has been selected from the search screen
	--				New contacts that are created from scratch already have CaseContact information
	-- =============================================
	
	-- ===============================================================
	-- Author:		SMJ
	-- Version:		2
	-- Modify date: 24-09-2012
	-- Description:	Changed error handling, added WITH (NOLOCK), added schema names
	-- ===============================================================		

	SET NOCOUNT ON
	DECLARE @Client_Uno INT = 0
	DECLARE @Name_Uno INT = 0
	DECLARE @Client_Name nvarchar(255)	
	DECLARE @errNoIDPassedIn VARCHAR(100)
	
	SET @errNoIDPassedIn = 'Please pass in @CaseContactID or @MatterContactID or @ContactID or @ClientID.'
	
	BEGIN TRY
	
		--Check an ID has been passed in
		IF @CaseContactID = 0 AND @MatterContactID = 0 AND @ContactID = 0 AND @ClientID = 0
			RAISERROR (@errNoIDPassedIn, 16, 1)
	
		declare @results table
		(
			ContactID int,
			ContactSource nvarchar(20),
			Name nvarchar(255),
			[Address] nvarchar(1000),
			Email nvarchar(255),
			Phone nvarchar(255),
			Fax nvarchar(255),
			ContactTypeCode nvarchar(255), 
			Reference nvarchar(255),
			RefHeading nvarchar(500),
			Blockbook nvarchar(10),
			Expertise nvarchar(255),
			Region nvarchar(255),
			SecondaryContactType nvarchar(255),
			Corporate nvarchar(1)
		)
		
		if (@CaseContactID <> 0)
		BEGIN
		
			declare @SourceContactID int
			declare @ContactType int
			
			select @SourceContactID = 
				Case when (isnull(casecontacts_contactid,0) <> 0) then casecontacts_contactid
					 when (isnull(CaseContacts_ClientID,0) <> 0) then CaseContacts_ClientID
					 else casecontacts_mattercontactid 
				end,
					 
				@ContactType = 
				Case when (isnull(casecontacts_contactid,0) <> 0) then 0 --Contact
					 when (isnull(casecontacts_mattercontactid,0) <> 0) then 1 --MatterContact
					 else 2 --HBM_Client
				end 
			from dbo.CaseContacts WITH (NOLOCK) where CaseContacts_CaseContactsID = @CaseContactID


			if(@ContactType = 1)
			BEGIN
				insert into @results
				select @SourceContactID,
				'MatterContact',
				[dbo].[ConcatenateMatterContactName](@SourceContactID) as Name,
				[dbo].[ConcatenateMatterContactAddress](@SourceContactID) as [Address],
				mcc1.MatterContactComs_ComDetails as Email,
				mcc2.MatterContactComs_ComDetails as Phone,
				mcc3.MatterContactComs_ComDetails as Fax,
				cc.CaseContacts_RoleCode as ContactTypeCode,
				cc.CaseContacts_Reference as Reference,
				cc.CaseContacts_ContactRefHeading as RefHeading,
				'' as Blockbook,
				'' as Expertise,
				'' as Region,
				cc.SecondaryContactType,
				mc.MatterContact_Corporate as Corporate
				FROM dbo.CaseContacts cc WITH (NOLOCK)
				inner join dbo.MatterContact mc WITH (NOLOCK)
				on cc.CaseContacts_MatterContactID = mc.MatterContact_MatterContactID
				left join dbo.MatterContactComs mcc1 WITH (NOLOCK)
				on mcc1.MatterContactComs_MatterContactID = cc.CaseContacts_MatterContactID
				and mcc1.MatterContactComs_ComType = 'PriEma'
				and mcc1.MatterContactComs_InActive = 0
				left join dbo.MatterContactComs mcc2 WITH (NOLOCK)
				on mcc2.MatterContactComs_MatterContactID = cc.CaseContacts_MatterContactID
				and mcc2.MatterContactComs_ComType = 'PriTel'
				and mcc2.MatterContactComs_InActive = 0
				left join dbo.MatterContactComs mcc3 WITH (NOLOCK)
				on mcc3.MatterContactComs_MatterContactID = cc.CaseContacts_MatterContactID
				and mcc3.MatterContactComs_ComType = 'PriFax'
				and mcc3.MatterContactComs_InActive = 0	
				where cc.CaseContacts_CaseContactsID = @CaseContactID
			END	
			ELSE IF @ContactType = 0
			BEGIN
					insert into @results 
					select @SourceContactID,
					'Contact',			
					[dbo].[ConcatenateContactName](@SourceContactID,0) as Name,
					[dbo].[ConcatenateContactAddress](@SourceContactID) as [Address],
					cc1.ContactComs_ComDetails as Email,
					cc2.ContactComs_ComDetails as Phone,
					cc3.ContactComs_ComDetails as Fax,
					cc.CaseContacts_RoleCode as ContactTypeCode,
					cc.CaseContacts_Reference as Reference,
					cc.CaseContacts_ContactRefHeading as RefHeading,
					c.Contact_Blockbook as Blockbook,
					c.Contact_FieldOfExpertise as Expertise,
					c.Contact_RegionCode as Region,
					cc.SecondaryContactType,
					c.Contact_Corporate as Corporate
					FROM dbo.CaseContacts cc WITH (NOLOCK)
					inner join dbo.Contact c WITH (NOLOCK)
					on cc.CaseContacts_ContactID = c.Contact_ContactID
					left join dbo.ContactComs cc1 WITH (NOLOCK)
					on cc1.ContactComs_ContactID = cc.CaseContacts_ContactID
					and cc1.ContactComs_ComType = 'PriEma'
					and cc1.ContactComs_InActive = 0
					left join dbo.ContactComs cc2 WITH (NOLOCK)
					on cc2.ContactComs_ContactID = cc.CaseContacts_ContactID
					and cc2.ContactComs_ComType = 'PriTel'
					and cc2.ContactComs_InActive = 0
					left join ContactComs cc3 WITH (NOLOCK)
					on cc3.ContactComs_ContactID = cc.CaseContacts_ContactID
					and cc3.ContactComs_ComType = 'PriFax'
					and cc3.ContactComs_InActive = 0	
					where cc.CaseContacts_CaseContactsID = @CaseContactID						
				END
			ELSE IF @ContactType = 2
				BEGIN
					--- Get the Aderant Unos. --Added by CKJ
					SELECT @Name_Uno = cl.NAME_UNO, @Client_Name = cl.CLIENT_NAME
					FROM dbo.HBM_CLIENT cl WITH (NOLOCK)
					WHERE (cl.CLIENT_UNO = @SourceContactID)  AND (cl.INACTIVE = 'N')
				
				
					insert into @results 
					select 
						@SourceContactID AS ContactID,			
						'HBM_Client' As ContactSource,			
						@Client_Name AS Name,
						[dbo].[ConcatenateClientAddress](@Name_Uno) as [Address],
						a._EMAIL_ADDRESS as Email,
						a.PHONE_NUMBER as Phone,
						a.FAX_NUMBER as Fax,
						cc.CaseContacts_RoleCode as ContactTypeCode,
						cc.CaseContacts_Reference as Reference,
						cc.CaseContacts_ContactRefHeading as RefHeading,
						'' as Blockbook,
						'' as Expertise,
						a.REGION_CODE as Region,
						cc.SecondaryContactType,
					CASE WHEN n.NAME_TYPE = 'P' THEN 'N'
					ELSE 'Y' END AS Corporate
					FROM dbo.CaseContacts cc WITH (NOLOCK)
					INNER JOIN dbo.HBM_ADDRESS a WITH (NOLOCK) ON (a.NAME_UNO = @Name_Uno)  AND (a.INACTIVE = 'N' )
					INNER JOIN dbo.HBM_NAME n WITH (NOLOCK) ON (n.NAME_UNO = a.NAME_UNO) AND  (n.NAME_UNO = @Name_Uno)  AND (n.INACTIVE = 'N')	
					where cc.CaseContacts_CaseContactsID = @CaseContactID	
						AND cc.CaseContacts_Inactive = 0	

				END
		END
		ELSE IF (@MatterContactID <> 0)
		BEGIN
			insert into @results
			select @MatterContactID AS ContactID,			
			'MatterContact' As ContactSource,			
			[dbo].[ConcatenateMatterContactName](@MatterContactID) as Name,
			[dbo].[ConcatenateMatterContactAddress](@MatterContactID) as [Address],
			mcc1.MatterContactComs_ComDetails as Email,
			mcc2.MatterContactComs_ComDetails as Phone,
			mcc3.MatterContactComs_ComDetails as Fax,
			'' as ContactTypeCode,
			'' as Reference,
			'' as RefHeading,
			'' as Blockbook,
			'' as Expertise,
			'' as Region,
			'' as SecondaryContactType,
			mc.MatterContact_Corporate as Corporate
			FROM dbo.MatterContact mc WITH (NOLOCK)
			left join dbo.MatterContactComs mcc1 WITH (NOLOCK) 
			on mcc1.MatterContactComs_MatterContactID = mc.MatterContact_MatterContactID
			and mcc1.MatterContactComs_ComType = 'PriEma'
			and mcc1.MatterContactComs_InActive = 0
			left join dbo.MatterContactComs mcc2 WITH (NOLOCK)
			on mcc2.MatterContactComs_MatterContactID = mc.MatterContact_MatterContactID
			and mcc2.MatterContactComs_ComType = 'PriTel'
			and mcc2.MatterContactComs_InActive = 0
			left join MatterContactComs mcc3 WITH (NOLOCK)
			on mcc3.MatterContactComs_MatterContactID = mc.MatterContact_MatterContactID
			and mcc3.MatterContactComs_ComType = 'PriFax'
			and mcc3.MatterContactComs_InActive = 0	
			where mc.MatterContact_MatterContactID = @MatterContactID
		END
		ELSE IF (@ClientID <> 0)		
			BEGIN	
				SELECT @Name_Uno = cl.NAME_UNO, @Client_Name = cl.CLIENT_NAME
				FROM dbo.HBM_CLIENT cl  WITH (NOLOCK)
				WHERE (cl.CLIENT_UNO = @ClientID)
					
					
				insert into @results					
				select 
					@ClientID AS ContactID,			
					'HBM_Client' As ContactSource,			
					@Client_Name as Name,
					[dbo].[ConcatenateClientAddress](@Name_Uno) as [Address],
					a._EMAIL_ADDRESS as Email,
					a.PHONE_NUMBER as Phone,
					a.FAX_NUMBER as Fax,
					'' as ContactTypeCode,
					'' as Reference,
					'' as RefHeading,
					'' as Blockbook,
					'' as Expertise,
					a.REGION_CODE as Region,
					'' AS SecondaryContactType,
					CASE WHEN n.NAME_TYPE = 'P' THEN 'N'
						ELSE 'Y' END AS Corporate				
				FROM dbo.HBM_NAME n WITH (NOLOCK)
				INNER JOIN dbo.HBM_ADDRESS a WITH (NOLOCK) ON (a.NAME_UNO = n.NAME_UNO) AND (a.NAME_UNO = @Name_Uno) AND (a.INACTIVE = 'N' )
				where (n.NAME_UNO  = @Name_Uno) AND (n.INACTIVE = 'N')	 
					
			END	
		ELSE IF (@ContactID <> 0)
		BEGIN
				insert into @results
				select @ContactID,
				'Contact',			
				[dbo].[ConcatenateContactName](@ContactID,0) as Name,
				[dbo].[ConcatenateContactAddress](@ContactID) as [Address],
				cc1.ContactComs_ComDetails as Email,
				cc2.ContactComs_ComDetails as Phone,
				cc3.ContactComs_ComDetails as Fax,
				c.Contact_ContactType as ContactTypeCode,
				'' as Reference,
				'' as RefHeading,
				c.Contact_Blockbook as Blockbook,
				c.Contact_FieldOfExpertise as Expertise,
				c.Contact_RegionCode as Region,
				'' as SecondaryContactType,
				c.Contact_Corporate as Corporate
				FROM dbo.Contact c WITH (NOLOCK)
				left join dbo.ContactComs cc1  WITH (NOLOCK)
				on cc1.ContactComs_ContactID = c.Contact_ContactID
				and cc1.ContactComs_ComType = 'PriEma'
				and cc1.ContactComs_InActive = 0
				left join dbo.ContactComs cc2 WITH (NOLOCK)
				on cc2.ContactComs_ContactID = c.Contact_ContactID
				and cc2.ContactComs_ComType = 'PriTel'
				and cc2.ContactComs_InActive = 0
				left join dbo.ContactComs cc3 WITH (NOLOCK)
				on cc3.ContactComs_ContactID = c.Contact_ContactID
				and cc3.ContactComs_ComType = 'PriFax'
				and cc3.ContactComs_InActive = 0	
				where c.Contact_ContactID = @ContactID
		END		
		
		SELECT * FROM @results
		
	END TRY
	
	BEGIN CATCH
		SELECT ERROR_MESSAGE() + ' SP: ' + OBJECT_NAME(@@PROCID)
	END CATCH

