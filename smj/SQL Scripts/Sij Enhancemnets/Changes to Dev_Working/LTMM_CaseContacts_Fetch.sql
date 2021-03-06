


ALTER PROC [dbo].[LTMM_CaseContacts_Fetch]
(
	@CaseID					int = 0,
	@SEARCHCaseContactID	int = 0,
	@ContactType			nvarchar(255)  = NULL,
	@ContactType2			nvarchar(255)  = NULL,
	@pNOTContactType		nvarchar(255)  = NULL,
	@pNOTContactType2		nvarchar(255)  = NULL,
	@UserName				nvarchar(255)  = ''			
)
AS
	--Stored Procedure to Either fetch a particular Contact or all Contacts Associated with a Case
	--Author(s) GQL
	--11-08-2009
	
	--Amended: 20-09-2011 by SMJ
	--Include new fields: 
	--	MatterContacts_NINumber
	--	MatterContacts_VehicleReg
	--	MatterContacts_Passenger

	--------------------------------------------------------------------------------------------------------------------
	-- Modified by GV on 29/09/2011
	-- SP extended to return the secondary contact type
	--------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------
	-- Modified by GV on 17/11/2011
	-- SP extended to allow the fetch of two contact types (new para @ContactType2)
	--------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------
	-- Modified by GV on 05/01/2012
	-- SP extended to ignore some contact types
	--------------------------------------------------------------------------------------------------------------------
	
	--------------------------------------------------------------------------------------------------------------------
	-- Modified by CKJ on 12/09/2012
	-- SP tweaked for performance against Aderant tables
	--------------------------------------------------------------------------------------------------------------------

	-- ===============================================================
	-- Author:		SMJ
	-- Version:		2
	-- Modify date: 24-09-2012
	-- Description:	Changed error handling, added WITH (NOLOCK), added schema names
	-- ===============================================================			
	
	DECLARE @MattConID int
	DECLARE @ClientConID int
	DECLARE @SQL nVARCHAR(MAX)
	
	
	DECLARE @Client_Uno int = 0
	DECLARE @Name_Uno int = 0
	DECLARE @Address_Uno int = 0
	DECLARE @Client_Name nvarchar(255)
	
	BEGIN TRY
		DECLARE @CC_CONTACTS TABLE
		(
			ContactID [int] NOT NULL,
			RoleCode nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Title nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Forename nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Surname nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Corporate nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			CompanyName nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Position nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			GENDerCode nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			DOB SMALLDATETIME NULL,
			FullName nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			FullName_Role nvarchar(512) COLLATE DATABASE_DEFAULT NULL,
			Blockbook nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			FieldOfExpertise nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			RegionCode nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			AddressType nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Address1 nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Address2 nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Address3 nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Address4 nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Town nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			County nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Postcode nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			Country nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			DXNumber nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			DXExchange nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			AddressOrder int NULL,
			IsPrimary BIT NULL,
			Reference nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			CaseContactsID INT NULL,
			[Source] nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			PrimaryEmail nvarchar(MAX) COLLATE DATABASE_DEFAULT NULL,
			PrimaryTelephone nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			PrimaryFax nvarchar(256) COLLATE DATABASE_DEFAULT NULL,
			ContactRoleDesc nvarchar(MAX) COLLATE DATABASE_DEFAULT NULL,
			ContactRefHeading nvarchar(MAX) COLLATE DATABASE_DEFAULT NULL,
			DOD SMALLDATETIME NULL,
			NINumber NVARCHAR(255)NULL,
			VehicleReg NVARCHAR(255) NULL,
			Passenger BIT NULL,
			SecondaryContactType nvarchar(250)
		)	
		
		--IF both a Case ID and a Case Contact ID have been passed through (even if its a negative contact ID to clear the grid)
		IF (@CaseID > 0 and @SEARCHCaseContactID <> 0)
		BEGIN
			
			DECLARE @ContactID int
			IF (@SEARCHCaseContactID < 0)  
			BEGIN
				SET @ContactID = -1
				SET @MattConID = - 1 
				SET @ClientConID = - 1
			END
			ELSE
			BEGIN
				SET @ContactID = (SELECT CaseContacts_ContactID FROM dbo.CaseContacts WITH (NOLOCK)  WHERE CaseContacts_CaseContactsID = @SEARCHCaseContactID and CaseContacts_Inactive = 0)
				SET @MattConID = (SELECT CaseContacts_MatterContactID FROM dbo.CaseContacts WITH (NOLOCK)  WHERE CaseContacts_CaseContactsID = @SEARCHCaseContactID and CaseContacts_Inactive = 0)
				SET @ClientConID = (SELECT CaseContacts_ClientID FROM dbo.CaseContacts WITH (NOLOCK)  WHERE CaseContacts_CaseContactsID = @SEARCHCaseContactID and CaseContacts_Inactive = 0)			
			END			
					
			--IF the contact that has been selected resides in the Contact Table
			IF (ISNULL(@ContactID,0) <> 0)
			BEGIN
				--Return the selected contact details from the Contact Table
				INSERT INTO @CC_CONTACTS (ContactID, 
					RoleCode, 
					Title, 
					Forename, 
					Surname, 
					Corporate, 
					CompanyName, 
					Position, 
					GENDerCode,
					DOB, 
					FullName, 
					Blockbook, 
					FieldOfExpertise, 
					RegionCode,
					DXExchange, 
					AddressOrder, 
					IsPrimary, 
					Reference, 
					CaseContactsID,
					[Source],
					ContactRefHeading,
					DOD,
					NINumber,
					VehicleReg,
					Passenger,
					SecondaryContactType)
				SELECT 
						c.Contact_ContactID		AS ContactID,
						CASE WHEN (ISNULL(c.[Contact_ContactType],'')) = ''
							THEN m.CaseContacts_RoleCode
							ELSE c.Contact_ContactType
						END AS RoleCode,
						c.[Contact_Title]		AS Title,
						c.[Contact_Forename]	AS Forename,
						c.[Contact_Surname]		AS Surname,
						c.[Contact_Corporate]	AS Corporate,
						c.[Contact_CompanyName] AS CompanyName,
						c.[Contact_Position]	AS Position,
						c.[Contact_GENDerCode]	AS GENDerCode,
						c.[Contact_DOB]			AS DOB,						
						CASE WHEN (ISNULL(c.[Contact_CompanyName], '') = '') OR (c.[Contact_CompanyName] = 'n/a')
							THEN c.[Contact_Title] + ' ' + c.[Contact_Forename] + ' ' + c.[Contact_Surname]
							ELSE c.[Contact_CompanyName]
						END AS FullName,
						c.Contact_Blockbook			AS Blockbook,
						c.Contact_FieldOfExpertise	AS FieldOfExpertise,
						c.Contact_RegionCode		AS RegionCode,
						Null AS DXExchange,
						Null as AddressOrder,
						0 AS IsPrimary,
						m.CaseContacts_Reference	AS Reference,
						m.CaseContacts_CaseContactsID AS  CaseContactsID,
						'Global Contact' as [Source],
						m.CaseContacts_ContactRefHeading as ContactRefHeading,
						''  as DateOfDeath,
						'' AS NINumber,
						'' AS VehicleReg,
						0 AS Passenger,
						m.SecondaryContactType
				FROM	dbo.CaseContacts m WITH (NOLOCK) 
						INNER JOIN dbo.Contact c WITH (NOLOCK) ON c.Contact_ContactID = m.CaseContacts_ContactID AND c.Contact_Inactive = 0					
				WHERE	m.CaseContacts_CaseID = @CaseID AND c.Contact_ContactID = @ContactID AND (ISNULL(m.CaseContacts_Inactive,0) = 0)
				
				--UPDATE ROLE DESCRIPTION (PREVIOUSLY LEFT OUTER JOIN)
				UPDATE @CC_CONTACTS 
				SET ContactRoleDesc = ISNULL(ctype.[Description],''),FullName_Role = ccC.FullName + ISNULL(' (' + ctype.[Description] + ')','')
				FROM @CC_CONTACTS ccC
				INNER JOIN dbo.CaseContacts cc WITH (NOLOCK) ON ccC.CaseContactsID = cc.CaseContacts_CaseContactsID 
				INNER JOIN dbo.Lookupcode ctype WITH (NOLOCK) on (cc.CaseContacts_RoleCode = ctype.Code) and (ctype.LookupTypeCode = 'Contact')
				
				--update contact address info (previously left outer joins)
				UPDATE @CC_CONTACTS 
				SET AddressType = ad.ContactAddress_AddressType,
					Address1 = ad.ContactAddress_Address1,
					Address2 = ad.ContactAddress_Address2,
					Address3 = ad.ContactAddress_Address3,
					Address4 = ad.ContactAddress_Address4,
					Town = ad.ContactAddress_Town,
					County = ad.ContactAddress_County,
					Postcode = ad.ContactAddress_Postcode,
					Country = ad.ContactAddress_Country,
					DXNumber = ad.ContactAddress_DXNumber,
					DXExchange = ad.ContactAddress_DXExchange,
					AddressOrder = ad.ContactAddress_AddressOrder
				FROM @CC_CONTACTS cc
				INNER JOIN dbo.Contact c WITH (NOLOCK) ON cc.ContactID = c.Contact_ContactID
				INNER JOIN dbo.ContactAddress ad WITH (NOLOCK)  on c.Contact_ContactID = ad.ContactAddress_ContactID and isnull(ad.ContactAddress_Inactive,0) = 0 
				
				--update contact email info (previously left outer joins)
				UPDATE @CC_CONTACTS 
				SET PrimaryEmail = ema.ContactComs_ComDetails
				FROM @CC_CONTACTS cc
				INNER JOIN dbo.Contact c WITH (NOLOCK) ON cc.ContactID = c.Contact_ContactID
				INNER JOIN dbo.ContactComs ema WITH (NOLOCK) on c.Contact_ContactID = ema.ContactComs_ContactID and isnull(ema.ContactComs_InActive, 0) = 0  and ema.ContactComs_ComType = 'PriEma'
				
				--update contact telephone info (previously left outer joins)
				UPDATE @CC_CONTACTS 
				SET PrimaryTelephone = tel.ContactComs_ComDetails 
				FROM @CC_CONTACTS cc
				INNER JOIN dbo.Contact c WITH (NOLOCK) ON cc.ContactID = c.Contact_ContactID
				INNER JOIN dbo.ContactComs tel WITH (NOLOCK)  on c.Contact_ContactID = tel.ContactComs_ContactID and isnull(tel.ContactComs_InActive, 0) = 0  and tel.ContactComs_ComType = 'PriTel'
				
				--update contact fax info (previously left outer joins)
				UPDATE @CC_CONTACTS
				SET PrimaryFax = fax.ContactComs_ComDetails
				FROM @CC_CONTACTS cc
				INNER JOIN dbo.Contact c WITH (NOLOCK) ON cc.ContactID = c.Contact_ContactID
				INNER JOIN dbo.ContactComs fax WITH (NOLOCK) on c.Contact_ContactID = fax.ContactComs_ContactID and isnull(fax.ContactComs_InActive, 0) = 0  and fax.ContactComs_ComType = 'PriFax'
			END 
			ELSE
			BEGIN
				--IF the contact that has been selected resides in the MatterContact Table
				IF (ISNULL(@MattConID,0) <> 0)
				BEGIN

					--Return the selected contact details from the Contact Table
					INSERT INTO @CC_CONTACTS (ContactID, 
						RoleCode, 
						Title, 
						Forename, 
						Surname, 
						Corporate, 
						CompanyName, 
						Position, 
						GENDerCode,
						DOB, 
						FullName, 
						Blockbook, 
						FieldOfExpertise, 
						RegionCode,
						DXExchange, 
						AddressOrder, 
						IsPrimary, 
						Reference, 
						CaseContactsID,
						[Source],
						ContactRefHeading,
						DOD,
						NINumber,
						VehicleReg,
						Passenger,
						SecondaryContactType)
					SELECT 
							c.MatterContact_MatterContactID	AS ContactID,
							CASE WHEN (ISNULL(c.[MatterContact_ContactType],'')) = ''
								THEN m.CaseContacts_RoleCode
								ELSE c.MatterContact_ContactType
							END AS RoleCode,
							c.[MatterContact_Title]			AS Title,
							c.[MatterContact_Forename]		AS Forename,
							c.[MatterContact_Surname]		AS Surname,
							c.[MatterContact_Corporate]		AS Corporate,
							c.[MatterContact_CompanyName]	AS CompanyName,
							c.[MatterContact_Position]		AS Position,
							c.[MatterContact_GENDerCode]	AS GENDerCode,
							c.[MatterContact_DOB]			AS DOB,
							CASE WHEN (c.[MatterContact_CompanyName] = '')
								THEN c.[MatterContact_Title] + ' ' + c.[MatterContact_Forename] + ' ' + c.[MatterContact_Surname]
								ELSE c.[MatterContact_CompanyName]
							END AS FullName,
							c.MatterContact_Blockbook			AS Blockbook,
							c.MatterContact_FieldOfExpertise	AS FieldOfExpertise,
							c.MatterContact_RegionCode		AS RegionCode,
							Null AS DXExchange,
							Null AS AddressOrder,
							0 AS IsPrimary,
							m.CaseContacts_Reference	AS Reference,
							m.CaseContacts_CaseContactsID AS  CaseContactsID,
							'Matter Contact' as [Source],
							m.CaseContacts_ContactRefHeading as ContactRefHeading,
							c.MatterContact_DateOfDeath  as DateOfDeath,
							c.MatterContacts_NINumber AS NINumber,
							c.MatterContacts_VehicleReg AS VehicleReg,
							c.MatterContacts_Passenger AS Passenger,
							m.SecondaryContactType AS SecondaryContactType
					FROM	dbo.CaseContacts m WITH (NOLOCK) 
							INNER JOIN dbo.MatterContact c WITH (NOLOCK) ON c.MatterContact_MatterContactID = m.CaseContacts_MatterContactID and c.MatterContact_Inactive = 0 
					WHERE	C.MatterContact_MatterContactID = @MattConID and m.CaseContacts_CaseID = @CaseID  AND (ISNULL(m.CaseContacts_Inactive,0) = 0)

					--UPDATE ROLE DESCRIPTION (PREVIOUSLY LEFT OUTER JOIN)
					UPDATE @CC_CONTACTS
					SET ContactRoleDesc = ISNULL(ctype.[Description],''),FullName_Role = ccC.FullName + ISNULL(' (' + ctype.[Description] + ')','')
					FROM @CC_CONTACTS ccC
					INNER JOIN dbo.CaseContacts cc WITH (NOLOCK)   ON ccC.CaseContactsID = cc.CaseContacts_CaseContactsID
					INNER JOIN dbo.Lookupcode ctype WITH (NOLOCK)  on (cc.CaseContacts_RoleCode = ctype.Code) and (ctype.LookupTypeCode = 'EdtCntct')

					--update Matter Contact address info (previously left outer joins)
					UPDATE @CC_CONTACTS 
					SET AddressType = ad.MatterContactAddress_AddressType,
						Address1 = ad.MatterContactAddress_Address1,
						Address2 = ad.MatterContactAddress_Address2,
						Address3 = ad.MatterContactAddress_Address3,
						Address4 = ad.MatterContactAddress_Address4,
						Town = ad.MatterContactAddress_Town,
						County = ad.MatterContactAddress_County,
						Postcode = ad.MatterContactAddress_Postcode,
						Country = ad.MatterContactAddress_Country,
						DXNumber = ad.MatterContactAddress_DXNumber,
						DXExchange = ad.MatterContactAddress_DXExchange,
						AddressOrder = ad.MatterContactAddress_AddressOrder,
						IsPrimary = 1
					FROM @CC_CONTACTS cc
					INNER JOIN dbo.MatterContact m WITH (NOLOCK) ON cc.ContactID = m.MatterContact_MatterContactID
					INNER JOIN dbo.MatterContactAddress ad WITH (NOLOCK) on m.MatterContact_MatterContactID = ad.MatterContactAddress_MatterContactID and isnull(ad.MatterContactAddress_Inactive, 0) = 0 AND ISNULL(MatterContactAddress_IsPrimary,0) = 1 
					
					--update contact email info (previously left outer joins)
					UPDATE @CC_CONTACTS 
					SET PrimaryEmail = ema.MatterContactComs_ComDetails
					FROM @CC_CONTACTS cc
					INNER JOIN dbo.MatterContact m WITH (NOLOCK) ON cc.ContactID = m.MatterContact_MatterContactID
					INNER JOIN dbo.MatterContactComs ema WITH (NOLOCK) ON m.MatterContact_MatterContactID = ema.MatterContactComs_MatterContactID and isnull(ema.MatterContactComs_InActive, 0) = 0  and ema.MatterContactComs_ComType = 'PriEma'
					
					--update contact telephone info (previously left outer joins)
					UPDATE @CC_CONTACTS 
					SET PrimaryTelephone = tel.MatterContactComs_ComDetails 
					FROM @CC_CONTACTS cc
					INNER JOIN dbo.MatterContact m WITH (NOLOCK) ON cc.ContactID = m.MatterContact_MatterContactID
					INNER JOIN dbo.MatterContactComs tel WITH (NOLOCK) on m.MatterContact_MatterContactID = tel.MatterContactComs_MatterContactID and isnull(tel.MatterContactComs_InActive, 0) = 0  and tel.MatterContactComs_ComType = 'PriTel'
					
					--update contact fax info (previously left outer joins)
					UPDATE @CC_CONTACTS
					SET PrimaryFax = fax.MatterContactComs_ComDetails
					FROM @CC_CONTACTS cc
					INNER JOIN dbo.MatterContact m WITH (NOLOCK) ON cc.ContactID = m.MatterContact_MatterContactID
					INNER JOIN dbo.MatterContactComs fax WITH (NOLOCK) on m.MatterContact_MatterContactID = fax.MatterContactComs_MatterContactID and isnull(fax.MatterContactComs_InActive, 0) = 0  and fax.MatterContactComs_ComType = 'PriFax'
					
				END
				ELSE
				BEGIN
					--IF the contact that has been selected resides in the Client Table
					IF (ISNULL(@ClientConID ,0) <> 0)
					BEGIN	
						--Return the selected contact details from the Contact Table
						INSERT INTO @CC_CONTACTS (ContactID, 
							RoleCode, 
							Title, 
							Forename, 
							Surname, 
							Corporate, 
							CompanyName, 
							Position, 
							GENDerCode,
							DOB, 
							FullName, 
							Blockbook, 
							FieldOfExpertise, 
							RegionCode,
							DXExchange, 
							AddressOrder, 
							IsPrimary, 
							Reference, 
							CaseContactsID,
							[Source],
							ContactRefHeading,
							DOD,
							NINumber,
							VehicleReg,
							Passenger,
							SecondaryContactType)
						SELECT 
								c.CLIENT_UNO					AS ContactID,
								'Client'						AS RoleCode,
								'n/a'							AS Title,
								'n/a'							AS Forename,
								'n/a'							AS Surname,
								'Y'								AS Corporate,
								c.CLIENT_NAME 					AS CompanyName,
								'n/a'							AS Position,
								'n/a'							AS GENDerCode,
								Null							AS DOB,
								c.CLIENT_NAME 					AS FullName,
								'n/a'							AS Blockbook,
								'n/a'							AS FieldOfExpertise,
								Null							AS RegionCode,
								'n/a'							AS DXExchange,
								0								AS AddressOrder,
								0								AS IsPrimary,
								m.CaseContacts_Reference		AS Reference,
								m.CaseContacts_CaseContactsID	AS  CaseContactsID,
								'Client'						AS [Source],
								m.CaseContacts_ContactRefHeading as ContactRefHeading,
								''								 as DateOfDeath,
								''								AS NINumber,
								''								AS VehicleReg,
								0								AS Passenger,
								m.SecondaryContactType			AS SecondaryContactType
						FROM	dbo.CaseContacts m WITH (NOLOCK)
								INNER JOIN dbo.HBM_Client c WITH (NOLOCK) ON c.CLIENT_UNO = m.CaseContacts_ClientID
						WHERE	m.CaseContacts_ClientID = @ClientConID and m.CaseContacts_CaseID = @CaseID AND (ISNULL(m.CaseContacts_Inactive,0) = 0)
						
						--UPDATE ROLE DESCRIPTION (PREVIOUSLY LEFT OUTER JOIN)
						UPDATE @CC_CONTACTS
						SET ContactRoleDesc = ISNULL(ctype.[Description],''),FullName_Role = ccC.FullName + ISNULL(' (' + ctype.[Description] + ')','')
						FROM @CC_CONTACTS ccC
						INNER JOIN dbo.CaseContacts cc WITH (NOLOCK) ON ccC.CaseContactsID = cc.CaseContacts_CaseContactsID 
						INNER JOIN dbo.Lookupcode ctype WITH (NOLOCK) on (cc.CaseContacts_RoleCode = ctype.Code) and (ctype.LookupTypeCode = 'AllContact')
						
						--update client contact info (previously left outer joins)
						UPDATE @CC_CONTACTS 
						SET RegionCode = ad.REGION_CODE,
							AddressType = ad.ADDR_TYPE_CODE,
							Address1 = ad.ADDRESS1,
							Address2 = ad.ADDRESS2,
							Address3 = ad.ADDRESS3,
							Address4 = ad.ADDRESS4,
							Town = ad.CITY,
							County = ad.STATE_CODE,
							Postcode = ad.POST_CODE,
							Country = ad.COUNTRY_CODE,
							DXNumber = ad.MODEM_NUMBER,
							PrimaryEmail = CONVERT(VARCHAR(MAX),ad._EMAIL_ADDRESS),
							PrimaryTelephone = ad.PHONE_NUMBER,
							PrimaryFax = ad.FAX_NUMBER				
						FROM @CC_CONTACTS cc
						INNER JOIN dbo.HBM_CLIENT cl WITH (NOLOCK) ON cc.ContactID = cl.CLIENT_UNO 
						INNER JOIN dbo.HBM_ADDRESS ad WITH (NOLOCK) ON cl.NAME_UNO = ad.NAME_UNO
						
					END
				END
			END	
		END	
		ELSE
		--IF only a Case ID has been passed through
			IF (@CaseID > 0)
			BEGIN
			
					--- Get the Aderant Unos. --Added by CKJ
					SELECT @Client_Uno = CaseContacts_ClientID
					FROM dbo.CaseContacts WITH (NOLOCK) 
					WHERE (CaseContacts_CaseID = @CaseID) AND (CaseContacts_Inactive=0)

					SELECT @Name_Uno = cl.NAME_UNO, @Client_Name = cl.CLIENT_NAME, @Address_Uno=cl.ADDRESS_UNO
					FROM dbo.HBM_CLIENT cl WITH (NOLOCK)
					WHERE (cl.CLIENT_UNO = @Client_Uno)
			
			
			
				--Return all contact details for the Matter with the CASE ID provide from both the Contact and MatterContact Tables
				INSERT INTO @CC_CONTACTS (ContactID, 
					RoleCode, 
					Title, 
					Forename, 
					Surname, 
					Corporate, 
					CompanyName, 
					Position, 
					GENDerCode,
					DOB, 
					FullName, 
					Blockbook, 
					FieldOfExpertise, 
					RegionCode,
					DXExchange, 
					AddressOrder, 
					IsPrimary, 
					Reference, 
					CaseContactsID,
					[Source],
					ContactRefHeading,
					DOD,
					NINumber,
					VehicleReg,
					Passenger,
					SecondaryContactType)
				SELECT   
						@Client_Uno						AS ContactID,
						'Client'						AS RoleCode,
						'n/a'							AS Title,
						'n/a'							AS Forename,
						'n/a'							AS Surname,
						'Y'								AS Corporate,
						@Client_Name 					AS CompanyName,
						'n/a'							AS Position,
						'n/a'							AS GENDerCode,
						Null							AS DOB,
						@Client_Name 					AS FullName,
						'n/a'							AS Blockbook,
						'n/a'							AS FieldOfExpertise,
						Null							AS RegionCode,
						'n/a'							AS DXExchange,
						0								AS AddressOrder,
						0								AS IsPrimary,
						m.CaseContacts_Reference		AS Reference,
						m.CaseContacts_CaseContactsID	AS  CaseContactsID,
						'Client'						AS [Source],
						m.CaseContacts_ContactRefHeading as ContactRefHeading,
						''								 as DateOfDeath,
						''								AS NINumber,
						''								AS VehicleReg,
						0								AS Passenger,
						m.SecondaryContactType			AS SecondaryContactType
				FROM	dbo.CaseContacts m WITH (NOLOCK) 
				WHERE	m.CaseContacts_CaseID = @CaseID AND (ISNULL(m.CaseContacts_Inactive,0) = 0) AND (m.CaseContacts_RoleCode = 'Client')
				UNION
				SELECT	c.Contact_ContactID		AS ContactID,
						CASE WHEN (ISNULL(c.[Contact_ContactType],'')) = ''
							THEN m.CaseContacts_RoleCode
							ELSE c.Contact_ContactType
						END AS RoleCode,
						c.[Contact_Title]		AS Title,
						c.[Contact_Forename]	AS Forename,
						c.[Contact_Surname]		AS Surname,
						c.[Contact_Corporate]	AS Corporate,
						c.[Contact_CompanyName] AS CompanyName,
						c.[Contact_Position]	AS Position,
						c.[Contact_GENDerCode]	AS GENDerCode,
						c.[Contact_DOB]			AS DOB,						
						CASE WHEN (ISNULL(c.[Contact_CompanyName], '') = '') OR (c.[Contact_CompanyName] = 'n/a')
							THEN c.[Contact_Title] + ' ' + c.[Contact_Forename] + ' ' + c.[Contact_Surname]
							ELSE c.[Contact_CompanyName]
						END AS FullName,
						c.Contact_Blockbook			AS Blockbook,
						c.Contact_FieldOfExpertise	AS FieldOfExpertise,
						c.Contact_RegionCode		AS RegionCode,
						Null AS DXExchange,
						Null as AddressOrder,
						0 AS IsPrimary,
						m.CaseContacts_Reference	AS Reference,
						m.CaseContacts_CaseContactsID AS  CaseContactsID,
						'Global Contact' as [Source],
						m.CaseContacts_ContactRefHeading as ContactRefHeading,
						'' as DateOfDeath,
						'' AS NINumber,
						'' AS VehicleReg,
						0 AS Passenger,
						m.SecondaryContactType AS SecondaryContactType
					FROM	dbo.CaseContacts m WITH (NOLOCK)
						INNER JOIN dbo.Contact c WITH (NOLOCK) ON c.Contact_ContactID = m.CaseContacts_ContactID AND c.Contact_Inactive = 0
					WHERE	m.CaseContacts_CaseID = @CaseID AND ((ISNULL(m.CaseContacts_Inactive,0) = 0))
				UNION
				SELECT	 
						c.MatterContact_MatterContactID	AS ContactID,
						CASE WHEN (ISNULL(c.[MatterContact_ContactType],'')) = ''
							THEN m.CaseContacts_RoleCode
							ELSE c.MatterContact_ContactType
						END AS RoleCode,
						c.[MatterContact_Title]			AS Title,
						c.[MatterContact_Forename]		AS Forename,
						c.[MatterContact_Surname]		AS Surname,
						c.[MatterContact_Corporate]		AS Corporate,
						c.[MatterContact_CompanyName]	AS CompanyName,
						c.[MatterContact_Position]		AS Position,
						c.[MatterContact_GENDerCode]	AS GENDerCode,
						c.[MatterContact_DOB]			AS DOB,
						CASE WHEN (c.[MatterContact_CompanyName] = '')
							THEN c.[MatterContact_Title] + ' ' + c.[MatterContact_Forename] + ' ' + c.[MatterContact_Surname]
							ELSE c.[MatterContact_CompanyName]
						END AS FullName,
						c.MatterContact_Blockbook			AS Blockbook,
						c.MatterContact_FieldOfExpertise	AS FieldOfExpertise,
						c.MatterContact_RegionCode		AS RegionCode,
						Null AS DXExchange,
						Null AS AddressOrder,
						0 AS IsPrimary,
						m.CaseContacts_Reference	AS Reference,
						m.CaseContacts_CaseContactsID AS  CaseContactsID,
						'Matter Contact' as [Source],
						m.CaseContacts_ContactRefHeading as ContactRefHeading,
						c.MatterContact_DateOfDeath  as DateOfDeath,
						c.MatterContacts_NINumber AS NINumber,
						c.MatterContacts_VehicleReg AS VehicleReg,
						c.MatterContacts_Passenger AS Passenger,
						m.SecondaryContactType AS SecondaryContactType
					FROM dbo.CaseContacts m WITH (NOLOCK)
						INNER JOIN dbo.MatterContact c WITH (NOLOCK) ON c.MatterContact_MatterContactID = m.CaseContacts_MatterContactID and c.MatterContact_Inactive = 0					
				WHERE	(m.CaseContacts_CaseID = @CaseID)	AND (ISNULL(m.CaseContacts_Inactive, 0) = 0)
							
				--UPDATE ROLE DESCRIPTION (PREVIOUSLY LEFT OUTER JOIN)
				UPDATE @CC_CONTACTS 
				SET ContactRoleDesc = ISNULL(ctype.[Description],''),FullName_Role = ccC.FullName + ISNULL(' (' + ctype.[Description] + ')','')
				FROM @CC_CONTACTS ccC
				INNER JOIN dbo.CaseContacts cc WITH (NOLOCK) ON ccC.CaseContactsID = cc.CaseContacts_CaseContactsID 
				INNER JOIN dbo.Lookupcode ctype WITH (NOLOCK)  on (cc.CaseContacts_RoleCode = ctype.Code) and (ctype.LookupTypeCode = 'Contact')
				WHERE ccC.[Source] = 'Global Contact'
				
				UPDATE @CC_CONTACTS 
				SET ContactRoleDesc = ISNULL(ctype.[Description],''),FullName_Role = ccC.FullName + ISNULL(' (' + ctype.[Description] + ')','')
				FROM @CC_CONTACTS ccC
				INNER JOIN dbo.CaseContacts cc WITH (NOLOCK) ON ccC.CaseContactsID = cc.CaseContacts_CaseContactsID 
				INNER JOIN dbo.Lookupcode ctype WITH (NOLOCK)  on (cc.CaseContacts_RoleCode = ctype.Code) and (ctype.LookupTypeCode IN ('EdtCntct', 'Contact'))
				WHERE ccC.[Source] = 'Matter Contact'
				
				UPDATE @CC_CONTACTS 
				SET ContactRoleDesc = 'Client'
				WHERE [Source] = 'Client'
						
						
				if (ISNULL(@Address_Uno,0) <> 0)
				
					--update client contact info (previously left outer joins)
					UPDATE @CC_CONTACTS 
					SET RegionCode		= ad.REGION_CODE,
						AddressType		= ad.ADDR_TYPE_CODE,
						Address1		= ad.ADDRESS1,
						Address2		= ad.ADDRESS2,
						Address3		= ad.ADDRESS3,
						Address4		= ad.ADDRESS4,
						Town			= ad.CITY,
						County			= ad.STATE_CODE,
						Postcode		= ad.POST_CODE,
						Country			= ad.COUNTRY_CODE,
						DXNumber		= ad.MODEM_NUMBER,
						PrimaryEmail	= CONVERT(VARCHAR(MAX),ad._EMAIL_ADDRESS),
						PrimaryTelephone = ad.PHONE_NUMBER,
						PrimaryFax		= ad.FAX_NUMBER				
					FROM @CC_CONTACTS cc
					INNER JOIN dbo.HBM_ADDRESS ad WITH (NOLOCK) ON  ( ad.ADDRESS_UNO = @Address_Uno) --AND (cl.NAME_UNO = ad.NAME_UNO) AND
					WHERE cc.[Source] = 'Client'
				
				--update contact address info (previously left outer joins)
				UPDATE @CC_CONTACTS 
				SET AddressType = ad.ContactAddress_AddressType,
					Address1 = ad.ContactAddress_Address1,
					Address2 = ad.ContactAddress_Address2,
					Address3 = ad.ContactAddress_Address3,
					Address4 = ad.ContactAddress_Address4,
					Town = ad.ContactAddress_Town,
					County = ad.ContactAddress_County,
					Postcode = ad.ContactAddress_Postcode,
					Country = ad.ContactAddress_Country,
					DXNumber = ad.ContactAddress_DXNumber,
					DXExchange = ad.ContactAddress_DXExchange,
					AddressOrder = ad.ContactAddress_AddressOrder
				FROM @CC_CONTACTS cc
				INNER JOIN dbo.Contact c WITH (NOLOCK) ON cc.ContactID = c.Contact_ContactID
				INNER JOIN dbo.ContactAddress ad WITH (NOLOCK)  on c.Contact_ContactID = ad.ContactAddress_ContactID and isnull(ad.ContactAddress_Inactive,0) = 0 
				WHERE cc.[Source] = 'Global Contact' 
				
				--update contact email info (previously left outer joins)
				UPDATE @CC_CONTACTS 
				SET PrimaryEmail = ema.ContactComs_ComDetails
				FROM @CC_CONTACTS cc
				INNER JOIN dbo.Contact c WITH (NOLOCK)  ON cc.ContactID = c.Contact_ContactID
				INNER JOIN dbo.ContactComs ema WITH (NOLOCK)  on c.Contact_ContactID = ema.ContactComs_ContactID and isnull(ema.ContactComs_InActive, 0) = 0  and ema.ContactComs_ComType = 'PriEma'
				WHERE cc.[Source] = 'Global Contact' 
				
				--update contact telephone info (previously left outer joins)
				UPDATE @CC_CONTACTS 
				SET PrimaryTelephone = tel.ContactComs_ComDetails 
				FROM @CC_CONTACTS cc
				INNER JOIN dbo.Contact c WITH (NOLOCK) ON cc.ContactID = c.Contact_ContactID
				INNER JOIN dbo.ContactComs tel WITH (NOLOCK)  on c.Contact_ContactID = tel.ContactComs_ContactID and isnull(tel.ContactComs_InActive, 0) = 0  and tel.ContactComs_ComType = 'PriTel'
				WHERE cc.[Source] = 'Global Contact' 
				
				--update contact fax info (previously left outer joins)
				UPDATE @CC_CONTACTS
				SET PrimaryFax = fax.ContactComs_ComDetails
				FROM @CC_CONTACTS cc
				INNER JOIN dbo.Contact c WITH (NOLOCK) ON cc.ContactID = c.Contact_ContactID
				INNER JOIN ContactComs fax on c.Contact_ContactID = fax.ContactComs_ContactID and isnull(fax.ContactComs_InActive, 0) = 0  and fax.ContactComs_ComType = 'PriFax'
				WHERE cc.[Source] = 'Global Contact'
				
				--update Matter Contact address info (previously left outer joins)
				UPDATE @CC_CONTACTS 
				SET AddressType = ad.MatterContactAddress_AddressType,
					Address1 = ad.MatterContactAddress_Address1,
					Address2 = ad.MatterContactAddress_Address2,
					Address3 = ad.MatterContactAddress_Address3,
					Address4 = ad.MatterContactAddress_Address4,
					Town = ad.MatterContactAddress_Town,
					County = ad.MatterContactAddress_County,
					Postcode = ad.MatterContactAddress_Postcode,
					Country = ad.MatterContactAddress_Country,
					DXNumber = ad.MatterContactAddress_DXNumber,
					DXExchange = ad.MatterContactAddress_DXExchange,
					AddressOrder = ad.MatterContactAddress_AddressOrder,
					IsPrimary = 1
				FROM @CC_CONTACTS cc
				INNER JOIN dbo.MatterContact m WITH (NOLOCK) ON cc.ContactID = m.MatterContact_MatterContactID
				INNER JOIN dbo.MatterContactAddress ad WITH (NOLOCK) on m.MatterContact_MatterContactID = ad.MatterContactAddress_MatterContactID and isnull(ad.MatterContactAddress_Inactive, 0) = 0 AND ISNULL(MatterContactAddress_IsPrimary,0) = 1 
				WHERE cc.[Source] = 'Matter Contact' 
				
				--update contact email info (previously left outer joins)
				UPDATE @CC_CONTACTS 
				SET PrimaryEmail = ema.MatterContactComs_ComDetails
				FROM @CC_CONTACTS cc
				INNER JOIN dbo.MatterContact m WITH (NOLOCK) ON cc.ContactID = m.MatterContact_MatterContactID
				INNER JOIN dbo.MatterContactComs ema WITH (NOLOCK) on m.MatterContact_MatterContactID = ema.MatterContactComs_MatterContactID and isnull(ema.MatterContactComs_InActive, 0) = 0  and ema.MatterContactComs_ComType = 'PriEma'
				WHERE cc.[Source] = 'Matter Contact' 
				
				--update contact telephone info (previously left outer joins)
				UPDATE @CC_CONTACTS 
				SET PrimaryTelephone = tel.MatterContactComs_ComDetails 
				FROM @CC_CONTACTS cc
				INNER JOIN dbo.MatterContact m WITH (NOLOCK) ON cc.ContactID = m.MatterContact_MatterContactID
				INNER JOIN dbo.MatterContactComs tel WITH (NOLOCK) on m.MatterContact_MatterContactID = tel.MatterContactComs_MatterContactID and isnull(tel.MatterContactComs_InActive, 0) = 0  and tel.MatterContactComs_ComType = 'PriTel'
				WHERE cc.[Source] = 'Matter Contact' 
				
				--update contact fax info (previously left outer joins)
				UPDATE @CC_CONTACTS
				SET PrimaryFax = fax.MatterContactComs_ComDetails
				FROM @CC_CONTACTS cc
				INNER JOIN dbo.MatterContact m WITH (NOLOCK) ON cc.ContactID = m.MatterContact_MatterContactID
				INNER JOIN dbo.MatterContactComs fax WITH (NOLOCK) on m.MatterContact_MatterContactID = fax.MatterContactComs_MatterContactID and isnull(fax.MatterContactComs_InActive, 0) = 0  and fax.MatterContactComs_ComType = 'PriFax'
				WHERE cc.[Source] = 'Matter Contact'
				
			END
						
			UPDATE @CC_CONTACTS 
			SET FullName_Role = ccC.FullName
			FROM @CC_CONTACTS ccC
			WHERE FullName_Role IS NULL
		
			SELECT *
			FROM @CC_CONTACTS
			WHERE ((ISNULL(@ContactType, '') = '' OR RoleCode = ISNULL(@ContactType, '') )
					OR RoleCode = ISNULL(@ContactType2, '' ))
			AND (ISNULL(@pNOTContactType, '') = '' OR RoleCode <> ISNULL(@pNOTContactType, '') )
			AND (ISNULL(@pNOTContactType2, '') = '' OR RoleCode <> ISNULL(@pNOTContactType2, '') )
			
	END TRY
	
	BEGIN CATCH		
		SELECT ERROR_MESSAGE() + ' SP: ' + OBJECT_NAME (@@PROCID)
	END CATCH





