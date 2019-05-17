use master
go

declare @backupPath nvarchar(500);
set @backupPath = 'c:\temp\rubanko.bak';

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

	/* close existing connections */
	Declare @dbname sysname
	Set @dbname = 'rubanko'
	Declare @spid int
	Select @spid = min(spid) from master.dbo.sysprocesses
	where dbid = db_id(@dbname)
	While @spid Is Not Null
	Begin
			Execute ('Kill ' + @spid)
			Select @spid = min(spid) from master.dbo.sysprocesses
			where dbid = db_id(@dbname) and spid > @spid
	End

	/* restore backup */
	restore database rubanko from disk=@backupPath with replace

	select 'backup restored' message
end
else
	select 'no need to restore' message
