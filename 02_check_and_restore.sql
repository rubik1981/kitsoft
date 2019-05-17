use tempdb
go


declare @backupPath nvarchar(500);
set @backupPath = 'ru.bak';

if object_id('tempdb..#temp') is not null
	drop table tempdb..#temp

select cast(Year as varchar(4)) + '-' + cast(Month as varchar(2)) ChangedPeriod
into #temp
from rubanko..THash
where rubanko.dbo.usp_check(Year, Month) = 0;

select *
from #temp

if (select count(*) from #temp) > 0 
begin
	print 'need restore'

	/* restore backup */
	ALTER DATABASE rubanko SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	restore database rubanko from disk=@backupPath with replace
	ALTER DATABASE rubanko SET MULTI_USER

	select 'backup restored' message
end
else
	select 'no need to restore' message