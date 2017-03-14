
declare @recid as numeric
declare @fieldName as nvarchar(50)
declare @tableName as nvarchar(50)
declare @tableId as int
declare @query as nvarchar(max)
declare @sqlStatement as nvarchar(max)
declare @tableCount as nvarchar(max)
declare @@count as int

create table #tmpIDs (recid numeric)
create table #tmptblcount (total int)



--select max(recid) from HRMParameters
declare tableCursor CURSOR for
select SQLNAME,TABLEID from SQLDICTIONARY 
where 
	name in
	 (
		select SQLNAME from  SQLDICTIONARY where SQLNAME like '%ledgerjournal%' and SQLNAME not like '%view%' and ARRAY=0
		union
		select SQLNAME from  SQLDICTIONARY where SQLNAME like '%custinvoice%' and SQLNAME not like '%view%' and ARRAY=0
		union
		select SQLNAME from  SQLDICTIONARY where SQLNAME like '%vendinvoice%' and SQLNAME not like '%view%' and ARRAY=0
		union
		select SQLNAME from  SQLDICTIONARY where SQLNAME like '%generaljournal%' and SQLNAME not like '%view%' and ARRAY=0
	 )
	and ARRAY=0 and SQLNAME <> '<source table>' 
	
	
	

open tableCursor;
fetch next from tableCursor into @tableName,@tableId
while (@@FETCH_STATUS = 0) 
BEGIN
	delete from #tmptblcount;
	set  @tableCount= 'Insert into #tmptblcount (total) SELECT count(recid)   FROM '+@tableName
	exec(@tableCount)
	--select total from #tmptblcount
	if((select total from #tmptblcount) = 0 )
	begin
		select @tableName +'is skipped'
		delete from #tmptblcount;
		fetch next from tableCursor
		into @tableName,@tableId
		
		continue
	end
	delete  from #tmpIDs

	set @query = 'Insert into #tmpIDs (recid) SELECT  recid FROM '+@tableName
	exec(@query)
	declare              jvCursor cursor for
	select  recid from #tmpIDs

	open                 jvCursor;
	FETCH NEXT FROM jvCursor INTO @recid;
	WHILE (@@FETCH_STATUS = 0) 
	BEGIN
		-- FIELD CURSOR
		declare fieldCursor CURSOR for
		select SQLNAME from SQLDICTIONARY 
		where 
			TABLEID =@tableId
			and ARRAY=1 and SQLNAME <> 'recid'
			and SQLNAME in (
								select SQLNAME from  SQLDICTIONARY where TABLEID=@tableId and SQLNAME like '%amount%'  and ARRAY =1
								union 
								select SQLNAME from  SQLDICTIONARY where TABLEID=@tableId and SQLNAME like '%price%' and ARRAY =1
								union
								select SQLNAME from  SQLDICTIONARY where TABLEID=@tableId and SQLNAME like '%balance%' and ARRAY =1
								union
								select SQLNAME from  SQLDICTIONARY where TABLEID=@tableId and SQLNAME like '%basic%' and ARRAY =1
							)

		open fieldCursor;
		fetch next from fieldCursor into @fieldName
		while (@@FETCH_STATUS = 0) 
		BEGIN
			 --NEWID() is generated once per query, so we update the  in many queries
			set @sqlStatement=' update '+@tableName+' 
			set ' +@fieldName+' =(select top 1 '+ @fieldName+' from '+@tableName+' order by NEWID()) 
			where recid = '+ cast( @recid as nvarchar(20))
			exec(@sqlStatement)

			--SELECT  @tableName,@fieldName,(select count(*) from #tmpIDs)
			fetch next from fieldCursor
			into @fieldName
		END

		close fieldCursor ;
		deallocate fieldCursor;
		-- END FIELD CURSOR
			
		fetch next from    jvCursor
		into          @recid
	END
		
	close                jvCursor;
	deallocate           jvCursor;
	
fetch next from tableCursor
into @tableName,@tableId

END

close tableCursor ;
deallocate tableCursor
drop table #tmpIDs
drop table #tmptblcount