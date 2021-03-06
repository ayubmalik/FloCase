USE [Flosuite_Data_Dev]
GO
/****** Object:  StoredProcedure [dbo].[LTMM_Client_Fetch]    Script Date: 09/12/2012 14:43:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[LTMM_Client_Fetch]
(
	@CaseID			int = 0,
	@ClientUno		int = 0,
	@ClientNumber	int = 0,
	@ClientName		varchar(40)  = '',
	@Address		varchar(255)  = '',
	@City			varchar(60)  = '',
	@PostCode		varchar(10)  = '',
	@UserName		varchar(255)  = ''			
)
AS
	--Stored Procedure to Either fetch a particular Client or all Clients Associated with a Case or All Clients
	--Author(s) GQL
	--29-07-2009
	
	--AMENDED 06-07-2011 - SMJ
	--CHANGED @ClientNumber to INT FROM NVARCHAR
	--CHANGED OTHER INPUT DATATYPES TO MATCH THOSE FROM HBM_ VIEWS
	--ADDED WITH (NOLOCK)
	--RETURN IF (IF) CONDITION HAS BEEN MET
	
	-- ===============================================================
	-- Author:		SMJ
	-- Version:		2
	-- Modify date: 24-09-2012
	-- Description:	Changed error handling, added WITH (NOLOCK), added schema names
	-- ===============================================================		
	 
	SET DATEFORMAT DMY


	DECLARE @Client_Uno int = 0
	DECLARE @Name_Uno int = 0
	DECLARE @Address_Uno int = 0

	BEGIN TRY
		--IF both a Case ID and a Client Uno have been passed through
		IF (@CaseID > 0 AND @ClientUno > 0)
		BEGIN
				--Fetch the details for the specified Client
				SELECT 
					c.LAST_MODIFIED as ClientModifiedDate,
					c.CLIENT_UNO,
					CASE WHEN (c.[INACTIVE] = 'N')
						THEN 'ACTIVE'
						ELSE 'INACTIVE'
					END AS INACTIVE,
					c.CLIENT_CODE,
					c.CLIENT_NUMBER,
					c.CLIENT_NAME,
					c.RESP_EMPLOYEE_CODE,
					a.LAST_MODIFIED as AddressModifiedDate,
					a.ADDRESS_UNO,
					a.ADDR_TYPE_CODE,
					a.ADDRESS1,
					a.ADDRESS2,
					a.ADDRESS3,
					a.ADDRESS4,
					a.CITY,
					a.STATE_CODE,
					a.COUNTRY_CODE,
					a.POST_CODE,
					a.REGION_CODE,
					a.PHONE_NUMBER,
					a.FAX_NUMBER,
					a._EMAIL_ADDRESS AS MODEM_NUMBER,
					a.PHONE_EXT_NUM,
					a.DIRECT_NUMBER
			FROM
				dbo.CaseContacts x WITH (NOLOCK)
				INNER JOIN dbo.HBM_Client c WITH (NOLOCK) ON (x.CaseContacts_ClientID = c.CLIENT_UNO) AND (c.CLIENT_UNO = @ClientUno)
				LEFT OUTER JOIN dbo.HBM_ADDRESS a WITH (NOLOCK) ON (c.NAME_UNO = a.NAME_UNO) 
			WHERE	x.CaseContacts_CaseID = @CaseID AND c.CLIENT_NUMBER = @ClientUno 
					AND (x.CaseContacts_Inactive = 0)
			RETURN
		END
		
		--IF only a Case ID has been passed through
		IF @CaseID > 0 --and isnull(@ClientUno,0) = 0) --SMJ - ClientUno will never be null as defaults to 0
		BEGIN
			--Fetch Client details for all clients on that matter
			SELECT 
					c.LAST_MODIFIED as ClientModifiedDate,
					c.CLIENT_UNO,
					CASE WHEN (c.[INACTIVE] = 'N')
						THEN 'ACTIVE'
						ELSE 'INACTIVE'
					END AS INACTIVE,
					c.CLIENT_CODE,
					c.CLIENT_NUMBER,
					c.CLIENT_NAME,
					c.RESP_EMPLOYEE_CODE,
					c.ADDRESS_UNO,
					a.LAST_MODIFIED as AddressModifiedDate,
					a.ADDRESS_UNO,
					a.ADDR_TYPE_CODE,
					a.ADDRESS1,
					a.ADDRESS2,
					a.ADDRESS3,
					a.ADDRESS4,
					a.CITY,
					a.STATE_CODE,
					a.COUNTRY_CODE,
					a.POST_CODE,
					a.REGION_CODE,
					a.PHONE_NUMBER,
					a.FAX_NUMBER,
					a._EMAIL_ADDRESS AS MODEM_NUMBER,
					a.PHONE_EXT_NUM,
					a.DIRECT_NUMBER 
			FROM
				dbo.CaseContacts x WITH (NOLOCK)
				INNER JOIN dbo.HBM_Client c WITH (NOLOCK) ON  X.CaseContacts_ClientID = c.CLIENT_UNO
				LEFT OUTER JOIN dbo.HBM_ADDRESS a WITH (NOLOCK) ON c.NAME_UNO = a.NAME_UNO
			WHERE	x.CaseContacts_CaseID = @CaseID AND (x.CaseContacts_Inactive = 0)
			RETURN
		END
		
	 
		--IF neither a Case ID or a Client Uno has been passed through
		--IF (ISNULL(@CaseID,0) = 0 and ISNULL(@ClientUno,0) = 0) 
		IF COALESCE (@Caseid, @ClientUno) = 0 --SMJ - Quicker than 2 ISNULL's	
		BEGIN		
		
			IF (ISNULL(@ClientNumber,0) <> 0)
			BEGIN
					
					--- Get the Aderant Unos. --Added by CKJ
					SELECT @Client_Uno = cl.CLIENT_UNO , @Name_Uno = cl.NAME_UNO, @Address_Uno=cl.ADDRESS_UNO
					FROM dbo.HBM_CLIENT cl WITH (NOLOCK)
					WHERE (cl.CLIENT_NUMBER = @ClientNumber) AND (cl.INACTIVE = 'N')
					
					SELECT 
						c.LAST_MODIFIED as ClientModifiedDate,
						c.CLIENT_UNO,
						CASE WHEN (c.[INACTIVE] = 'N')
							THEN 'ACTIVE'
							ELSE 'INACTIVE'
						END AS INACTIVE,
						c.CLIENT_CODE,
						c.CLIENT_NUMBER,
						c.CLIENT_NAME,
						c.RESP_EMPLOYEE_CODE,
						a.LAST_MODIFIED as AddressModifiedDate,
						a.ADDRESS_UNO,
						a.ADDR_TYPE_CODE,
						a.ADDRESS1,
						a.ADDRESS2,
						a.ADDRESS3,
						a.ADDRESS4,
						a.CITY,
						a.STATE_CODE,
						a.COUNTRY_CODE,
						a.POST_CODE,
						a.REGION_CODE,
						a.PHONE_NUMBER,
						a.FAX_NUMBER,
						a._EMAIL_ADDRESS AS MODEM_NUMBER,
						a.PHONE_EXT_NUM,
						a.DIRECT_NUMBER
				FROM
					dbo.HBM_Client c WITH (NOLOCK)
					LEFT OUTER JOIN dbo.HBM_ADDRESS a WITH (NOLOCK) ON  (a.NAME_UNO = @Name_Uno) ---AND (c.NAME_UNO = a.NAME_UNO)
				WHERE (c.CLIENT_UNO = @Client_Uno)

					
		END
		ELSE
			BEGIN
		
				--Return all active client details
				SELECT 
						c.LAST_MODIFIED as ClientModifiedDate,
						c.CLIENT_UNO,
						CASE WHEN (c.[INACTIVE] = 'N')
							THEN 'ACTIVE'
							ELSE 'INACTIVE'
						END AS INACTIVE,
						c.CLIENT_CODE,
						c.CLIENT_NUMBER,
						c.CLIENT_NAME,
						c.RESP_EMPLOYEE_CODE,
						a.LAST_MODIFIED as AddressModifiedDate,
						a.ADDRESS_UNO,
						a.ADDR_TYPE_CODE,
						a.ADDRESS1,
						a.ADDRESS2,
						a.ADDRESS3,
						a.ADDRESS4,
						a.CITY,
						a.STATE_CODE,
						a.COUNTRY_CODE,
						a.POST_CODE,
						a.REGION_CODE,
						a.PHONE_NUMBER,
						a.FAX_NUMBER,
						a._EMAIL_ADDRESS AS MODEM_NUMBER,
						a.PHONE_EXT_NUM,
						a.DIRECT_NUMBER
				FROM
					dbo.HBM_Client c WITH (NOLOCK)
					LEFT OUTER JOIN dbo.HBM_ADDRESS a WITH (NOLOCK) ON c.NAME_UNO = a.NAME_UNO
				WHERE c.INACTIVE = 'N' AND
				((ISNULL(@ClientNumber,0) = 0 OR c.CLIENT_NUMBER = @ClientNumber)
				AND (ISNULL(@ClientName,'') = '' OR c.CLIENT_NAME = @ClientName)
				AND (ISNULL(@Address,'') = '' OR a.ADDRESS1 + ' ' + a.ADDRESS2 + ' ' + a.ADDRESS3 + ' ' + a.ADDRESS4 LIKE '%' + @Address + '%')
				AND (ISNULL(@City,'') = '' OR a.CITY = @City)
				AND (ISNULL(@PostCode,'') = '' OR a.POST_CODE = @PostCode))
			END
		END
	END TRY
	
	BEGIN CATCH		
		SELECT ERROR_MESSAGE() + ' SP: ' + OBJECT_NAME (@@PROCID)
	END CATCH
	




