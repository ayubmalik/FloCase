	-- ==========================================================================================
	-- Author:		RPM
	-- Amended date: 21-07-2011
	-- ==========================================================================================


--RPM Adding a lookupcode for credit hire create pending task
  
  
  insert into LookupCode (Description,Code,LookupTypeCode,Inactive,CreateUser,CreateDate )
  values ('Credit Hire Advice','CRHIAD','TaskType',0,'RPM','2011-07-11 09:45:00')


UPDATE [LookupCode]
SET [Description] = 'Phone'      
 WHERE [Description] = 'Phone Call'
GO



IF NOT EXISTS (SELECT * FROM [AppDefinitionSchedule] 
WHERE [AppTaskDefinitionCode] = 'MATTCSLA' AND [ScheduleDefinitionName] ='Due Date')
BEGIN
      INSERT INTO [AppDefinitionSchedule]
           ([AppTaskDefinitionCode],[ScheduleDefinitionName])
      VALUES ('MATTCSLA','Due Date')
END
