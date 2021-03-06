
/****** Object:  StoredProcedure [dbo].[AppTask_Reschedule]    Script Date: 10/08/2012 18:21:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[AppTask_Reschedule]
(
	@pAppTaskID					int				= NULL,		-- Manditory. 
	@pUserName					nvarchar(255)	= NULL,		-- Manditory.  Map System.Username for Current User
	@pAppTaskDefinitionCode		nvarchar(50)	= NULL,
	@pDescription				nvarchar(255)	= NULL,
	@pLocation					nvarchar(255)	= NULL,
	@pAssignedTo				nvarchar(255)	= NULL,
	@pDueDate					smalldatetime	= Null,
	@pReminderDate				smalldatetime	= Null,
	@pAppTaskTypeCode			nvarchar(50)	= NULL,
	@pTaskStatusCode			nvarchar(10)	= NULL,
	@pContactID					int				= NULL,
	@pDocumentID				int				= NULL,
	@pKeyDateID					int				= NULL,
	@pCustomID1					int				= NULL,
	@pCustomID2					int				= NULL,
	@pCustomID3					int				= NULL,
	@pCustomID4					int				= NULL,
	@pCustomID5					int				= NULL,
	@pAppTaskSubTypeCode		nvarchar(50)	= NULL,
	@pComment					nvarchar(max)	= NULL,
	@pStartScheduleDate			smalldatetime	= Null,
	@pEndScheduleDate			smalldatetime	= Null,		-- Optional.
	@pPriorityCode				nVarchar(10),
	@pOutlook_GUID				nVARCHAR(256)   = NULL,		-- Optional.
	@pEscdate					smalldatetime	= NULL,		-- Optional.
	@pEscUser					nvarchar(255)	= NULL,		-- Optional.
	@pEscAppTaskID				int				= NULL,		-- Optional.
	@pEscTaskText				nvarchar(255)	= NULL,
	@pHistoricalTaskDesc		nvarchar(255)	= NULL,
	@pOutlookTaskOption			nvarchar(10)	= NULL,
	@pPersonAttending			nvarchar(255)	= NULL,
	@pAttDate					smalldatetime	= NULL,
	@pAttTime					nvarchar(255)	= NULL,
	@pNatureAttendance			nvarchar(255)	= NULL,
	@pReferencialCode			nvarchar(255)	= NULL,		-- GV 25/08/2011: to deal with link to other tables
	@pAppTaskDateModified		SMALLDATETIME	= NULL,		-- SMJ 21/09/2011: SET TO TODAY(GETDATE())	
	@pMatterPaymentsCode		nvarchar(255)	= NULL,		-- GV 18/4/2012: Release 5.15 - FLO87
	@pRoleCode					nvarchar(255)	= NULL,
	@pReturnID					bit = 1						-- GV 22/08/2012: added to return the AppTaskID or not
)
AS
	-- ==========================================================================================
	-- Updated by:		GV
	-- Modified date: 17-08-2011
	-- Changes made to not overwritte Task details with parameter default when no value provided
	-- ==========================================================================================
	
	-- ==========================================================================================
	-- Updated by:		GV
	-- Modified date: 25-08-2011
	-- Changes made to allow a referencial code to be passed in
	-- ==========================================================================================
	
	-- ==========================================================================================
	-- SMJ - Amended - 21-09-2011
	-- New column AppTask_DateModified to AppTask table
	-- Changed SP to take in this parameter and use it in insert
	-- ==========================================================================================

	-- ==========================================================================================
	-- GV - Amended - 22-09-2011
	-- SP will changed the AppTask_DateModified value if the AssignedTo changes
	-- ==========================================================================================

	SET NOCOUNT ON
	DECLARE @myLastError int 
	SELECT @myLastError = 0
	DECLARE @myLastErrorString nvarchar(255)
	SELECT @myLastErrorString = ''
	
	BEGIN TRANSACTION AppTaskReschedule
		
	IF (ISNULL(@pAppTaskID,0) > 0)
	BEGIN	
		IF (ISNULL(@pUserName,'') = '')
		BEGIN
			SET @myLastErrorString = '@UserName not supplied'
			GOTO THROW_ERROR_UPWARDS
		END
		
		-- GV 22/09/2011: new variables
		DECLARE @NewAssignedTo nvarchar(255)
		DECLARE @OldAssignedTo nvarchar(255)
	
		-- GV 17/08/2011: GET EXISTING VALUES FOR TASK
		SELECT 
			@NewAssignedTo = @pAssignedTo,
			@OldAssignedTo = AssignedTo,
			@pAppTaskDefinitionCode = ISNULL(@pAppTaskDefinitionCode,AppTaskDefinitionCode),
			@pDescription = ISNULL(@pDescription,[Description]),
			@pLocation = ISNULL(@pLocation,Location),
			@pAssignedTo = ISNULL(@pAssignedTo,AssignedTo),
			@pDueDate = ISNULL(@pDueDate,DueDate),
			@pReminderDate = ISNULL(@pReminderDate,ReminderDate),
			@pAppTaskTypeCode = ISNULL(@pAppTaskTypeCode,AppTaskTypeCode),
			@pTaskStatusCode = ISNULL(@pTaskStatusCode,StatusCode),
			@pContactID = ISNULL(@pContactID,ContactID),
			@pDocumentID = ISNULL(@pDocumentID,DocumentID),
			@pCustomID2 = ISNULL(@pCustomID2,CustomID1),
			@pCustomID2 = ISNULL(@pCustomID2,CustomID2),
			@pCustomID3 = ISNULL(@pCustomID3,CustomID3),
			@pCustomID4 = ISNULL(@pCustomID4,CustomID4),
			@pCustomID5 = ISNULL(@pCustomID5,CustomID5),
			@pAppTaskSubTypeCode = ISNULL(@pAppTaskSubTypeCode,AppTaskSubTypeCode),
			@pComment = ISNULL(@pComment,Comment),
			@pPriorityCode = ISNULL(@pPriorityCode,PriorityCode),
			@pEscdate = ISNULL(@pEscdate,Escdate),
			@pEscUser = ISNULL(@pEscUser,EscUser),
			@pEscAppTaskID = ISNULL(@pEscAppTaskID,EscAppTaskID),
			@pEscTaskText = ISNULL(@pEscTaskText,EscTaskText),
			@pHistoricalTaskDesc = ISNULL(@pHistoricalTaskDesc,HistoricalTaskDesc),
			@pOutlookTaskOption = ISNULL(@pOutlookTaskOption ,OutlookTaskOption),
			@pPersonAttending = ISNULL(@pPersonAttending,PersonAttending),
			@pAttDate = ISNULL(@pAttDate,AttDate),
			@pAttTime = ISNULL(@pAttTime,AttTime),
			@pNatureAttendance = ISNULL(@pNatureAttendance,NatureAttendance),
			@pReferencialCode = ISNULL(@pReferencialCode,Referencial_Code),
			@pAppTaskDateModified = ISNULL(@pAppTaskDateModified,AppTask_DateModified),
			@pMatterPaymentsCode = ISNULL(@pMatterPaymentsCode,MatterPayments_Code),
			@pRoleCode = ISNULL(@pRoleCode,RoleCode),
			@pKeyDateID = ISNULL(@pkeydateID,keydateid)
		FROM AppTask
		WHERE (AppTaskID = @pAppTaskID) 
		
		-- GV 22/09/2011: check if assignedTo has changed
		IF @NewAssignedTo <> @OldAssignedTo 
			SELECT @pAppTaskDateModified = GETDATE()		
		
		--**********************************************************************************************
		--TEMPORY CODE TO ALLOW USERS TO RESCHEDULE THE ESCALATION ON THE NEW REPORT TO CLIENT REMINDERS
		--GQL - 25.01.2010 TO BE REMOVED ONCE ALL OF THESE TASKS HAVE BEEN RESCHEDULED
		-- GV - 17/08/2011: changed IF statement 
		--IF (SELECT AppTaskDefinitionCode FROM APPTASK WHERE APPTASKID = @pAppTaskID) = 'CLNTREP'
		IF @pAppTaskDefinitionCode = 'CLNTREP'
		BEGIN
			--get the current caseid and store it in a variable
			DECLARE @pCaseID INT
	
			SELECT @pCaseID = CASEID 
			FROM ApplicationInstance 
			WHERE IdentifierValue = (SELECT AppInstanceValue FROM AppTask WHERE AppTaskID = @pAppTaskID)
			
			--set the escalation date to 1 week from the due date entred by the user
			SET @pEscdate = DATEADD(WEEK,1,@pDueDate)
			
			--update the date the next client report is due based on the due date entred by the user
			--SMJ - 06/08
			UPDATE [Case] 
			SET Case_ClntRepDte = DATEADD(WEEK,10,@pDueDate),
			Case_Date_Updated = GETDATE() WHERE Case_CaseID = @pCaseID 
		END
		--END OF TEMPORY CODE
		--GQL - 25.01.2010 
		--**********************************************************************************************
		
		UPDATE AppTask
		SET 
			AppTaskDefinitionCode = @pAppTaskDefinitionCode,
			[Description] = @pDescription,
			Location = @pLocation,
			AssignedTo = @pAssignedTo,
			DueDate = @pDueDate,
			ReminderDate = @pReminderDate,
			AppTaskTypeCode = @pAppTaskTypeCode,
			StatusCode = @pTaskStatusCode,
			ContactID = @pContactID,
			DocumentID = @pDocumentID,
			CustomID1 = @pCustomID1,
			CustomID2 = @pCustomID2,
			CustomID3 = @pCustomID3,
			CustomID4 = @pCustomID4,
			CustomID5 = @pCustomID5,
			AppTaskSubTypeCode = @pAppTaskSubTypeCode,
			Comment = @pComment,
			PriorityCode = @pPriorityCode,
			Escdate = @pEscdate,
			EscUser = @pEscUser,
			EscAppTaskID = @pEscAppTaskID,
			EscTaskText = @pEscTaskText,
			HistoricalTaskDesc = @pHistoricalTaskDesc,
			OutlookTaskOption = @pOutlookTaskOption ,
			PersonAttending	= @pPersonAttending,
			AttDate	= @pAttDate,
			AttTime	= @pAttTime,
			NatureAttendance = @pNatureAttendance,
			Referencial_Code = @pReferencialCode,
			AppTask_DateModified = @pAppTaskDateModified,
			MatterPayments_Code = @pMatterPaymentsCode,
			RoleCode=@pRoleCode,
			KeyDateID=@pkeydateid 
		WHERE (AppTaskID = @pAppTaskID) 
		
		UPDATE AppTaskSchedule
			SET 
			StartScheduleDate = ISNULL(@pStartScheduleDate, StartScheduleDate),
			EndScheduleDate = ISNULL(@pEndScheduleDate, EndScheduleDate),
			Outlook_GUID = ISNULL(@pOutlook_GUID, Outlook_GUID)
		WHERE (AppTaskID = @pAppTaskID) 
		
		SELECT @myLastError = @@ERROR
		IF @myLastError <> 0 GOTO THROW_ERROR_UPWARDS
	END
	
	COMMIT TRANSACTION AppTaskReschedule
	
	IF @pReturnID = 1
		SELECT @pAppTaskID AS AppTaskID 
	
	THROW_ERROR_UPWARDS:
	IF (@myLastError <> 0 ) OR (@myLastErrorString <> '')
	BEGIN
		ROLLBACK TRANSACTION AppTaskReschedule 
		SET @myLastErrorString = 'Error Occurred In Stored Procedure AppTask_Reschedule - ' + @myLastErrorString
		RAISERROR (@myLastErrorString, 16,1)
	END


