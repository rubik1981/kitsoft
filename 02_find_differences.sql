use tempdb
go


declare @backupPath nvarchar(500);
set @backupPath = 'ru3.bak';

if object_id('tempdb..#temp2') is not null
	drop table tempdb..#temp2

select Year, Month
into #temp2
from rubanko..THash
where rubanko.dbo.usp_check(Year, Month) = 0;

if (select count(*) from #temp2) > 0 
begin
	print 'need restore'

	/* restore backup */
	declare @mdf varchar(500);
	select @mdf=physical_name
	from sys.master_files 
	where name = 'rubanko'	
		and physical_name like '%rubanko.mdf';
	declare @newMdf varchar(500), @newLdf varchar(500);	
	set @newMdf = replace(@mdf, 'rubanko.mdf', 'rubanko_bak.mdf');
	set @newLdf = replace(@mdf, 'rubanko.mdf', 'rubanko_bak.ldf');
	restore database rubanko_bak 
	from disk=@backupPath 
	with move 'rubanko' to @newMdf, move 'rubanko_log' to @newLdf, replace;
	
	select f.*
	from rubanko..TFact f
		inner join tempdb..#temp2 t on t.Year = f.Year and t.Month = f.Month
	except
	select f.*
	from rubanko_bak..TFact f
		inner join tempdb..#temp2 t on t.Year = f.Year and t.Month = f.Month	
end
else
	select 'no differences found' message