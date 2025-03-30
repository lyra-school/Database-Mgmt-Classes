use S00233718
go
create proc dbo.ExamMaster
@EPatientFname varchar(35)
, @EPatientLname varchar(35)
, @EPatientDOB date
, @EPatientCOVIDStatus char(8)
, @EWardID int
, @ECareTeamID int
as
begin transaction
	-- data being read from physical tables
	declare @IWardCapacity tinyint, @IWardStatus char(15)
	, @IWardSpecialty char(20)
	, @IPatientsInWard int, @IEligibleNurses EligibleNurses
	, @IDoctorsCareTeam DoctorCarers, @INursesCareTeam NurseCarers

	-- this one has to be in its separate declare block because SQL Server reports syntax
	-- errors otherwise for me
	declare @ICurrentDate datetime = GETDATE()

	-- data calculated from processes (but not read from physical data, only existing data in sproc)
	declare @ICurrentDay char(15) = datename(DW, @ICurrentDate), @IDoctorsCount int
	, @INursesCount int, @IFormattedMessage varchar(150)
	, @IFormattedMessage2 varchar(150), @IPatientFullYears int = datediff(year, @EPatientDOB, @ICurrentDate)
	, @ISelectedID int, @IMatchingNurseSpec int, @IMatchingDoctorSpec int

	-- to retrieve ID of an insert later
	declare @INewPatientID int

	-- read necessary data from the requested ward
	select @IWardCapacity = WardCapacity, @IWardStatus = WardStatus
			, @IWardSpecialty = WardSpeciality
	from dbo.WarDTBL
	where WardID = @EWardID

	-- get a count of patients assigned to a ward to be used in comparing capacity
	select @IPatientsInWard = count(*)
	from dbo.PatientTBL
	where PatientWarD = @EWardID

	begin try
		-- read all nurses that could possibly be selected for care team
		insert into @IEligibleNurses(NurseID, NurseSpecialty,NurseWard,COVID19Vaccinated)
		select NurseID, NurseSpeciality, NurseWarD, COVID19Vacinated
		from dbo.NurseTBL as n
		-- calculate the # of assigned care teams to use as a filter for the initial read
		where (NurseWarD is null and (0 = (select count(*)
				from dbo.NurseCareTeamMembersTBL as nc
				where nc.CurrentMember != 0 and n.NurseID = nc.MemberID
		)))
		or (NurseWarD = @EWardID and (3 > (select count(*)
				from dbo.NurseCareTeamMembersTBL as nc
				where nc.CurrentMember != 0 and n.NurseID = nc.MemberID
		)))


		-- get all current nurses in the care team
		insert into @INursesCareTeam(NurseID, NurseSpecialty)
		select n.NurseID, n.NurseSpeciality
		from dbo.NurseTBL as n
		inner join dbo.NurseCareTeamMembersTBL as nc
		on n.NurseID = nc.MemberID
		where nc.CareTeamID = @ECareTeamID
		and nc.CurrentMember != 0

		-- get all current doctors in the care team
		insert into @IDoctorsCareTeam(DoctorID, DoctorSpecialty)
		select d.DoctorID, d.DoctorSpeciality
		from dbo.DoctorTBL as d
		inner join dbo.DoctorCareTeamMembersTBL as dc
		on d.DoctorID = dc.MemberID
		where dc.CareTeamID = @ECareTeamID
		and dc.CurrentMember != 0
	end try
	begin catch
		rollback transaction
		;throw
	end catch

	-- count all current doctors/nurses to simplify a future check
	select @IDoctorsCount = count(*)
	from @IDoctorsCareTeam

	select @INursesCount = count(*)
	from @INursesCareTeam

	-- only ward capacity rules seem to require patient names + specific formatting in the error message
	select @IFormattedMessage = concat('This ward is full – find a different ward for '
	, upper(substring(@EPatientFname, 1, 1)),  lower(substring(@EPatientFname, 2, len(@EPatientFname))), ' '
	, upper(substring(@EPatientLname, 1, 1)),  lower(substring(@EPatientLname, 2, len(@EPatientLname))))

	select @IFormattedMessage2 = concat('This ward is overflowing – find a different ward for '
	, upper(substring(@EPatientFname, 1, 1)),  lower(substring(@EPatientFname, 2, len(@EPatientFname))), ' '
	, upper(substring(@EPatientLname, 1, 1)),  lower(substring(@EPatientLname, 2, len(@EPatientLname))))

	-- check age and ward specialty rule
	-- these should evaluate sequentially due to use of if-else
	if(@IPatientFullYears <= 13)
	begin
		if(@IWardSpecialty not like 'Paediatric13' and @IWardSpecialty not like 'Paeds 13')
		begin
			rollback transaction
			;throw 50003, 'Patients under or equal to the age of 13 must be admitted to a ward with specialty Paediatric13 or Paeds 13', 1
		end
	end
	else if(@IPatientFullYears < 15)
	begin -- the spec says to check Paeds15, not Paeds 15, however I assume it's a typo considering it asks to check for Paeds 13 above
		if(@IWardSpecialty not like 'Paediatric15' and @IWardSpecialty not like 'Paeds 15')
		begin
			rollback transaction
			;throw 50004, 'Patients between ages 13 (exclusive) and 15 (exclusive) must be admitted to a ward with specialty Paediatric15 or Paeds 15', 1
		end
	end
	else if(@IPatientFullYears < 18)
	begin
		if(@IWardSpecialty not like 'Paediatric' and @IWardSpecialty not like 'Paeds')
		begin
			rollback transaction
			;throw 50005, 'Patients between ages 15 (inclusive) and 18 (exclusive) must be admitted to a ward with specialty Paediatric or Paeds', 1
		end
	end
	else -- default to 18+ if other age brackets fail
	begin
		if(@IWardSpecialty like '%Paediatric%' or @IWardSpecialty like '%Paeds%')
		begin
			rollback transaction
			;throw 50007, 'Patients age 18 and over cannot be admitted to any paediatric wards', 1
		end
	end

	-- evaluate capacity rules based on the day of the week
	if (@ICurrentDay like 'Saturday' or @ICurrentDay like 'Sunday')
	begin
		-- calculate whether the increased capacity rule would be breached
		-- terminate sproc if it does
		if((@IPatientsInWard + 1) > @IWardCapacity * 1.2)
		begin
			rollback transaction
			;throw 50002, @IFormattedMessage2, 1
		end
		
		-- the spec doesn't say that there should be a special sproc for this update
		begin try
			update dbo.WarDTBL
			set WardStatus = 'Overflow'
			where WardID = @EWardID
		end try
		begin catch
			rollback transaction
			;throw
		end catch
	end
	else begin
		-- check that the ward isn't at capacity
		if(@IPatientsInWard >= @IWardCapacity)
		begin
			rollback transaction
			;throw 50001, @IFormattedMessage, 1
		end
	end

	begin try
		-- the spec doesn't say that the sproc must return SCOPE_IDENTITY, however
		-- that is the only way to retrieve it (won't work within the master sproc)
		exec dbo.InsertPatient @EPatientFname, @EPatientLname, @EWardID, @EPatientCOVIDStatus, @INewPatientID output
	end try
	begin catch
		rollback transaction
		;throw
	end catch

	-- from now on, we use COMMIT instead of ROLLBACK before throws so that the patient can be
	-- added to the ward regardless of what happens to the care team

	-- in case of adding a new nurse:
	-- the spec doesn't specifiy that this change must be reverted if the specialty
	-- eval fails, so selected nurse doesn't get removed from nurse care team if they're put
	-- in one; including due to any other insertion failures

	-- care team must have 2 nurses and 1 doctor at least
	-- there's no rule for assigning doctors so immediately terminate if doctors are at 0
	-- the rule for assigning nurses is only applicable if there's 1 so terminate if there's 0
	if(@INursesCount = 0 or @IDoctorsCount = 0)
	begin
		commit transaction
		;throw 50006, 'Patient has not been assigned to the care team but has been admitted to the ward - not enough staff', 1
	end

	-- add a nurse ONLY if there's only 1 active nurse (previous read already filters for activity)
	if(@INursesCount = 1)
	begin
		if(@EPatientCOVIDStatus != 'Negative')
		begin
			-- https://stackoverflow.com/questions/580639/how-to-randomly-select-rows-in-sql
			-- if patient is positive or unknown, can only select from nurses without wards
			-- (care team # was already filtered out) and that were covid vaccinated
			select top 1 @ISelectedID = NurseID
			from @IEligibleNurses
			where NurseWard is null and COVID19Vaccinated = 1
			order by NEWID()

			-- above is the only way to get a nurse for a positive patient, so if none gets selected, terminate
			if(@ISelectedID is null)
			begin
				commit transaction
				;throw 50006, 'Patient has not been assigned to the care team but has been admitted to the ward - no nurse found', 1
			end

			begin try
				-- insert selected nurse details into the table type for care team for a later evaluation
				insert into @INursesCareTeam(NurseID, NurseSpecialty)
				select NurseID, NurseSpecialty
				from @IEligibleNurses
				where NurseID = @ISelectedID

				-- insert nurse to the care team
				exec dbo.InsertNurse @ECareTeamID, @ISelectedID, @ICurrentDate
			end try
			begin catch
				commit transaction
				;throw 50006, 'Patient has not been assigned to the care team but has been admitted to the ward - no nurse found', 1
			end catch
		end
		else -- covid-negative patients
		begin
			-- the table type insert already ensures that the # of care teams rule is conformed to
			-- first try to get a random (vaccinated or not) nurse from the ward
			select top 1 @ISelectedID = NurseID
			from @IEligibleNurses
			where NurseWard = @EWardID
			order by NEWID()

			if(@ISelectedID is null)
			begin
				-- if above failed, try from nurses without a ward
				select top 1 @ISelectedID = NurseID
				from @IEligibleNurses
				where NurseWard is null
				order by NEWID()
				
				-- if that fails too, terminate
				if(@ISelectedID is null)
				begin
					commit transaction
					;throw 50006, 'Patient has not been assigned to the care team but has been admitted to the ward - no nurse found', 1
				end
			end

			begin try
				-- insert selected nurse details into the table type for care team for a later evaluation
				insert into @INursesCareTeam(NurseID, NurseSpecialty)
				select NurseID, NurseSpecialty
				from @IEligibleNurses
				where NurseID = @ISelectedID

				-- insert nurse to the care team
				-- the spec doesn't specifiy that this change must be reverted if the specialty
				-- eval fails
				exec dbo.InsertNurse @ECareTeamID, @ISelectedID, @ICurrentDate
			end try
			begin catch
				commit transaction
				;throw 50006, 'Patient has not been assigned to the care team but has been admitted to the ward - error adding nurse to a team', 1
			end catch
		end
	end

	-- count the amount of doctors/nurses with correct specialty
	select @IMatchingDoctorSpec = count(*)
	from @IDoctorsCareTeam
	where LEFT(@IWardSpecialty, 3) like RIGHT(DoctorSpecialty, 3)

	select @IMatchingNurseSpec = count(*)
	from @INursesCareTeam
	where LEFT(@IWardSpecialty, 3) like RIGHT(NurseSpecialty, 3)

	-- there must be at least 1 matching nurse and at least 1 matching doctor, otherwise terminate
	if(@IMatchingDoctorSpec < 1 or @IMatchingNurseSpec < 1)
	begin
		commit transaction
		;throw 50006, 'Patient has not been assigned to the care team but has been admitted to the ward - not enough nurses/doctors with matching specialty', 1
	end

	-- there's no success message associated with this project
	begin try
		exec dbo.InsertToCareTeam @ECareTeamID, @INewPatientID
	end try
	begin catch
		commit transaction
		;throw 50006, 'Patient has not been assigned to the care team but has been admitted to the ward - simple failure to insert', 1
	end catch

commit transaction
