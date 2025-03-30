use S00233718
go
create proc dbo.InsertPatient
@EPatientFname varchar(35)
,@EPatientLname varchar(35)
,@EPatientWard int
,@EPatientCOVIDStatus char(8)
,@OPatientID int output
as
begin try
	insert into dbo.PatientTBL (PatientFname, PatientLname, PatientWarD, PatientCOVIDStatus)
	values (@EPatientFname, @EPatientLname, @EPatientWard, @EPatientCOVIDStatus)

	select @OPatientID = SCOPE_IDENTITY()
end try
begin catch
;throw
end catch