-- why do I have identical looking test sprocs in here (except for exec)? because I can't put more than one test
-- per sproc because SET XACT_ABORT OFF doesn't actually do anything and SQL Server rolls everything back
-- for no reason sometimes anyway. Thanks, Microsoft.

-- I didn't have an explicit rollback in begin catch for exec dbo.ExamMaster at the time; you will see when running these tests that
-- SOME OTHER times, it won't roll the transaction back but it WILL ignore 'rollback transaction' at the end of a given test
-- I don't know how to fix this or what's causing it

-- and because I can't use raiserror() as per project requirements, I can't prevent this

-- also because of the same odd issue that's causing this, each of these procs has to be run twice within
-- same connection to apply rollback
-- no print() message = test succeeded
create proc dbo.ExamTests
as
begin transaction
-- run this sproc ONLY on empty tables; identity inserts are dangerous in terms of conflicts otherwise
-- apologies for how messy this looks, whoever worked on SQL Server implemented a feature where only
-- one table at a time can have IDENTITY INSERT set to ON

-- this is necessary due to a feature with try-catch blocks in SQL Server...
set XACT_ABORT OFF;

-- populate all test data before proceeding
begin try
	set identity_insert dbo.WarDTBL on;
	insert into dbo.WarDTBL(WardID, WardName, WardCapacity, WardSpeciality)
	values
	(1, 'Mortuary', 5, 'Death')
	,(2, 'Kids <=13', 2, 'Paediatric13')
	,(3, 'Teens <15', 5, 'Paediatric15')
	,(4, 'Teens <18', 5, 'Paediatric')
	set identity_insert dbo.WarDTBL off;

	set identity_insert dbo.DoctorTBL on;
	-- COVID vaccination status doesn't seem to matter for doctors?
	insert into dbo.DoctorTBL(DoctorID, DoctorName, DoctorSpeciality)
	values
	-- the extra characters beside the last 3 exist to prove that the sproc is capable of isolating
	-- just the last three characters
	(1, 'Dr Frankenstein', 'mortDea')
	,(2, 'Dr Doofenshmirtz', 'evilincPae')
	,(3, 'Dr Strangelove', 'irrelevant')
	set identity_insert dbo.DoctorTBL off;

	set identity_insert dbo.PatientTBL on;
	-- other columns are irrelevant (it doesn't matter that a patient has COVID if they're already in the db)
	insert into dbo.PatientTBL(PatientID, PatientFname, PatientLname, PatientWarD)
	values
	-- inserts to the mortuary will pass on weekdays OR weekends
	(1, 'Frankensteins', 'Monster', 1)
	,(2, 'Morticia', 'Addams', 1)
	-- Paediatric13 ward inserts won't pass on weekdays OR weekends due to numbers
	,(3, 'Pippi', 'Longstocking', 2)
	,(4, 'Snotty', 'Betty', 2)
	-- Paediatric15 inserts will only pass on weekends (change system clock?)
	-- it worked for me on Saturday
	,(5, 'Harry', 'Du Bois', 3)
	,(6, 'Kim', 'Kitsuragi', 3)
	,(7, 'Cuno', null, 3)
	,(8, 'Cunoesse', null, 3)
	,(9, 'Dolores', 'Dei', 3)
	-- the other Paed doesn't need its own patient data
	set identity_insert dbo.PatientTBL off;

	-- according to class, PatientID in a care team should always be null when this query is run
	-- no point testing with any other cols
	insert into dbo.CareTeamTBL(CareTeamID)
	values
	-- 2 nurses 1 doctor
	(1)
	-- 2 nurses 2 doctors
	,(2)
	-- 2 nurses 1 doctor (with bad speciality)
	,(3)
	-- 0 nurses 1 doctor
	,(4)
	-- 2 nurses 0 doctors
	,(5)
	-- 1 nurse 1 doctor
	,(6)
	-- 1 nurse 1 doctor (but patient is covid positive)
	,(7)

	set identity_insert dbo.NurseTBL on;
	-- no need to test Pae13 because it will always fail on patient insert due to capacity
	insert into dbo.NurseTBL(NurseID, NurseName, NurseSpeciality, NurseWarD, COVID19Vacinated)
	values
	(1, 'Cool Auntie', 'Pae', 4, 1)
	,(2, 'Cooler Auntie', 'Pae', 4, 0)
	,(3, 'Coolest Auntie', 'Pae', 3, 1)
	,(4, 'Most Coolest Auntie', 'Pae', 3, 1)
	-- she's already actively assigned to a team
	,(5, 'Even More Coolest Auntie', 'Pae', null, 0)
	,(6, 'Plague Doctor', 'Dea', 1, 1)
	-- no assignments
	,(7, 'i ran out of ideas', 'Pae', null, 1)
	,(8, 'Typhoid Mary', 'Pae', 4, 0)
	set identity_insert dbo.NurseTBL off;

	insert into dbo.DoctorCareTeamMembersTBL(CareTeamID, MemberID)
	values
	(1, 2)
	, (2, 2)
	, (2, 1)
	, (3, 3)
	, (4, 1)
	, (6, 2)
	, (7, 2)

	-- CurrentMember is there to demo that a nurse is not considered part of that team
	insert into dbo.NurseCareTeamMembersTBL(CareTeamID, MemberID, CurrentMember)
	values
	(1, 1, 1)
	,(1, 2, 1)
	,(1, 8, 0)
	,(2, 1, 1)
	,(2, 6, 1)
	,(3, 8, 1)
	,(3, 5, 1)
	,(4, 6, 0)
	,(5, 5, 1)
	,(5, 6, 1)
	,(6, 1, 1)
	,(7, 3, 1)

end try
begin catch
	rollback transaction
	print('Tests cannot proceed due to a failure in populating test data')
	;throw
end catch

declare @Error int, @Message varchar(200);
begin try
	-- will fail due to capacity
	exec dbo.ExamMaster 'tEstName', 'cApiTaLs', '2024-01-01', 'Positive', 2, 1
end try
begin catch
	select @Error = ERROR_NUMBER()
	select @Message = ERROR_MESSAGE()
	if(@Error = 50001)
	begin
		print(@Message)
		print('Test correctly failed from lacking ward capacity')
	end
end catch

begin try
	-- will fail due to age requirements
	exec dbo.ExamMaster 'Test', 'Person', '2000-01-01', 'Positive', 4, 1
end try
begin catch
	select @Error = ERROR_NUMBER()
	select @Message = ERROR_MESSAGE()
	if(@Error = 50007)
	begin
		print(@Message)
		print('Test correctly failed from lacking ward capacity')
	end
end catch
rollback transaction
go;

create proc dbo.ExamTests2
as
begin transaction
-- run this sproc ONLY on empty tables; identity inserts are dangerous in terms of conflicts otherwise
-- apologies for how messy this looks, whoever worked on SQL Server implemented a feature where only
-- one table at a time can have IDENTITY INSERT set to ON

-- this is necessary due to a feature with try-catch blocks in SQL Server...
set XACT_ABORT OFF;

-- populate all test data before proceeding
begin try
	set identity_insert dbo.WarDTBL on;
	insert into dbo.WarDTBL(WardID, WardName, WardCapacity, WardSpeciality)
	values
	(1, 'Mortuary', 5, 'Death')
	,(2, 'Kids <=13', 2, 'Paediatric13')
	,(3, 'Teens <15', 5, 'Paediatric15')
	,(4, 'Teens <18', 5, 'Paediatric')
	set identity_insert dbo.WarDTBL off;

	set identity_insert dbo.DoctorTBL on;
	-- COVID vaccination status doesn't seem to matter for doctors?
	insert into dbo.DoctorTBL(DoctorID, DoctorName, DoctorSpeciality)
	values
	-- the extra characters beside the last 3 exist to prove that the sproc is capable of isolating
	-- just the last three characters
	(1, 'Dr Frankenstein', 'mortDea')
	,(2, 'Dr Doofenshmirtz', 'evilincPae')
	,(3, 'Dr Strangelove', 'irrelevant')
	set identity_insert dbo.DoctorTBL off;

	set identity_insert dbo.PatientTBL on;
	-- other columns are irrelevant (it doesn't matter that a patient has COVID if they're already in the db)
	insert into dbo.PatientTBL(PatientID, PatientFname, PatientLname, PatientWarD)
	values
	-- inserts to the mortuary will pass on weekdays OR weekends
	(1, 'Frankensteins', 'Monster', 1)
	,(2, 'Morticia', 'Addams', 1)
	-- Paediatric13 ward inserts won't pass on weekdays OR weekends due to numbers
	,(3, 'Pippi', 'Longstocking', 2)
	,(4, 'Snotty', 'Betty', 2)
	-- Paediatric15 inserts will only pass on weekends (change system clock?)
	-- it worked for me on Saturday
	,(5, 'Harry', 'Du Bois', 3)
	,(6, 'Kim', 'Kitsuragi', 3)
	,(7, 'Cuno', null, 3)
	,(8, 'Cunoesse', null, 3)
	,(9, 'Dolores', 'Dei', 3)
	-- the other Paed doesn't need its own patient data
	set identity_insert dbo.PatientTBL off;

	-- according to class, PatientID in a care team should always be null when this query is run
	-- no point testing with any other cols
	insert into dbo.CareTeamTBL(CareTeamID)
	values
	-- 2 nurses 1 doctor
	(1)
	-- 2 nurses 2 doctors
	,(2)
	-- 2 nurses 1 doctor (with bad speciality)
	,(3)
	-- 0 nurses 1 doctor
	,(4)
	-- 2 nurses 0 doctors
	,(5)
	-- 1 nurse 1 doctor
	,(6)
	-- 1 nurse 1 doctor (but patient is covid positive)
	,(7)

	set identity_insert dbo.NurseTBL on;
	-- no need to test Pae13 because it will always fail on patient insert due to capacity
	insert into dbo.NurseTBL(NurseID, NurseName, NurseSpeciality, NurseWarD, COVID19Vacinated)
	values
	(1, 'Cool Auntie', 'Pae', 4, 1)
	,(2, 'Cooler Auntie', 'Pae', 4, 0)
	,(3, 'Coolest Auntie', 'Pae', 3, 1)
	,(4, 'Most Coolest Auntie', 'Pae', 3, 1)
	-- she's already actively assigned to a team
	,(5, 'Even More Coolest Auntie', 'Pae', null, 0)
	,(6, 'Plague Doctor', 'Dea', 1, 1)
	-- no assignments
	,(7, 'i ran out of ideas', 'Pae', null, 1)
	,(8, 'Typhoid Mary', 'Pae', 4, 0)
	set identity_insert dbo.NurseTBL off;

	insert into dbo.DoctorCareTeamMembersTBL(CareTeamID, MemberID)
	values
	(1, 2)
	, (2, 2)
	, (2, 1)
	, (3, 3)
	, (4, 1)
	, (6, 2)
	, (7, 2)

	-- CurrentMember is there to demo that a nurse is not considered part of that team
	insert into dbo.NurseCareTeamMembersTBL(CareTeamID, MemberID, CurrentMember)
	values
	(1, 1, 1)
	,(1, 2, 1)
	,(1, 8, 0)
	,(2, 1, 1)
	,(2, 6, 1)
	,(3, 8, 1)
	,(3, 5, 1)
	,(4, 6, 0)
	,(5, 5, 1)
	,(5, 6, 1)
	,(6, 1, 1)
	,(7, 3, 1)

end try
begin catch
	rollback transaction
	print('Tests cannot proceed due to a failure in populating test data')
	;throw
end catch

declare @Error int, @Message varchar(200);
begin try
	-- will fail due to age requirements
	exec dbo.ExamMaster 'Test', 'Person', '2000-01-01', 'Positive', 4, 1
end try
begin catch
	select @Error = ERROR_NUMBER()
	select @Message = ERROR_MESSAGE()
	if(@Error = 50007)
	begin
		print(@Message)
		print('Test correctly failed from lacking ward capacity')
	end
end catch

rollback transaction
go;

create proc dbo.ExamTests3
as
begin transaction
-- run this sproc ONLY on empty tables; identity inserts are dangerous in terms of conflicts otherwise
-- apologies for how messy this looks, whoever worked on SQL Server implemented a feature where only
-- one table at a time can have IDENTITY INSERT set to ON

-- this is necessary due to a feature with try-catch blocks in SQL Server...
set XACT_ABORT OFF;

-- populate all test data before proceeding
begin try
	set identity_insert dbo.WarDTBL on;
	insert into dbo.WarDTBL(WardID, WardName, WardCapacity, WardSpeciality)
	values
	(1, 'Mortuary', 5, 'Death')
	,(2, 'Kids <=13', 2, 'Paediatric13')
	,(3, 'Teens <15', 5, 'Paediatric15')
	,(4, 'Teens <18', 5, 'Paediatric')
	set identity_insert dbo.WarDTBL off;

	set identity_insert dbo.DoctorTBL on;
	-- COVID vaccination status doesn't seem to matter for doctors?
	insert into dbo.DoctorTBL(DoctorID, DoctorName, DoctorSpeciality)
	values
	-- the extra characters beside the last 3 exist to prove that the sproc is capable of isolating
	-- just the last three characters
	(1, 'Dr Frankenstein', 'mortDea')
	,(2, 'Dr Doofenshmirtz', 'evilincPae')
	,(3, 'Dr Strangelove', 'irrelevant')
	set identity_insert dbo.DoctorTBL off;

	set identity_insert dbo.PatientTBL on;
	-- other columns are irrelevant (it doesn't matter that a patient has COVID if they're already in the db)
	insert into dbo.PatientTBL(PatientID, PatientFname, PatientLname, PatientWarD)
	values
	-- inserts to the mortuary will pass on weekdays OR weekends
	(1, 'Frankensteins', 'Monster', 1)
	,(2, 'Morticia', 'Addams', 1)
	-- Paediatric13 ward inserts won't pass on weekdays OR weekends due to numbers
	,(3, 'Pippi', 'Longstocking', 2)
	,(4, 'Snotty', 'Betty', 2)
	-- Paediatric15 inserts will only pass on weekends (change system clock?)
	-- it worked for me on Saturday
	,(5, 'Harry', 'Du Bois', 3)
	,(6, 'Kim', 'Kitsuragi', 3)
	,(7, 'Cuno', null, 3)
	,(8, 'Cunoesse', null, 3)
	,(9, 'Dolores', 'Dei', 3)
	-- the other Paed doesn't need its own patient data
	set identity_insert dbo.PatientTBL off;

	-- according to class, PatientID in a care team should always be null when this query is run
	-- no point testing with any other cols
	insert into dbo.CareTeamTBL(CareTeamID)
	values
	-- 2 nurses 1 doctor
	(1)
	-- 2 nurses 2 doctors
	,(2)
	-- 2 nurses 1 doctor (with bad speciality)
	,(3)
	-- 0 nurses 1 doctor
	,(4)
	-- 2 nurses 0 doctors
	,(5)
	-- 1 nurse 1 doctor
	,(6)
	-- 1 nurse 1 doctor (but patient is covid positive)
	,(7)

	set identity_insert dbo.NurseTBL on;
	-- no need to test Pae13 because it will always fail on patient insert due to capacity
	insert into dbo.NurseTBL(NurseID, NurseName, NurseSpeciality, NurseWarD, COVID19Vacinated)
	values
	(1, 'Cool Auntie', 'Pae', 4, 1)
	,(2, 'Cooler Auntie', 'Pae', 4, 0)
	,(3, 'Coolest Auntie', 'Pae', 3, 1)
	,(4, 'Most Coolest Auntie', 'Pae', 3, 1)
	-- she's already actively assigned to a team
	,(5, 'Even More Coolest Auntie', 'Pae', null, 0)
	,(6, 'Plague Doctor', 'Dea', 1, 1)
	-- no assignments
	,(7, 'i ran out of ideas', 'Pae', null, 1)
	,(8, 'Typhoid Mary', 'Pae', 4, 0)
	set identity_insert dbo.NurseTBL off;

	insert into dbo.DoctorCareTeamMembersTBL(CareTeamID, MemberID)
	values
	(1, 2)
	, (2, 2)
	, (2, 1)
	, (3, 3)
	, (4, 1)
	, (6, 2)
	, (7, 2)

	-- CurrentMember is there to demo that a nurse is not considered part of that team
	insert into dbo.NurseCareTeamMembersTBL(CareTeamID, MemberID, CurrentMember)
	values
	(1, 1, 1)
	,(1, 2, 1)
	,(1, 8, 0)
	,(2, 1, 1)
	,(2, 6, 1)
	,(3, 8, 1)
	,(3, 5, 1)
	,(4, 6, 0)
	,(5, 5, 1)
	,(5, 6, 1)
	,(6, 1, 1)
	,(7, 3, 1)

end try
begin catch
	rollback transaction
	print('Tests cannot proceed due to a failure in populating test data')
	;throw
end catch

declare @Error int, @Message varchar(200);
begin try
	-- will succeed in insert but fail due to bad specialties
	exec dbo.ExamMaster 'Test', 'Person', '2000-01-01', 'Positive', 1, 3
end try
begin catch
	select @Error = ERROR_NUMBER()
	select @Message = ERROR_MESSAGE()
	if(@Error = 50006)
	begin
		print(@Message)
		print('Test correctly failed from bad staff specialties')
	end
end catch

rollback transaction
go;

create proc dbo.ExamTests4
as
begin transaction
-- run this sproc ONLY on empty tables; identity inserts are dangerous in terms of conflicts otherwise
-- apologies for how messy this looks, whoever worked on SQL Server implemented a feature where only
-- one table at a time can have IDENTITY INSERT set to ON

-- this is necessary due to a feature with try-catch blocks in SQL Server...
set XACT_ABORT OFF;

-- populate all test data before proceeding
begin try
	set identity_insert dbo.WarDTBL on;
	insert into dbo.WarDTBL(WardID, WardName, WardCapacity, WardSpeciality)
	values
	(1, 'Mortuary', 5, 'Death')
	,(2, 'Kids <=13', 2, 'Paediatric13')
	,(3, 'Teens <15', 5, 'Paediatric15')
	,(4, 'Teens <18', 5, 'Paediatric')
	set identity_insert dbo.WarDTBL off;

	set identity_insert dbo.DoctorTBL on;
	-- COVID vaccination status doesn't seem to matter for doctors?
	insert into dbo.DoctorTBL(DoctorID, DoctorName, DoctorSpeciality)
	values
	-- the extra characters beside the last 3 exist to prove that the sproc is capable of isolating
	-- just the last three characters
	(1, 'Dr Frankenstein', 'mortDea')
	,(2, 'Dr Doofenshmirtz', 'evilincPae')
	,(3, 'Dr Strangelove', 'irrelevant')
	set identity_insert dbo.DoctorTBL off;

	set identity_insert dbo.PatientTBL on;
	-- other columns are irrelevant (it doesn't matter that a patient has COVID if they're already in the db)
	insert into dbo.PatientTBL(PatientID, PatientFname, PatientLname, PatientWarD)
	values
	-- inserts to the mortuary will pass on weekdays OR weekends
	(1, 'Frankensteins', 'Monster', 1)
	,(2, 'Morticia', 'Addams', 1)
	-- Paediatric13 ward inserts won't pass on weekdays OR weekends due to numbers
	,(3, 'Pippi', 'Longstocking', 2)
	,(4, 'Snotty', 'Betty', 2)
	-- Paediatric15 inserts will only pass on weekends (change system clock?)
	-- it worked for me on Saturday
	,(5, 'Harry', 'Du Bois', 3)
	,(6, 'Kim', 'Kitsuragi', 3)
	,(7, 'Cuno', null, 3)
	,(8, 'Cunoesse', null, 3)
	,(9, 'Dolores', 'Dei', 3)
	-- the other Paed doesn't need its own patient data
	set identity_insert dbo.PatientTBL off;

	-- according to class, PatientID in a care team should always be null when this query is run
	-- no point testing with any other cols
	insert into dbo.CareTeamTBL(CareTeamID)
	values
	-- 2 nurses 1 doctor
	(1)
	-- 2 nurses 2 doctors
	,(2)
	-- 2 nurses 1 doctor (with bad speciality)
	,(3)
	-- 0 nurses 1 doctor
	,(4)
	-- 2 nurses 0 doctors
	,(5)
	-- 1 nurse 1 doctor
	,(6)
	-- 1 nurse 1 doctor (but patient is covid positive)
	,(7)

	set identity_insert dbo.NurseTBL on;
	-- no need to test Pae13 because it will always fail on patient insert due to capacity
	insert into dbo.NurseTBL(NurseID, NurseName, NurseSpeciality, NurseWarD, COVID19Vacinated)
	values
	(1, 'Cool Auntie', 'Pae', 4, 1)
	,(2, 'Cooler Auntie', 'Pae', 4, 0)
	,(3, 'Coolest Auntie', 'Pae', 3, 1)
	,(4, 'Most Coolest Auntie', 'Pae', 3, 1)
	-- she's already actively assigned to a team
	,(5, 'Even More Coolest Auntie', 'Pae', null, 0)
	,(6, 'Plague Doctor', 'Dea', 1, 1)
	-- no assignments
	,(7, 'i ran out of ideas', 'Pae', null, 1)
	,(8, 'Typhoid Mary', 'Pae', 4, 0)
	set identity_insert dbo.NurseTBL off;

	insert into dbo.DoctorCareTeamMembersTBL(CareTeamID, MemberID)
	values
	(1, 2)
	, (2, 2)
	, (2, 1)
	, (3, 3)
	, (4, 1)
	, (6, 2)
	, (7, 2)

	-- CurrentMember is there to demo that a nurse is not considered part of that team
	insert into dbo.NurseCareTeamMembersTBL(CareTeamID, MemberID, CurrentMember)
	values
	(1, 1, 1)
	,(1, 2, 1)
	,(1, 8, 0)
	,(2, 1, 1)
	,(2, 6, 1)
	,(3, 8, 1)
	,(3, 5, 1)
	,(4, 6, 0)
	,(5, 5, 1)
	,(5, 6, 1)
	,(6, 1, 1)
	,(7, 3, 1)

end try
begin catch
	rollback transaction
	print('Tests cannot proceed due to a failure in populating test data')
	;throw
end catch

declare @Error int, @Message varchar(200);
begin try
	-- will succeed in insert and care team assignment
	exec dbo.ExamMaster 'Test', 'Person', '2000-01-01', 'Positive', 1, 2
end try
begin catch
	select @Error = ERROR_NUMBER()
	select @Message = ERROR_MESSAGE()
	print(@Message)
end catch

rollback transaction
go;

create proc dbo.ExamTests5
as
begin transaction
-- run this sproc ONLY on empty tables; identity inserts are dangerous in terms of conflicts otherwise
-- apologies for how messy this looks, whoever worked on SQL Server implemented a feature where only
-- one table at a time can have IDENTITY INSERT set to ON

-- this is necessary due to a feature with try-catch blocks in SQL Server...
set XACT_ABORT OFF;

-- populate all test data before proceeding
begin try
	set identity_insert dbo.WarDTBL on;
	insert into dbo.WarDTBL(WardID, WardName, WardCapacity, WardSpeciality)
	values
	(1, 'Mortuary', 5, 'Death')
	,(2, 'Kids <=13', 2, 'Paediatric13')
	,(3, 'Teens <15', 5, 'Paediatric15')
	,(4, 'Teens <18', 5, 'Paediatric')
	set identity_insert dbo.WarDTBL off;

	set identity_insert dbo.DoctorTBL on;
	-- COVID vaccination status doesn't seem to matter for doctors?
	insert into dbo.DoctorTBL(DoctorID, DoctorName, DoctorSpeciality)
	values
	-- the extra characters beside the last 3 exist to prove that the sproc is capable of isolating
	-- just the last three characters
	(1, 'Dr Frankenstein', 'mortDea')
	,(2, 'Dr Doofenshmirtz', 'evilincPae')
	,(3, 'Dr Strangelove', 'irrelevant')
	set identity_insert dbo.DoctorTBL off;

	set identity_insert dbo.PatientTBL on;
	-- other columns are irrelevant (it doesn't matter that a patient has COVID if they're already in the db)
	insert into dbo.PatientTBL(PatientID, PatientFname, PatientLname, PatientWarD)
	values
	-- inserts to the mortuary will pass on weekdays OR weekends
	(1, 'Frankensteins', 'Monster', 1)
	,(2, 'Morticia', 'Addams', 1)
	-- Paediatric13 ward inserts won't pass on weekdays OR weekends due to numbers
	,(3, 'Pippi', 'Longstocking', 2)
	,(4, 'Snotty', 'Betty', 2)
	-- Paediatric15 inserts will only pass on weekends (change system clock?)
	-- it worked for me on Saturday
	,(5, 'Harry', 'Du Bois', 3)
	,(6, 'Kim', 'Kitsuragi', 3)
	,(7, 'Cuno', null, 3)
	,(8, 'Cunoesse', null, 3)
	,(9, 'Dolores', 'Dei', 3)
	-- the other Paed doesn't need its own patient data
	set identity_insert dbo.PatientTBL off;

	-- according to class, PatientID in a care team should always be null when this query is run
	-- no point testing with any other cols
	insert into dbo.CareTeamTBL(CareTeamID)
	values
	-- 2 nurses 1 doctor
	(1)
	-- 2 nurses 2 doctors
	,(2)
	-- 2 nurses 1 doctor (with bad speciality)
	,(3)
	-- 0 nurses 1 doctor
	,(4)
	-- 2 nurses 0 doctors
	,(5)
	-- 1 nurse 1 doctor
	,(6)
	-- 1 nurse 1 doctor (but patient is covid positive)
	,(7)

	set identity_insert dbo.NurseTBL on;
	-- no need to test Pae13 because it will always fail on patient insert due to capacity
	insert into dbo.NurseTBL(NurseID, NurseName, NurseSpeciality, NurseWarD, COVID19Vacinated)
	values
	(1, 'Cool Auntie', 'Pae', 4, 1)
	,(2, 'Cooler Auntie', 'Pae', 4, 0)
	,(3, 'Coolest Auntie', 'Pae', 3, 1)
	,(4, 'Most Coolest Auntie', 'Pae', 3, 1)
	-- she's already actively assigned to a team
	,(5, 'Even More Coolest Auntie', 'Pae', null, 0)
	,(6, 'Plague Doctor', 'Dea', 1, 1)
	-- no assignments
	,(7, 'i ran out of ideas', 'Pae', null, 1)
	,(8, 'Typhoid Mary', 'Pae', 4, 0)
	set identity_insert dbo.NurseTBL off;

	insert into dbo.DoctorCareTeamMembersTBL(CareTeamID, MemberID)
	values
	(1, 2)
	, (2, 2)
	, (2, 1)
	, (3, 3)
	, (4, 1)
	, (6, 2)
	, (7, 2)

	-- CurrentMember is there to demo that a nurse is not considered part of that team
	insert into dbo.NurseCareTeamMembersTBL(CareTeamID, MemberID, CurrentMember)
	values
	(1, 1, 1)
	,(1, 2, 1)
	,(1, 8, 0)
	,(2, 1, 1)
	,(2, 6, 1)
	,(3, 8, 1)
	,(3, 5, 1)
	,(4, 6, 0)
	,(5, 5, 1)
	,(5, 6, 1)
	,(6, 1, 1)
	,(7, 3, 1)

end try
begin catch
	rollback transaction
	print('Tests cannot proceed due to a failure in populating test data')
	;throw
end catch

declare @Error int, @Message varchar(200);
begin try
	-- will succeed in insert and care team assignment (with only one nurse)
	exec dbo.ExamMaster 'Test', 'Person', '2009-01-01', 'Negative', 4, 6
end try
begin catch
	select @Error = ERROR_NUMBER()
	select @Message = ERROR_MESSAGE()
	print(@Message)
end catch

rollback transaction
go;

create proc dbo.ExamTests6
as
begin transaction
-- run this sproc ONLY on empty tables; identity inserts are dangerous in terms of conflicts otherwise
-- apologies for how messy this looks, whoever worked on SQL Server implemented a feature where only
-- one table at a time can have IDENTITY INSERT set to ON

-- this is necessary due to a feature with try-catch blocks in SQL Server...
set XACT_ABORT OFF;

-- populate all test data before proceeding
begin try
	set identity_insert dbo.WarDTBL on;
	insert into dbo.WarDTBL(WardID, WardName, WardCapacity, WardSpeciality)
	values
	(1, 'Mortuary', 5, 'Death')
	,(2, 'Kids <=13', 2, 'Paediatric13')
	,(3, 'Teens <15', 5, 'Paediatric15')
	,(4, 'Teens <18', 5, 'Paediatric')
	set identity_insert dbo.WarDTBL off;

	set identity_insert dbo.DoctorTBL on;
	-- COVID vaccination status doesn't seem to matter for doctors?
	insert into dbo.DoctorTBL(DoctorID, DoctorName, DoctorSpeciality)
	values
	-- the extra characters beside the last 3 exist to prove that the sproc is capable of isolating
	-- just the last three characters
	(1, 'Dr Frankenstein', 'mortDea')
	,(2, 'Dr Doofenshmirtz', 'evilincPae')
	,(3, 'Dr Strangelove', 'irrelevant')
	set identity_insert dbo.DoctorTBL off;

	set identity_insert dbo.PatientTBL on;
	-- other columns are irrelevant (it doesn't matter that a patient has COVID if they're already in the db)
	insert into dbo.PatientTBL(PatientID, PatientFname, PatientLname, PatientWarD)
	values
	-- inserts to the mortuary will pass on weekdays OR weekends
	(1, 'Frankensteins', 'Monster', 1)
	,(2, 'Morticia', 'Addams', 1)
	-- Paediatric13 ward inserts won't pass on weekdays OR weekends due to numbers
	,(3, 'Pippi', 'Longstocking', 2)
	,(4, 'Snotty', 'Betty', 2)
	-- Paediatric15 inserts will only pass on weekends (change system clock?)
	-- it worked for me on Saturday
	,(5, 'Harry', 'Du Bois', 3)
	,(6, 'Kim', 'Kitsuragi', 3)
	,(7, 'Cuno', null, 3)
	,(8, 'Cunoesse', null, 3)
	,(9, 'Dolores', 'Dei', 3)
	-- the other Paed doesn't need its own patient data
	set identity_insert dbo.PatientTBL off;

	-- according to class, PatientID in a care team should always be null when this query is run
	-- no point testing with any other cols
	insert into dbo.CareTeamTBL(CareTeamID)
	values
	-- 2 nurses 1 doctor
	(1)
	-- 2 nurses 2 doctors
	,(2)
	-- 2 nurses 1 doctor (with bad speciality)
	,(3)
	-- 0 nurses 1 doctor
	,(4)
	-- 2 nurses 0 doctors
	,(5)
	-- 1 nurse 1 doctor
	,(6)
	-- 1 nurse 1 doctor (but patient is covid positive)
	,(7)

	set identity_insert dbo.NurseTBL on;
	-- no need to test Pae13 because it will always fail on patient insert due to capacity
	insert into dbo.NurseTBL(NurseID, NurseName, NurseSpeciality, NurseWarD, COVID19Vacinated)
	values
	(1, 'Cool Auntie', 'Pae', 4, 1)
	,(2, 'Cooler Auntie', 'Pae', 4, 0)
	,(3, 'Coolest Auntie', 'Pae', 3, 1)
	,(4, 'Most Coolest Auntie', 'Pae', 3, 1)
	-- she's already actively assigned to a team
	,(5, 'Even More Coolest Auntie', 'Pae', null, 0)
	,(6, 'Plague Doctor', 'Dea', 1, 1)
	-- no assignments
	,(7, 'i ran out of ideas', 'Pae', null, 1)
	,(8, 'Typhoid Mary', 'Pae', 4, 0)
	set identity_insert dbo.NurseTBL off;

	insert into dbo.DoctorCareTeamMembersTBL(CareTeamID, MemberID)
	values
	(1, 2)
	, (2, 2)
	, (2, 1)
	, (3, 3)
	, (4, 1)
	, (6, 2)
	, (7, 2)

	-- CurrentMember is there to demo that a nurse is not considered part of that team
	insert into dbo.NurseCareTeamMembersTBL(CareTeamID, MemberID, CurrentMember)
	values
	(1, 1, 1)
	,(1, 2, 1)
	,(1, 8, 0)
	,(2, 1, 1)
	,(2, 6, 1)
	,(3, 8, 1)
	,(3, 5, 1)
	,(4, 6, 0)
	,(5, 5, 1)
	,(5, 6, 1)
	,(6, 1, 1)
	,(7, 3, 1)

end try
begin catch
	rollback transaction
	print('Tests cannot proceed due to a failure in populating test data')
	;throw
end catch

declare @Error int, @Message varchar(200);
begin try
	-- will succeed in insert and care team assignment only on weekends
	exec dbo.ExamMaster 'Test', 'Person', '2011-01-01', 'Negative', 3, 1
end try
begin catch
	select @Error = ERROR_NUMBER()
	select @Message = ERROR_MESSAGE()
	print(@Message)
end catch

rollback transaction
go;

create proc dbo.ExamTests7
as
begin transaction
-- run this sproc ONLY on empty tables; identity inserts are dangerous in terms of conflicts otherwise
-- apologies for how messy this looks, whoever worked on SQL Server implemented a feature where only
-- one table at a time can have IDENTITY INSERT set to ON

-- this is necessary due to a feature with try-catch blocks in SQL Server...
set XACT_ABORT OFF;

-- populate all test data before proceeding
begin try
	set identity_insert dbo.WarDTBL on;
	insert into dbo.WarDTBL(WardID, WardName, WardCapacity, WardSpeciality)
	values
	(1, 'Mortuary', 5, 'Death')
	,(2, 'Kids <=13', 2, 'Paediatric13')
	,(3, 'Teens <15', 5, 'Paediatric15')
	,(4, 'Teens <18', 5, 'Paediatric')
	set identity_insert dbo.WarDTBL off;

	set identity_insert dbo.DoctorTBL on;
	-- COVID vaccination status doesn't seem to matter for doctors?
	insert into dbo.DoctorTBL(DoctorID, DoctorName, DoctorSpeciality)
	values
	-- the extra characters beside the last 3 exist to prove that the sproc is capable of isolating
	-- just the last three characters
	(1, 'Dr Frankenstein', 'mortDea')
	,(2, 'Dr Doofenshmirtz', 'evilincPae')
	,(3, 'Dr Strangelove', 'irrelevant')
	set identity_insert dbo.DoctorTBL off;

	set identity_insert dbo.PatientTBL on;
	-- other columns are irrelevant (it doesn't matter that a patient has COVID if they're already in the db)
	insert into dbo.PatientTBL(PatientID, PatientFname, PatientLname, PatientWarD)
	values
	-- inserts to the mortuary will pass on weekdays OR weekends
	(1, 'Frankensteins', 'Monster', 1)
	,(2, 'Morticia', 'Addams', 1)
	-- Paediatric13 ward inserts won't pass on weekdays OR weekends due to numbers
	,(3, 'Pippi', 'Longstocking', 2)
	,(4, 'Snotty', 'Betty', 2)
	-- Paediatric15 inserts will only pass on weekends (change system clock?)
	-- it worked for me on Saturday
	,(5, 'Harry', 'Du Bois', 3)
	,(6, 'Kim', 'Kitsuragi', 3)
	,(7, 'Cuno', null, 3)
	,(8, 'Cunoesse', null, 3)
	,(9, 'Dolores', 'Dei', 3)
	-- the other Paed doesn't need its own patient data
	set identity_insert dbo.PatientTBL off;

	-- according to class, PatientID in a care team should always be null when this query is run
	-- no point testing with any other cols
	insert into dbo.CareTeamTBL(CareTeamID)
	values
	-- 2 nurses 1 doctor
	(1)
	-- 2 nurses 2 doctors
	,(2)
	-- 2 nurses 1 doctor (with bad speciality)
	,(3)
	-- 0 nurses 1 doctor
	,(4)
	-- 2 nurses 0 doctors
	,(5)
	-- 1 nurse 1 doctor
	,(6)
	-- 1 nurse 1 doctor (but patient is covid positive)
	,(7)

	set identity_insert dbo.NurseTBL on;
	-- no need to test Pae13 because it will always fail on patient insert due to capacity
	insert into dbo.NurseTBL(NurseID, NurseName, NurseSpeciality, NurseWarD, COVID19Vacinated)
	values
	(1, 'Cool Auntie', 'Pae', 4, 1)
	,(2, 'Cooler Auntie', 'Pae', 4, 0)
	,(3, 'Coolest Auntie', 'Pae', 3, 1)
	,(4, 'Most Coolest Auntie', 'Pae', 3, 1)
	-- she's already actively assigned to a team
	,(5, 'Even More Coolest Auntie', 'Pae', null, 0)
	,(6, 'Plague Doctor', 'Dea', 1, 1)
	-- no assignments
	,(7, 'i ran out of ideas', 'Pae', null, 1)
	,(8, 'Typhoid Mary', 'Pae', 4, 0)
	set identity_insert dbo.NurseTBL off;

	insert into dbo.DoctorCareTeamMembersTBL(CareTeamID, MemberID)
	values
	(1, 2)
	, (2, 2)
	, (2, 1)
	, (3, 3)
	, (4, 1)
	, (6, 2)
	, (7, 2)

	-- CurrentMember is there to demo that a nurse is not considered part of that team
	insert into dbo.NurseCareTeamMembersTBL(CareTeamID, MemberID, CurrentMember)
	values
	(1, 1, 1)
	,(1, 2, 1)
	,(1, 8, 0)
	,(2, 1, 1)
	,(2, 6, 1)
	,(3, 8, 1)
	,(3, 5, 1)
	,(4, 6, 0)
	,(5, 5, 1)
	,(5, 6, 1)
	,(6, 1, 1)
	,(7, 3, 1)

end try
begin catch
	rollback transaction
	print('Tests cannot proceed due to a failure in populating test data')
	;throw
end catch

declare @Error int, @Message varchar(200);
begin try
	-- will fail because of lacking staff
	exec dbo.ExamMaster 'Test', 'Person', '2000-01-01', 'Negative', 1, 4
end try
begin catch
	select @Error = ERROR_NUMBER()
	select @Message = ERROR_MESSAGE()
	if(@Error = 50006)
	begin
		print(@Message)
		print('Test successfully failed to lack of staff')
	end

end catch

rollback transaction
go;