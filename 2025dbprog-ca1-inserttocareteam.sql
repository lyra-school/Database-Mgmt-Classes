use S00233718
go
create proc dbo.InsertToCareTeam
@ECareTeamID int
, @EPatientID int
as
-- the sproc is called InsertToCareTeam, not InsertToCareTeams
-- so presumably it's used for only one entity, therefore looping must be done in
-- the master sproc
begin try
	update dbo.CareTeamTBL
	set PatientID = @EPatientID
	where CareTeamID = @ECareTeamID
end try
begin catch
;throw
end catch