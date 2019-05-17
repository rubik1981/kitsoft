create database rubanko;
go

use rubanko;



/*	create and fill tables */

create table TFact ( TFactId int primary key identity(1,1), Year int not null, Month int not null, SomeINTData int not null, SomeTextData varchar(max));
go

declare @y int, @m int;
declare @i int, @j int;

set @i = 0;
while @i < 10 begin	
	set @y = 2017 + floor(rand()*2);
	set @m = floor(rand()*11)+1;

	set @j = 0;
	while @j < 10 begin
		insert into TFact(Year, Month, SomeINTData, SomeTextData)
		select @y, @m, floor(rand()*power(10,9)), newid();

		set @j = @j + 1;
	end;

	set @i = @i + 1;
end;

while (select count(*) from TFact) < power(10,5) begin
	insert into TFact(Year, Month, SomeINTData, SomeTextData) select Year, Month,SomeINTData, SomeTextData from TFact;
end;
delete from TFact where TFactID > power(10,5);

create index TFact_M1 on TFact (Year, Month);

create table THash (Year int, Month int, primary key (Year, Month), HashCode varchar(400));

go


/* create functions and procedures */

create function fnCalculateHash(@year int, @month int)
returns varchar(400)
as begin
	declare @c cursor;
	declare @data varchar(max);
	declare @hash varchar(400) = '';

	set @c = cursor fast_forward for
		select cast(SomeINTData as varchar(50)) + SomeTextData
		from TFact
		where Year = @year
			and Month = @month;

	open @c
	fetch next from @c into @data
	while @@FETCH_STATUS = 0 begin
		set @hash = HASHBYTES('sha1', @hash + @data)
	
		fetch next from @c into @data
	end

	return @hash
end
go

create function usp_Check(@year int, @month int)
returns bit
as begin
	declare @hash varchar(400) = dbo.fnCalculateHash(@year, @month);
	declare @res bit;
	if @hash = (select HashCode from THash where Year = @year and Month = @month)
		set @res = 1
	else
		set @res = 0

	return @res;
end
go


create procedure calculate_and_save_one @year int, @month int
as begin
	declare @hash varchar(400) = dbo.fnCalculateHash(@year, @month);

	if not exists(select 1 from THash where Year = @year and Month = @month)
		insert into THash (Year, Month, HashCode) values(@year, @month, @hash)
	else
		update THash
		set HashCode = @hash
		where Year = @year and Month = @month
end
go

create procedure usp_init
as begin
	declare @y int, @m int;

	declare @c cursor;
	set @c = cursor for
		select distinct Year, Month from TFact;
	
	open @c;
	fetch next from @c into @y, @m;
	while @@FETCH_STATUS = 0 begin
		exec calculate_and_save_one @y, @m;

		fetch next from @c into @y, @m;
	end
end
go

select Year, Month, count(*) records
from TFact
group by Year, Month