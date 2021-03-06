

ALTER PROCEDURE [dbo].[LTMM_CaseBanner_Fetch]
(
	@CaseID			int = 0,
	@UserName		nvarchar(255)  = ''
)
AS
		
	-- ==========================================================================================
	-- Author:		GQL
	-- Create date: 10-08-2009
	-- Amend date: 17-03-2011
	-- Description:	Stored Procedure to returns the Case Banner data used by the case console when passed a valid ID for a Case
	-- GQL Amended to remove left outer joins
	-- ==========================================================================================
	
	-- ==========================================================================================
	-- Author:	   SMJ
	-- Amend date: 29-11-2011
	-- Description:	Added check for Healthcare
	-- ==========================================================================================
				
				
	--CREATE TEMPORY TABLE TO HOLD RESULT SET 
	DECLARE @INSTDATE AS SMALLDATETIME
	--DECLARE @CaseBannerDetails TABLE
	--(
		DECLARE @Case_CaseID [int] 
		DECLARE @Case_ClientUno [int] 
		DECLARE @Case_MatterUno [int] 
		DECLARE @AppInstanceValue nvarchar(50) 
		DECLARE @Case_MatterDescription nvarchar(256)  
		DECLARE @Case_WorkValue nvarchar(256)  
		DECLARE @Client_Name nvarchar(256)  
		DECLARE @FECode nvarchar(256)   
		DECLARE @TLCode nvarchar(256)  
		DECLARE @CFECode nvarchar(256)  
		DECLARE @Keydates_AccidentDate smalldatetime
		DECLARE @Keydates_LimitationDate smalldatetime
		DECLARE @LinkedCases nvarchar(256)  
		DECLARE @CaseStatus nvarchar(256)  
		DECLARE @ClientCode nvarchar(256)  
		DECLARE @Contact_Ref nvarchar(256)  
		DECLARE @TACode nvarchar(256)  
		DECLARE @FixedFee nvarchar(256)  
		DECLARE @Delegated_Athority nvarchar(256)  
		DECLARE @Time_WIP_Amount money 
		DECLARE @Time_WIP_Hours decimal(18,2) 
		DECLARE @Cycle_Time int 
		DECLARE @CostsEstimate money 
		DECLARE @SettlementDate smalldatetime
		DECLARE @HealthCare BIT 
		DECLARE @ClientRuleCode nvarchar(256)  
		DECLARE @ClientGroupName nvarchar(256)  
		DECLARE @SecCaseTypeInj nvarchar(10)  
		DECLARE @SecCaseTypeNInj nvarchar(10)  
		DECLARE @Case_WorkType nvarchar(256) 
		DECLARE @Case_CostsAssgn bit 
	--)
	/*
	--GET A DATE OF RECIPT OF INSRUCTIONS FROM EXPERT IF ONE DOESNT EXIST IN FLOCASE
	IF NOT EXISTS (SELECT K.CaseKeyDates_Date FROM CaseKeyDates k WHERE k.CaseKeyDates_CaseID = @CaseID and k.CaseKeyDates_Inactive = 0 and k.CaseKeyDates_KeyDatesCode = 'Receipt')
	BEGIN
		SELECT @INSTDATE = CAST(Date_Instructed AS smalldatetime)
		FROM _HBM_Matter_Usr_Data m INNER JOIN
		ApplicationInstance a ON m.MATTER_UNO = a.AExpert_MatterUno 
		WHERE a.CaseID =@CaseID
		
		IF ISNULL(@INSTDATE, '') <> '' OR ISNULL(@INSTDATE, '') <> '01/01/1900'
		BEGIN		
			EXECUTE [dbo].[LTMM_CaseKeyDates_Save] 
			   0
			  ,@CaseID 
			  ,'Receipt'
			  ,@INSTDATE
			  ,0
			  ,0
			  ,0
			  ,'ADMIN'
			  ,0
		END
		
	END*/
	
	/*INSERT INTO @CaseBannerDetails(Case_CaseID, Case_ClientUno, Case_MatterUno, Case_MatterDescription, 
	Client_Name, FECode, TLCode, CFECode, ClientCode,AppInstanceValue,Contact_Ref, Time_WIP_Amount, Time_WIP_Hours, ClientRuleCode, ClientGroupName,
	SecCaseTypeInj, SecCaseTypeNInj, Case_WorkType )*/
	SELECT 
		@Case_CaseID = c.Case_CaseID, 
		@Case_ClientUno = c.Case_ClientUno, 
		@Case_MatterUno = c.Case_MatterUno, 
		@Case_MatterDescription = c.Case_MatterDescription,	
		@Client_Name = CASE WHEN (ISNULL(cc.CaseContacts_Reference,'') <> '')
			THEN cc.CaseContacts_SearchName + ' - ' + cc.CaseContacts_Reference
			ELSE cc.CaseContacts_SearchName
		END,
		@FECode = fes.UserName, 
		@TLCode = tl.UserName,
		@CFECode = cfe.UserName,
		@ClientCode = c.Case_ClientCode,
		@AppInstanceValue = ai.IdentifierValue,
		@Contact_Ref = cc.CaseContacts_Reference,
		@Time_WIP_Amount = c.CASE_Time_WIP_Amount,
		@Time_WIP_Hours = c.CASE_Time_WIP_Hours,
		@ClientRuleCode = c.Case_ClientRuleCode,
		@ClientGroupName = cg.ClientGroupName,
		@SecCaseTypeInj = c.Case_SecCaseTypeInj, 
		@SecCaseTypeNInj = c.Case_SecCaseTypeNInj,
		@Case_WorkType = c.Case_WorkTypeCode,
		@Case_CostsAssgn = c.Case_CostsAssgn

	FROM dbo.ClientRule AS cr INNER JOIN
	  dbo.ClientGroup AS cg ON cr.ClientRule_ClientGroupID = cg.ClientGroupID AND cr.ClientRule_InActive = 0 RIGHT OUTER JOIN
	  
	  dbo.[Case] AS c ON cr.ClientRule_Code = c.Case_ClientRuleCode INNER JOIN
	  dbo.ApplicationInstance AS ai ON ai.CaseID = c.Case_CaseID INNER JOIN
	  dbo.AppUser AS fes ON fes.AppInstanceValue = ai.IdentifierValue AND fes.AppUserRoleCode = 'FES' AND fes.InActive = 0 INNER JOIN
	  dbo.AppUser AS tl ON tl.AppInstanceValue = ai.IdentifierValue AND tl.AppUserRoleCode = 'TL' AND tl.InActive = 0 LEFT OUTER JOIN
	  dbo.AppUser AS cfe ON cfe.AppInstanceValue = ai.IdentifierValue AND cfe.AppUserRoleCode = 'CFE' AND cfe.InActive = 0 INNER JOIN
	  dbo.CaseContacts AS cc ON cc.CaseContacts_CaseID = c.Case_CaseID AND ISNULL(cc.CaseContacts_ClientID, 0) > 0 AND cc.CaseContacts_Inactive = 0 
--	  INNER JOIN
--	  dbo.HBM_CLIENT AS clt ON cc.CaseContacts_ClientID = clt.CLIENT_UNO ON cr.ClientRule_Code = c.Case_ClientRuleCode
	WHERE (Case_CaseID = @CaseID)

	--UPDATE RESULT SET WITH Team Admin INFO (PREVIOUSLY LEFT OUTER JOIN)
	SELECT @TACode = ta.UserName
	FROM [Case] ca
	INNER JOIN AppUser AS ta ON (ta.AppInstanceValue = ca.Case_BLMREF) AND (ta.AppUserRoleCode = 'TA')  AND (ta.InActive=0)
	WHERE ca.Case_CaseID = @Case_CaseID
		
	--UPDATE RESULT SET WITH WORKVALUE INFO (PREVIOUSLY LEFT OUTER JOIN)
	SELECT @Case_WorkValue = workvalue.Description
	FROM [Case] ca
	INNER JOIN LookupCode AS workvalue ON (workvalue.LookupTypeCode = 'WorkValue') AND (workvalue.Code = cA.Case_WorkValueCode)
	WHERE ca.Case_CaseID = @Case_CaseID
	
	--UPDATE RESULT SET WITH ACCIDENT DATE INFO (PREVIOUSLY LEFT OUTER JOIN)	
	SELECT @Keydates_AccidentDate = ckd1.CaseKeyDates_Date
	FROM [Case] c
	INNER JOIN CaseKeyDates AS ckd1 ON (ckd1.CaseKeyDates_CaseID = c.Case_CaseID)
										AND (ckd1.CaseKeyDates_KeyDatesCode = 'Accident')
										AND (ckd1.CaseKeyDates_Inactive = 0)
	WHERE c.Case_CaseID = @Case_CaseID			
		
	--UPDATE RESULT SET WITH LIMITATION DATE INFO (PREVIOUSLY LEFT OUTER JOIN)
	SELECT @Keydates_LimitationDate = ckd1.CaseKeyDates_Date
	FROM [Case] c
	INNER JOIN CaseKeyDates AS ckd1 ON (ckd1.CaseKeyDates_CaseID = c.Case_CaseID)
										AND (ckd1.CaseKeyDates_KeyDatesCode = 'Limit')
										AND (ckd1.CaseKeyDates_Inactive = 0)
	WHERE c.Case_CaseID = @Case_CaseID
		
	--UPDATE RESULT SET WITH CASE STATUS INFO (PREVIOUSLY LEFT OUTER JOIN)
	SELECT @CaseStatus = cs.[Description] 
	FROM [Case] ca  
	INNER JOIN LookupCode AS cs ON (cs.LookupTypeCode = 'CaseStatus') AND (cs.Code = ca.Case_StateCode)
	WHERE ca.Case_CaseID = @Case_CaseID
	
	--UPDATE RESULT SET WITH LINKED MATTERS INFO (PREVIOUSLY LEFT OUTER JOIN)
	/*SET @LinkedCases = 'No'
	
	SELECT @LinkedCases  =	CASE WHEN (ISNULL(crs.CaseRelationship_SourceCaseID,0) <> 0)
							THEN 'Yes'
							ELSE 'No'
						END
	FROM CaseRelationship AS crs 
	WHERE (crs.CaseRelationship_SourceCaseID = @Case_CaseID) AND (crs.CaseRelationship_Inactive = 0)*/
	
	SELECT @LinkedCases =	CASE WHEN (ISNULL(crd.CaseRelationship_DestCaseID,0) <> 0)
							THEN 'Yes'
							ELSE 'No'
						END
	FROM CaseRelationship AS crd 
	WHERE (crd.CaseRelationship_DestCaseID = @Case_CaseID) AND (crd.CaseRelationship_Inactive = 0)
	
	--UPDATE RESULT SET WITH SETTLEMENT DATE
	SELECT @SettlementDate = s.Settlement_SettlementDate 
	FROM Settlement s 
	WHERE s.Settlement_CaseID = @Case_CaseID and s.Settlement_Inactive = 0
	
	DECLARE @date1 datetime
	DECLARE @date2 datetime
	
	SELECT @date1 = k.CaseKeyDates_Date
	from CaseKeyDates k
	WHERE 
	k.CaseKeyDates_CaseID = @Case_CaseID and k.CaseKeyDates_Inactive = 0 and k.CaseKeyDates_KeyDatesCode = 'Receipt'
	
	SELECT @date2 = k.CaseKeyDates_Date
	from CaseKeyDates k
	WHERE 
	k.CaseKeyDates_CaseID = @Case_CaseID and k.CaseKeyDates_Inactive = 0 and k.CaseKeyDates_KeyDatesCode = 'DamSet'
	
	--CALCULATE THE CYCLE TIME ON THE MATTER
	SELECT @Cycle_Time = --DATEDIFF(DAY,k.CaseKeyDates_Date, GETDATE())
					CASE 
						WHEN ISNULL(@date2, '') <> '' --OR ISNULL(s.CaseKeyDates_Date, '') <> '01/01/1900' 
							THEN DATEDIFF(DAY,@date1, @date2) 
						ELSE 
							DATEDIFF(DAY,@date1, GETDATE())
					END
	
			
	--UPDATE RESULT SET WITH FIXED FEE AND DELEGATED INFORMATION FROM EXPERT
	SELECT @FixedFee = mud.FIXED_FEES,
	@Delegated_Athority = LOWER(mud.DELEGATED_AUTHORITY)
	FROM ApplicationInstance ai
	INNER JOIN _HBM_MATTER_USR_DATA mud ON ai.AExpert_MatterUno = mud.MATTER_UNO 
	WHERE ai.CaseID = @Case_CaseID
	
	--UPDATE RESULT SET CLAIMANTS COSTS ESTIMATE
	SELECT @CostsEstimate = ISNULL(f.Financial_NHSVal, 0) 
						+ ISNULL(f.Financial_CRUValue, 0)
						+ ISNULL(f.Financial_DamagesPaid, 0)
						+ ISNULL(f.Financial_SpecialDamagesPaid, 0)
						+ ISNULL(f.Financial_CSCostsClaimed, 0)
	FROM Financial f
	WHERE f.Financial_CaseID = @Case_CaseID AND f.Financial_InActive = 0

	--UPDATE HEALTHCARE		
	IF EXISTS(SELECT [CASEID]
      ,[CLIENT_NUMBER]
      ,[CLIENT_CODE]
      ,[CLIENT_GROUPCODE]
      ,[WORK_TYPE]
	FROM vew_dmsTemplates_Filter_Operands
	WHERE (WORK_TYPE IN ('Healthcare - Claims', 'Healthcare Non Claims')) AND CASEID = @CaseID)
	BEGIN
		SET @HealthCare = 1
	END
	ELSE
	BEGIN
		SET @HealthCare = 0
	END	
			
	--RETURN RESULT SET
	SELECT @Case_CaseID AS Case_CaseID,
		@Case_CaseID AS CaseID,
		@Case_ClientUno AS Case_ClientUno,
		@Case_MatterUno AS Case_MatterUno,
		@Case_MatterDescription AS Case_MatterDescription,
		@Case_WorkValue AS Case_WorkValue,
		@AppInstanceValue AS AppInstanceValue,
		@Client_Name AS Client_Name,
		@FECode AS FECode, 
		@TLCode AS TLCode,
		@CFECode AS CFECode,
		@Keydates_AccidentDate AS Keydates_AccidentDate,
		@Keydates_LimitationDate AS Keydates_LimitationDate,
		@LinkedCases AS LinkedCases,
		@CaseStatus AS CaseStatus,
		@ClientCode AS ClientCode,
		@Contact_Ref AS Contact_Ref,
		@TACode AS TACode,
		@FixedFee AS FixedFee,
		@Delegated_Athority AS Delegated_Athority,
		@Time_WIP_Amount AS Time_WIP_Amount,
		@Time_WIP_Hours AS Time_WIP_Hours,
		@Cycle_Time AS Cycle_Time,
		@CostsEstimate AS CostsEstimate,
		@SettlementDate AS SettlementDate,
		@HealthCare AS HealthCare,
		@ClientRuleCode AS ClientRuleCode,
		@ClientGroupName AS ClientGroupName,
		@SecCaseTypeInj AS SecCaseTypeInj,
		@SecCaseTypeNInj AS SecCaseTypeNInj,
		@Case_WorkType AS Case_WorkType,
		@Case_CostsAssgn AS Case_CostsAssgn