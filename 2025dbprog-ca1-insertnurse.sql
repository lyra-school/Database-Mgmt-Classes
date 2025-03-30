use S00233718
go
create proc dbo.InsertNurse
@ECareTeamID int
, @ENurseID int
, @ECurrentDate smalldatetime
as
begin try
	insert into dbo.NurseCareTeamMembersTBL(CareTeamID, MemberID, DateJoineD, CurrentMember)
	values (@ECareTeamID, @ENurseID, @ECurrentDate, 1)
end try
begin catch
;throw
end catch