--DON'T RUN THIS - THE SP IS ON LIVE - Temp_Rebuild_Indexes

Create Table #IndexTable
(
ID int Identity(1,1) not null,
Table_Name varchar(100) not null
)

Insert into #IndexTable
Select name from sys.tables
Where type_desc = 'USER_TABLE'

Declare @TableName Varchar(100)
Declare @sql Varchar(1000)
Declare @fillfactor int
Declare @Loop int
Declare @cnt int
Select @cnt = COUNT(*) from #IndexTable
Set @Loop = 0
set @fillfactor = 80
While (@Loop < @cnt )
BEGIN
Select Top 1 @TableName = Table_Name from #IndexTable
Where ID not in (Select Top(@Loop)ID from #IndexTable)
IF @TableName <> 'Case'
BEGIN
	Set @sql = 'ALTER INDEX ALL ON ' + @TableName + ' REBUILD WITH (FILLFACTOR = ' + CONVERT(VARCHAR(3),@fillfactor) + ')'
	Exec(@sql)
END
Set @Loop += 1

END

DROP Table #IndexTable



ALTER INDEX ALL ON  [case] REBUILD WITH (FILLFACTOR = 80)


DECLARE @TableName VARCHAR(255)
DECLARE @sql NVARCHAR(500)
DECLARE @fillfactor INT
SET @fillfactor = 80
DECLARE TableCursor CURSOR FOR
SELECT OBJECT_SCHEMA_NAME([object_id])+'.'+name AS TableName
FROM sys.tables
OPEN TableCursor
FETCH NEXT FROM TableCursor INTO @TableName
WHILE @@FETCH_STATUS = 0
BEGIN
SET @sql = 'ALTER INDEX ALL ON ' + @TableName + ' REBUILD WITH (FILLFACTOR = ' + CONVERT(VARCHAR(3),@fillfactor) + ')'
EXEC (@sql)
FETCH NEXT FROM TableCursor INTO @TableName
END
CLOSE TableCursor
DEALLOCATE TableCursor
GO


