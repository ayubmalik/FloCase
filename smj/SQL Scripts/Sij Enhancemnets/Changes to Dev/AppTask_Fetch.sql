
ALTER PROCEDURE [dbo].[AppTask_Fetch]
(
	@UserName				nvarchar(255)  = '',		-- eg CKJ.  Map System.Username for Current User
	@ApplicationCode		nvarchar(50) = '',			-- eg LTMM
	@AppInstanceValue		nvarchar(50) = '',			-- eg M12345
	@AppTaskID				int = 0,					-- 4567
	@StatusCode				nvarchar(10)  = 'Active',	-- eg Active or Complete
	@CaseID					int = 0,					-- eg 34545	Mandatory					
	@ExcludeEscalated		bit = 0
)
AS
	-- ==========================================================================================
	-- Author:		GQL
	-- Create date: 12-08-2009
	-- Description:	Stored Procedure to return a set of Task Information Given a Caseid and an optional Task Status Code
	-- ==========================================================================================
	
	
	-- ==========================================================================================
	-- Author:		SMJ
	-- Amended date: 12-07-2011
	-- Description:	Commented out line that returns extra data set
	--				Added DISTINCT when doing initial table insert and subsequent selects
	--				as was returning duplicate data
	-- ==========================================================================================
	
	-- ==========================================================================================
	-- Author:		SMJ
	-- Amended date: 15-07-2011
	-- Description:	Insert and return new field MatterPayments_Code
	-- ==========================================================================================
	
	-- ==========================================================================================
	-- Author:		SMJ
	-- Amended date: 14-09-2011
	-- Description:	Filtered CaseContacts join on RoleCode = 'CLIENT'
	-- ==========================================================================================	
	
	-- ==========================================================================================
	-- Author:		SMJ
	-- Amended date: 29-09-2011
	-- Description:	Returns new columns PrintStatus and DateLastPrinted
	-- ==========================================================================================	
	

	-- ==========================================================================================
	-- Author:		SMJ
	-- Amended date: 11-06-2012
	-- Description:	Added new param ExcludeEscalated - if passed in doesn't return escalated tasks
	-- ==========================================================================================		


	-- ==========================================================================================
	-- Author:		CKJ
	-- Amended date: 26-09-2012
	-- Description:	Refactored for performance
	--				SMJ - Also changed error handling, added WITH (NOLOCK) and schema names
	-- ==========================================================================================		


	-- ==========================================================================================
	-- Author:		SMJ
	-- Amended date: 27-09-2012
	-- Description:	Missing AppTaskTypeDesc
	-- ==========================================================================================		

	SET NOCOUNT ON	
	DECLARE @errNoCaseID VARCHAR(50)
	
	SET @errNoCaseID = 'YOU MUST PROVIDE A @CaseID.'

	--SET DATE FORMAT TO UK FORMAT
	SET DATEFORMAT DMY
	
	BEGIN TRY
		----Test to see that a Caseid has been supplied
		IF (ISNULL(@CaseID,0) = 0)
			RAISERROR (@errNoCaseID, 16,1)

		IF @StatusCode = 'Complete'

			SELECT DISTINCT
				AppTask.AppTaskID, AppTaskDefinition.ApplicationCode, ApplicationInstance.CaseID, AppTask.AppTaskDefinitionCode, AppTask.AppInstanceValue,
				'<a href=http://' + SystemSettings.SystemSettings_ServerName + '//floclient/default.aspx?CallType=Process&ProcessName=LTMM+Action+Manager&LTMMProcessName=' + AppTaskDefinition.ProcessName + '&MatterPayments_Code=' + MatterPayments_Code + '&LTMMWorkFlowName=' + AppTaskDefinition.WorkflowName + '&CaseID=' + RTRIM(CAST(ApplicationInstance.CaseID AS VARCHAR(MAX))) + '&AppTaskID=' + RTRIM(CAST(AppTask.AppTaskID AS VARCHAR(MAX)))  + '&ReferencialCode=' + RTRIM(CAST(AppTask.Referencial_Code AS VARCHAR(MAX)))  + ' target=_blank> TASK: ' + AppTask.[Description] as [TaskLink],
				CASE WHEN (AppTask.StatusCode = 'Deleted')
					THEN 'No longer required: ' + AppTask.[Description]
					ELSE AppTask.[Description]
				END AS [Description],
				AppTask.Location, 
				CreatedBy, 
				CreatedDate,
				left(datename(WEEKDAY , CreatedDate),3) + ' ' + cast(datepart(d,CreatedDate) as nvarchar(2)) +  ' ' + left(datename(M , CreatedDate),3) + ' ' + cast(datepart(YYYY, CreatedDate) as nvarchar(4)) as TextCreatedDate,
				CASE WHEN (datepart(mi, CreatedDate) > 9) 
					THEN cast(datepart(hh, CreatedDate) as nvarchar(4)) + ':' + cast(datepart(mi, CreatedDate)as nvarchar(4))
					ELSE cast(datepart(hh, CreatedDate) as nvarchar(4)) + ':' + '0' + cast(datepart(mi, CreatedDate)as nvarchar(4))
				END  as TextCreateTime,
				AssignedTo, 
				AppTask_DateModified AS AssignedDate,
				DueDate,
				left(datename(WEEKDAY , DueDate),3) + ' ' + cast(datepart(d,DueDate) as nvarchar(2)) +  ' ' + left(datename(M , DueDate),3) + ' ' + cast(datepart(YYYY, DueDate) as nvarchar(4)) as TextDueDate,
				AppTask.ReminderDate,
				CASE WHEN (isnull(CompletedBy,'') = '')
					THEN DeletedBy  
					ELSE CompletedBy
				END AS CompletedBy,
				Case WHEN (ISNULL(DeletedDate, '') = '')
					THEN CompletedDate
					ELSE DeletedDate
				END AS XCompletedDate,
				CompletedDate,
				CASE WHEN (isnull(CompletedDate, 0) = 0) 
					THEN left(datename(WEEKDAY , DeletedDate),3) + ' ' + cast(datepart(d,DeletedDate) as nvarchar(2)) +  ' ' + left(datename(M, DeletedDate),3) + ' ' + cast(datepart(YYYY, DeletedDate) as nvarchar(4))
					ELSE left(datename(WEEKDAY , CompletedDate),3) + ' ' + cast(datepart(d,CompletedDate) as nvarchar(2)) +  ' ' + left(datename(M , CompletedDate),3) + ' ' + cast(datepart(YYYY, CompletedDate) as nvarchar(4))
				END as TextCompletedDate,
				CASE WHEN (isnull(CompletedDate, 0) = 0)
					THEN
						CASE WHEN (datepart(mi, DeletedDate) > 9) 
							THEN cast(datepart(hh, DeletedDate) as nvarchar(4)) + ':' + cast(datepart(mi, DeletedDate)as nvarchar(4))
							ELSE cast(datepart(hh, DeletedDate) as nvarchar(4)) + ':' + '0' + cast(datepart(mi, DeletedDate)as nvarchar(4))
						END
					ELSE
						CASE WHEN (datepart(mi, CompletedDate) > 9) 
							THEN cast(datepart(hh, CompletedDate) as nvarchar(4)) + ':' + cast(datepart(mi, CompletedDate)as nvarchar(4))
							ELSE cast(datepart(hh, CompletedDate) as nvarchar(4)) + ':' + '0' + cast(datepart(mi, CompletedDate)as nvarchar(4))
						END
				END  as TextCompleteTime,
				AppTask.StatusCode, ContactID, DocumentID, AppTask.KeyDateID, 
				CustomID1, CustomID2, CustomID3, CustomID4,	CustomID5, 
				AppTask.AppTaskSubTypeCode, AppTask.Comment, AppTask.PriorityCode, AppTaskDefinition.WorkflowName,
				AppTaskDefinition.ProcessName, AppTaskDefinition.UserLevelCode, AppTaskDefinition.AppStageCode, AppTaskDefinition.AppWorkTypeCode,
				AppTask.AppTaskTypeCode, AppTaskSchedule.StartScheduleDate, AppTaskSchedule.EndScheduleDate, AppTaskSchedule.Outlook_GUID,
				D.CaseContacts_SearchName AS ClientName, c.Case_MatterDescription AS MatterDescription, c.Case_BLMREF as BLMREF,
				AppTask.EscDate as EscDate, AppTask.EscUser as EscUser, AppTask.EscAppTaskID as EscAppTaskID, AppTask.EscTaskText as EscTaskText,
				AppTask.HistoricalTaskDesc as HistoricalTaskDesc, at.[Description] AS AppTaskTypeDesc, AppTask.OutlookTaskOption, AppTask.PersonAttending, 
				AppTask.AttDate, AppTask.AttTime, AppTask.NatureAttendance, 
				AppTask.MatterPayments_Code, AppTask.Referencial_Code, 
				AppTask.PrintStatus, AppTask.DateLastPrinted,
				AppTask.RoleCode 
			FROM dbo.[Case] c WITH (NOLOCK)
			INNER JOIN dbo.ApplicationInstance WITH (NOLOCK) ON (ApplicationInstance.CaseID = c.Case_CaseID)
			INNER JOIN dbo.AppTask WITH (NOLOCK) ON (AppTask.AppInstanceValue = ApplicationInstance.IdentifierValue)
			INNER JOIN dbo.AppTaskSchedule WITH (NOLOCK) ON (AppTask.AppTaskID = AppTaskSchedule.AppTaskID)
			INNER JOIN dbo.AppTaskDefinition WITH (NOLOCK) ON (AppTaskDefinition.AppTaskDefinitionCode = AppTask.AppTaskDefinitionCode)
			INNER JOIN dbo.AppTaskType at WITH (NOLOCK) ON AppTask.AppTaskTypeCode = at.AppTaskTypeCode
			INNER JOIN dbo.CaseContacts d WITH (NOLOCK) ON (d.CaseContacts_CaseID = c.Case_CaseID) 
						and (ISNULL(d.CaseContacts_ClientID, 0) > 0) AND (d.CaseContacts_Inactive = 0)
						AND (d.CaseContacts_RoleCode = 'CLIENT')
			INNER JOIN dbo.SystemSettings WITH (NOLOCK) ON (SystemSettings.SystemSettings_Inactive = 0)
				
			WHERE (c.Case_CaseID = @CaseID)
					AND ((AppTask.StatusCode = 'Complete') OR (AppTask.StatusCode = 'Deleted') )
					AND ((@ApplicationCode) = '' OR (AppTaskDefinition.ApplicationCode = @ApplicationCode))
					AND ((@AppTaskID = 0) OR (AppTask.AppTaskID = @AppTaskID))
					AND ((@ExcludeEscalated = 0) OR (AppTaskDefinition.AppTaskDefinitionCode <> 'EscTask'))
			ORDER BY XCompletedDate desc, TextCreateTime desc
		ELSE
			SELECT DISTINCT
				AppTask.AppTaskID, AppTaskDefinition.ApplicationCode, ApplicationInstance.CaseID, AppTask.AppTaskDefinitionCode, AppTask.AppInstanceValue,
				'<a href=http://' + SystemSettings.SystemSettings_ServerName + '//floclient/default.aspx?CallType=Process&ProcessName=LTMM+Action+Manager&LTMMProcessName=' + AppTaskDefinition.ProcessName + '&MatterPayments_Code=' + MatterPayments_Code + '&LTMMWorkFlowName=' + AppTaskDefinition.WorkflowName + '&CaseID=' + RTRIM(CAST(ApplicationInstance.CaseID AS VARCHAR(MAX))) + '&AppTaskID=' + RTRIM(CAST(AppTask.AppTaskID AS VARCHAR(MAX)))  + '&ReferencialCode=' + RTRIM(CAST(AppTask.Referencial_Code AS VARCHAR(MAX)))  + ' target=_blank> TASK: ' + AppTask.[Description] as [TaskLink],
				CASE WHEN (AppTask.StatusCode = 'Deleted')
					THEN 'No longer required: ' + AppTask.[Description]
					ELSE AppTask.[Description]
				END AS [Description],
				AppTask.Location, CreatedBy, CreatedDate,
				left(datename(WEEKDAY , CreatedDate),3) + ' ' + cast(datepart(d,CreatedDate) as nvarchar(2)) +  ' ' + left(datename(M , CreatedDate),3) + ' ' + cast(datepart(YYYY, CreatedDate) as nvarchar(4)) as TextCreatedDate,
				CASE WHEN (datepart(mi, CreatedDate) > 9) 
					THEN cast(datepart(hh, CreatedDate) as nvarchar(4)) + ':' + cast(datepart(mi, CreatedDate)as nvarchar(4))
					ELSE cast(datepart(hh, CreatedDate) as nvarchar(4)) + ':' + '0' + cast(datepart(mi, CreatedDate)as nvarchar(4))
				END  as TextCreateTime,
				AssignedTo, 
				AppTask_DateModified  AS AssignedDate,
				DueDate,
				left(datename(WEEKDAY , DueDate),3) + ' ' + cast(datepart(d,DueDate) as nvarchar(2)) +  ' ' + left(datename(M , DueDate),3) + ' ' + cast(datepart(YYYY, DueDate) as nvarchar(4)) as TextDueDate,
				AppTask.ReminderDate,
				CASE WHEN (isnull(CompletedBy,'') = '')
					THEN DeletedBy  
					ELSE CompletedBy
				END AS CompletedBy,
				Case WHEN (ISNULL(DeletedDate, '') = '')
					THEN CompletedDate
					ELSE DeletedDate
				END AS XCompletedDate,
				CompletedDate,
				CASE WHEN (isnull(CompletedDate, 0) = 0) 
					THEN left(datename(WEEKDAY , DeletedDate),3) + ' ' + cast(datepart(d,DeletedDate) as nvarchar(2)) +  ' ' + left(datename(M, DeletedDate),3) + ' ' + cast(datepart(YYYY, DeletedDate) as nvarchar(4))
					ELSE left(datename(WEEKDAY , CompletedDate),3) + ' ' + cast(datepart(d,CompletedDate) as nvarchar(2)) +  ' ' + left(datename(M , CompletedDate),3) + ' ' + cast(datepart(YYYY, CompletedDate) as nvarchar(4))
				END as TextCompletedDate,
				CASE WHEN (isnull(CompletedDate, 0) = 0)
					THEN
						CASE WHEN (datepart(mi, DeletedDate) > 9) 
							THEN cast(datepart(hh, DeletedDate) as nvarchar(4)) + ':' + cast(datepart(mi, DeletedDate)as nvarchar(4))
							ELSE cast(datepart(hh, DeletedDate) as nvarchar(4)) + ':' + '0' + cast(datepart(mi, DeletedDate)as nvarchar(4))
						END
					ELSE
						CASE WHEN (datepart(mi, CompletedDate) > 9) 
							THEN cast(datepart(hh, CompletedDate) as nvarchar(4)) + ':' + cast(datepart(mi, CompletedDate)as nvarchar(4))
							ELSE cast(datepart(hh, CompletedDate) as nvarchar(4)) + ':' + '0' + cast(datepart(mi, CompletedDate)as nvarchar(4))
						END
				END  as TextCompleteTime,
				AppTask.StatusCode, ContactID, DocumentID, AppTask.KeyDateID, 
				CustomID1, CustomID2, CustomID3, CustomID4,	CustomID5, 
				AppTask.AppTaskSubTypeCode, AppTask.Comment, AppTask.PriorityCode, AppTaskDefinition.WorkflowName,
				AppTaskDefinition.ProcessName, AppTaskDefinition.UserLevelCode, AppTaskDefinition.AppStageCode, AppTaskDefinition.AppWorkTypeCode,
				AppTask.AppTaskTypeCode, AppTaskSchedule.StartScheduleDate, AppTaskSchedule.EndScheduleDate, AppTaskSchedule.Outlook_GUID,
				D.CaseContacts_SearchName AS ClientName, c.Case_MatterDescription AS MatterDescription, c.Case_BLMREF as BLMREF,
				AppTask.EscDate as EscDate, AppTask.EscUser as EscUser, AppTask.EscAppTaskID as EscAppTaskID, AppTask.EscTaskText as EscTaskText,
				AppTask.HistoricalTaskDesc as HistoricalTaskDesc, at.[Description] AS AppTaskTypeDesc, AppTask.OutlookTaskOption, AppTask.PersonAttending, 
				AppTask.AttDate, AppTask.AttTime, AppTask.NatureAttendance, 
				AppTask.MatterPayments_Code, AppTask.Referencial_Code, 
				AppTask.PrintStatus, AppTask.DateLastPrinted,
				AppTask.RoleCode 
				
			FROM dbo.[Case] c WITH (NOLOCK)
			INNER JOIN dbo.ApplicationInstance WITH (NOLOCK) ON (ApplicationInstance.CaseID = c.Case_CaseID)
			INNER JOIN dbo.AppTask WITH (NOLOCK) ON (AppTask.AppInstanceValue = ApplicationInstance.IdentifierValue)
			INNER JOIN dbo.AppTaskSchedule WITH (NOLOCK) ON (AppTask.AppTaskID = AppTaskSchedule.AppTaskID)
			INNER JOIN dbo.AppTaskDefinition WITH (NOLOCK) ON (AppTaskDefinition.AppTaskDefinitionCode = AppTask.AppTaskDefinitionCode)
			INNER JOIN dbo.AppTaskType at WITH (NOLOCK) ON AppTask.AppTaskTypeCode = at.AppTaskTypeCode
			INNER JOIN dbo.CaseContacts d WITH (NOLOCK) ON (d.CaseContacts_CaseID = c.Case_CaseID) 
						and (ISNULL(d.CaseContacts_ClientID, 0) > 0) AND (d.CaseContacts_Inactive = 0)
						AND (d.CaseContacts_RoleCode = 'CLIENT')
			INNER JOIN dbo.SystemSettings WITH (NOLOCK) ON (SystemSettings.SystemSettings_Inactive = 0)
				
			WHERE (c.Case_CaseID = @CaseID)
					AND (AppTask.StatusCode = 'Active') 
					AND ((@ApplicationCode) = '' OR (AppTaskDefinition.ApplicationCode = @ApplicationCode))
					AND ((@AppTaskID = 0) OR (AppTask.AppTaskID = @AppTaskID))
					AND ((@ExcludeEscalated = 0) OR (AppTaskDefinition.AppTaskDefinitionCode <> 'EscTask'))
					
					AND ((@UserName = '') OR (apptask.AssignedTo = @UserName))
			ORDER BY DueDate
		END TRY

	BEGIN CATCH
		SELECT ERROR_MESSAGE() + ' SP: ' + OBJECT_NAME (@@PROCID)
	END CATCH




