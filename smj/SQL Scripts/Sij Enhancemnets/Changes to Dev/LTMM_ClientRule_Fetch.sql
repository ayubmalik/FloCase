USE [Flosuite_Data_Dev]
GO
/****** Object:  StoredProcedure [dbo].[LTMM_ClientRule_Fetch]    Script Date: 09/24/2012 15:29:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[LTMM_ClientRule_Fetch]
(
	@pClientRule_ClientCode					nvarchar(255)   = '',
	@pClientRule_ClientRuleCode				nvarchar(255)   = '',
	@pUserName								nvarchar(255)	= ''	
)
AS

	-- ===============================================================
	-- Author:		SMJ
	-- Version:		2
	-- Modify date: 24-09-2012
	-- Description:	Changed error handling, added WITH (NOLOCK), added schema names
	-- ===============================================================	
	
	--Initialise Error trapping	
	SET NOCOUNT ON
  	DECLARE @errNoUserID VARCHAR(50)
  	  	
  	SET @errNoUserID = 'No @pUserName passed in.'

	BEGIN TRY
		--ERROR TEST FOR USERNAME
		IF (@pUserName = '')
			RAISERROR (@errNoUserID, 16, 1)

		--- CKJ --- Changed this to be optimal when returning client rules for a clientcode.
		if (@pClientRule_ClientCode = '')
		BEGIN

			--*** This seemed overly complicated... replaced with the following ***
			SELECT cc.ClientRule_ID, cc.ClientRule_Code, cc.ClientRule_Name, 
				cc.ClientRule_ClientCode, cc.ClientRule_ClientGroupID, 
				cc.ClientRule_InActive, cc.ClientRule_CreateDate, 
				cc.ClientRule_CreateUser, c.CLIENT_NAME AS ClientRule_CLIENT_NAME, 
				dbo.ClientGroup.ClientGroupName, ClientRule_ResponsiblePartner 
			FROM dbo.ClientRule cc WITH (NOLOCK) INNER JOIN
				dbo.HBM_CLIENT c WITH (NOLOCK) ON cc.ClientRule_ClientCode = c.CLIENT_CODE INNER JOIN
				dbo.ClientGroup WITH (NOLOCK) ON cc.ClientRule_ClientGroupID = dbo.ClientGroup.ClientGroupID
			WHERE ISNULL(cc.ClientRule_InActive,0) = 0 and 
			(((cc.ClientRule_ClientCode = @pClientRule_ClientCode OR @pClientRule_ClientCode = '') 
			and (cc.ClientRule_Code = @pClientRule_ClientRuleCode OR @pClientRule_ClientRuleCode = '' ))
			or (cc.ClientRule_Code = 'CLTRL000000000000000' and @pClientRule_ClientRuleCode = '' ))
			ORDER by cc.ClientRule_ClientCode Desc
		END
		ELSE
		BEGIN
				SELECT cc.ClientRule_ID, cc.ClientRule_Code, cc.ClientRule_Name, 
			cc.ClientRule_ClientCode, cc.ClientRule_ClientGroupID, 
			cc.ClientRule_InActive, cc.ClientRule_CreateDate, 
			cc.ClientRule_CreateUser, c.CLIENT_NAME AS ClientRule_CLIENT_NAME, 
			dbo.ClientGroup.ClientGroupName, ClientRule_ResponsiblePartner 
			FROM dbo.ClientRule cc  WITH (NOLOCK)
			INNER JOIN dbo.HBM_CLIENT c WITH (NOLOCK) ON cc.ClientRule_ClientCode = c.CLIENT_CODE  AND (cc.ClientRule_ClientCode = @pClientRule_ClientCode)
			INNER JOIN dbo.ClientGroup WITH (NOLOCK) ON cc.ClientRule_ClientGroupID = dbo.ClientGroup.ClientGroupID
			WHERE ISNULL(cc.ClientRule_InActive,0) = 0 
				and  (((cc.ClientRule_ClientCode = @pClientRule_ClientCode			 
				 ) 
				and (cc.ClientRule_Code = @pClientRule_ClientRuleCode OR @pClientRule_ClientRuleCode = '' ))
				or (cc.ClientRule_Code = 'CLTRL000000000000000' and @pClientRule_ClientRuleCode = '' ))
			
			-- SSCF: Added as Aviva (44874) was returning nothing breaking update case details
			union
			
				SELECT cc.ClientRule_ID, cc.ClientRule_Code, cc.ClientRule_Name, 
		cc.ClientRule_ClientCode, cc.ClientRule_ClientGroupID, 
		cc.ClientRule_InActive, cc.ClientRule_CreateDate, 
        cc.ClientRule_CreateUser, c.CLIENT_NAME AS ClientRule_CLIENT_NAME, 
        dbo.ClientGroup.ClientGroupName, ClientRule_ResponsiblePartner 
	FROM dbo.ClientRule AS cc INNER JOIN
		dbo.HBM_CLIENT AS c WITH (NOLOCK) ON cc.ClientRule_ClientCode = c.CLIENT_CODE INNER JOIN
		dbo.ClientGroup WITH (NOLOCK) ON cc.ClientRule_ClientGroupID = dbo.ClientGroup.ClientGroupID
	WHERE ISNULL(cc.ClientRule_InActive,0) = 0
	and (cc.ClientRule_Code = 'CLTRL000000000000000' and @pClientRule_ClientRuleCode = '' )
			
			ORDER by cc.ClientRule_ClientCode Desc
			
		END
	END TRY

	BEGIN CATCH		
		SELECT ERROR_MESSAGE() + ' SP: ' + OBJECT_NAME (@@PROCID)
	END CATCH






