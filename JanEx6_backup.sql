use S00233718SQLExam
go
create proc JanEx6
	@InputID int
as
begin try
	delete from Patrons.FunderTBL
	where FunderID like @InputID
end try
begin catch
;throw
end catch