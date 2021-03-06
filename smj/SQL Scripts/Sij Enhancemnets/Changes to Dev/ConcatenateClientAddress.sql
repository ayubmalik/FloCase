USE [Flosuite_Data_Dev]
GO
/****** Object:  UserDefinedFunction [dbo].[ConcatenateClientAddress]    Script Date: 09/11/2012 17:01:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		SMJ
-- Create date: 	24/08/2012
-- Description:	
-- =============================================
ALTER FUNCTION [dbo].[ConcatenateClientAddress] 
(
	@Name_Uno int
	 
)
RETURNS varchar(3000)

AS
BEGIN
	
	declare @result nvarchar(3000)
	
	select @result = 
	
		ISNULL(ADDRESS1, '') +
		case when (ADDRESS2<> '') then ', '+ADDRESS2 else '' end +
		case when (ADDRESS3 <> '') then ', '+ADDRESS3 else '' end + 
		case when (ADDRESS4 <> '') then ', '+ADDRESS4 else '' end + 
		case when (CITY <> '') then ', '+CITY else '' end +
		case when (POST_CODE <> '') then ', '+POST_CODE else '' end 
	FROM HBM_ADDRESS a
	WHERE (a.NAME_UNO = @Name_Uno)
		
	
	RETURN (@result)
END
