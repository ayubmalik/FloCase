USE [Flosuite_Data_Dev]
GO
/****** Object:  StoredProcedure [dbo].[dmsTemplates_Fetch]    Script Date: 09/12/2012 15:19:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[dmsTemplates_Fetch]
(
	@pdmsTemplates_TemplateCode			nvarchar(255) = '',
	@pdmsTemplates_TemplateName			nvarchar(255) = '',
	@pdmsTemplates_TemplateDesc			nvarchar(255) = '',
	@pdmsTemplates_TemplateGroup		nvarchar(255) = '',
	@pCaseid							int = 0,
	@pShowAll							bit = 0,
	@pBlankRow							bit = 0,				--Pass 1 to insert a blank row at the beginning of the table
	@pUserName							nvarchar(255) = '',		-- Manditory. Map System.Username for Current User	
	@pAutoDoc							bit = 0
)
AS
	-- ==========================================================================================
	-- Author:		GQL
	-- Create date: 20-01-2011
	-- This stored proc is used to extract document templates by the dms.
	-- ==========================================================================================
	
	-- ==========================================================================================
	-- Author:		SMJ
	-- Modify date: 21-09-2011
	-- Get new field dmsTemplates_ReqSup
	-- ==========================================================================================
	
	-- ==========================================================================================
	-- Author:		SMJ
	-- Modify date: 21-10-2011
	-- Check dmsTemplates_ReqSup = 0 before deleting a record from temp table
	-- ==========================================================================================
	
	-- ==========================================================================================
	-- Author:		GV
	-- Modify date: 23-11-2011
	-- Removed changes made by SMJ on 21-10-2011 -- see comments
	-- ==========================================================================================
	
	-- ==========================================================================================
	-- Author:		CKJ
	-- Create date: 11-09-2012
	-- The stored proc has been refactored to support caching of the case templates
	-- ==========================================================================================

	-- ===============================================================
	-- Author:		SMJ
	-- Version:		1
	-- Modify date: 21-09-2012
	-- Description:	Changed error handling, added WITH (NOLOCK), added schema names
	-- ===============================================================	
	
	--Initialise Error trapping	
	SET NOCOUNT ON
  	DECLARE @errNoUserID VARCHAR(50)
  	DECLARE @errNoCaseID VARCHAR(50)
  	
  	SET @errNoUserID = 'No @pUserName passed in.'
  	SET @errNoCaseID = 'No @pCaseid supplied passed in.'

	BEGIN TRY
		IF (@pUserName = '')
			RAISERROR (@errNoUserID, 16,1)
		
		IF (@pCaseid = 0)
			RAISERROR (@errNoCaseID, 16,1)						

		IF (NOT EXISTS (SELECT * 
				FROM dbo.dmsCaseTemplates WITH (NOLOCK)
				WHERE CaseID = @pCaseid))
		BEGIN
			
			--Declare a tempory table to hold returned recordset as you cannot order in a unioned select
			CREATE TABLE #dmsTemplates
			(
				dmsTemplates_dmsTemplatesID int,
				dmsTemplates_TemplateCode nvarchar(255),
				dmsTemplates_TemplateName nvarchar(255),
				dmsTemplates_TemplateDesc nvarchar(255),
				dmsTemplates_TemplateGroup nvarchar(255),
				Template_Group nvarchar(255),
				dmsTemplates_TemplatePath nvarchar(255),
				[Documment_Code] nvarchar(255),
				dmsTemplates_AvailAdhoc BIT,
				CaseID int,
				dmsTemplates_Createuser nvarchar(255),
				dmsTemplates_CreateDate smalldatetime,
				dmsTemplates_ReqSup BIT, 
				DMSFILTERSQL nvarchar(max)
			)
			
			INSERT INTO #dmsTemplates(dmsTemplates_dmsTemplatesID, dmsTemplates_TemplateCode, dmsTemplates_TemplateName, 
			dmsTemplates_TemplateDesc, dmsTemplates_TemplateGroup, Template_Group, dmsTemplates_TemplatePath, 
			[Documment_Code], dmsTemplates_AvailAdhoc, dmsTemplates_Createuser, dmsTemplates_CreateDate, dmsTemplates_ReqSup)
			
			SELECT dmsTemplates_dmsTemplatesID,
				dmsTemplates_TemplateCode,
				dmsTemplates_TemplateName,
				dmsTemplates_TemplateDesc,
				dmsTemplates_TemplateGroup,
				l.[Description] as 'Template_Group',
				dmsTemplates_TemplatePath,
				dmsTemplates_FormCode as [Documment_Code],
				dmsTemplates_AvailAdhoc,
				dmsTemplates_Createuser, 
				dmsTemplates_CreateDate,
				dmsTemplates_ReqSup
			FROM dbo.dmsTemplates t WITH (NOLOCK)
			INNER JOIN  LookupCode l WITH (NOLOCK) ON t.dmsTemplates_TemplateGroup  = l.Code
			WHERE (ISNULL(dmsTemplates_InActive, 0) = 0) AND (dmsTemplates_TemplateGroup <> 'TMPG0005')
			
			
			
			--***********START DOCUMENT FILTERING SECTION************
			--REMOVE TEMPLATES THAT ARE MARKED NOT AVAILABLE ADHOC
			DELETE FROM #dmsTemplates WHERE ISNULL(dmsTemplates_AvailAdhoc,0) = 0 and @pAutoDoc = 0
			--AND ISNULL(dmsTemplates_ReqSup,0) = 0 --SMJ --<< removed by GV 23/11/2011 as don't know why this was added
					
			--ADD THE CASEID TO TEMP TABLE FOR FILTERING PURPOSES
			UPDATE #dmsTemplates SET CaseID = @pCaseid 
			
			CREATE TABLE #dmsFilteredTemplate
			(
				ID int identity(1,1),
				derivedsql nvarchar(max),
				tmpltcode  nvarchar(255)
			)
			
			
			--INSERT THOSE DOCUMENTS WITH FILTERS INTO TEMP TABLE FOR PROCESSING
			INSERT #dmsFilteredTemplate(derivedsql, tmpltcode) 
			SELECT N'EXISTS(SELECT ' 
				+ F.dmsTemplateFilters_Operand 
				+ N' FROM vew_dmsTemplates_Filter_Operands WHERE CASEID = ' + CAST(@pCaseid AS NVARCHAR(MAX)) 
				+ N' AND ' + F.dmsTemplateFilters_Operand + N' ' + f.dmsTemplateFilters_Operator  
				+ N' (''' + REPLACE(F.dmsTemplateFilters_Expression, ',', ''',''') 
				+ N'''))', f.dmsTemplateFilters_TemplateCode
			FROM #dmsTemplates t
			INNER JOIN dmsTemplateFilters f ON t.dmsTemplates_TemplateCode = f.dmsTemplateFilters_TemplateCode AND f.dmsTemplateFilters_InActive = 0
			ORDER BY f.dmsTemplateFilters_TemplateCode
					
			--IF THERE ARE FILTERS TO PROCESS		
			IF (SELECT ISNULL(MAX(ID), 0) FROM #dmsFilteredTemplate) > 0
			BEGIN
				--DECLARE VARIABLES FOR SQL STRING RECURSION AND EXECUTION
				DECLARE @MINID INT
				DECLARE @MAXID INT
				DECLARE @FLAG NVARCHAR(1)
				DECLARE @SQLSTRING NVARCHAR(MAX)
				
				--INITILISE VARIABLES BASED ON RESULT SET
				SELECT @MINID = 1, @FLAG = 'N', @MAXID = MAX(ID)
				FROM #dmsFilteredTemplate 
				
				--WHILE THERE ARE RECORDS TO PROCESS
				WHILE @MINID <= @MAXID 
				BEGIN
					--INITIALISE SQL STRING WITH LEADING IF
					SELECT @SQLSTRING = 'IF ', @FLAG = 'N'
					--WHILE THERE MAYBE FURTHER FILTERS ON CURRENT TEMPLATE
					WHILE @FLAG = 'N' 
					BEGIN
						--ADD DERIVED SQL TO SQL STATEMENT
						
						SELECT @SQLSTRING = @SQLSTRING + derivedsql FROM #dmsFilteredTemplate WHERE ID = @MINID
						--IF THE NEXT RECORD IS FOR THE SAME TEMPLATE
						IF (SELECT ISNULL(tmpltcode, '') FROM #dmsFilteredTemplate WHERE ID = @MINID) = (SELECT ISNULL(tmpltcode, '') FROM #dmsFilteredTemplate WHERE ID = @MINID + 1)
						BEGIN
							--SET COUNTER TO NEXT RECORD
							SET @MINID = @MINID + 1
							--ADD AND TO END OF SQL STATEMENT FOR NEXT RECORDS DERIVED SQL
							SELECT @SQLSTRING = @SQLSTRING + ' AND '
						END
						--ELSE THE NEXT RECORD IS FOR THE A DIFFERENT TEMPLATE
						ELSE
						BEGIN
							--MARK FLAG TO MOVE TO NEXT TEMPLATE
							SELECT @FLAG = 'Y', 
							--APPEND END SQL TO PROCESS TEMPLATE FOR POTENTIAL EXCLUSION TO SQL STATEMENT
							@SQLSTRING = @SQLSTRING + ' BEGIN DELETE FROM #dmsTemplates WHERE dmsTemplates_TemplateCode = ''' + tmpltcode + ''' END' 
							FROM #dmsFilteredTemplate WHERE ID = @MINID
							
							--REPLACE OPERATOR PLACE HOLDERS
							SELECT @SQLSTRING = REPLACE(@SQLSTRING, 'chr(60)', '<')
							SELECT @SQLSTRING = REPLACE(@SQLSTRING, 'chr(61)', '=')
							SELECT @SQLSTRING = REPLACE(@SQLSTRING, 'chr(62)', '>')
							SELECT @SQLSTRING = REPLACE(@SQLSTRING, 'chr(33)', '!')
							
							--EXECUTE SQL
							--print @SQLSTRING
							EXEC (@SQLSTRING)
							
							--INITIAL SQL STATEMENT TO BLANK
							SELECT @SQLSTRING = ''
						END
					END	
					--SET COUNTER TO NEXT RECORD
					SET @MINID = @MINID + 1
				END
			END
				
			DROP TABLE #dmsFilteredTemplate
			

			--***********END DOCUMENT FILTERING SECTION************
		

			INSERT INTO dbo.dmsCaseTemplates 
			SELECT dmsTemplates_TemplateCode, dmsTemplates_TemplateName, dmsTemplates_TemplateDesc, dmsTemplates_TemplateGroup, 
				Template_Group, dmsTemplates_TemplatePath, [Documment_Code], dmsTemplates_AvailAdhoc, CaseID, dmsTemplates_Createuser, 
				dmsTemplates_CreateDate, dmsTemplates_ReqSup 
			FROM #dmsTemplates 
			order by dmsTemplates_TemplateGroup, dmsTemplates_TemplateDesc 
			
			DROP TABLE #dmsTemplates
		END
			
		SELECT
			Null AS dmsTemplates_dmsTemplatesID,
			Null AS dmsTemplates_TemplateCode,
			Null AS dmsTemplates_TemplateName,
			Null AS dmsTemplates_TemplateDesc,
			Null AS dmsTemplates_TemplateGroup,
			Null AS 'Template_Group',
			Null AS dmsTemplates_TemplatePath,
			Null AS [Documment_Code],
			Null AS dmsTemplates_AvailAdhoc,
			Null AS dmsTemplates_Createuser, 
			Null AS dmsTemplates_CreateDate,
			NULL AS dmsTemplates_ReqSup 
		WHERE (ISNULL(@pBlankRow,0) = 1)
		UNION			
		SELECT dmsTemplates_dmsTemplatesID, dmsTemplates_TemplateCode, dmsTemplates_TemplateName, 
			dmsTemplates_TemplateDesc, dmsTemplates_TemplateGroup, Template_Group, dmsTemplates_TemplatePath, 
			[Documment_Code], dmsTemplates_AvailAdhoc, dmsTemplates_Createuser, dmsTemplates_CreateDate, dmsTemplates_ReqSup
		FROM dbo.dmsCaseTemplates dt WITH (NOLOCK)
		WHERE   
			(dt.CaseID = @pCaseid)
			AND (((ISNULL(@pdmsTemplates_TemplateCode, '') = '') OR (dmsTemplates_TemplateCode = @pdmsTemplates_TemplateCode))
			AND ((ISNULL(@pdmsTemplates_TemplateName, '') = '') OR (dmsTemplates_TemplateName = @pdmsTemplates_TemplateName))
			AND ((ISNULL(@pdmsTemplates_TemplateDesc, '') = '') OR (dmsTemplates_TemplateDesc = @pdmsTemplates_TemplateDesc))
			AND ((ISNULL(@pdmsTemplates_TemplateGroup, '') = '') OR (dmsTemplates_TemplateGroup = @pdmsTemplates_TemplateGroup)))
		ORDER BY dmsTemplates_TemplateGroup, dmsTemplates_TemplateDesc
	END TRY		
		
	BEGIN CATCH		
		SELECT ERROR_MESSAGE() + ' SP: ' + OBJECT_NAME (@@PROCID)
	END CATCH





