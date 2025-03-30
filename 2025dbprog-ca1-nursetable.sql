use S00233718
go
create type EligibleNurses as table (
	NurseID int,
	NurseSpecialty varchar(50),
	NurseWard int,
	COVID19Vaccinated bit
);