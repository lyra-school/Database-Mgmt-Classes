alter proc ContributionMaster
	@EVolunteerID smallint,
	@ECharityID int,
	@EContributionAmount money,
	@EContributionDate date
as
-- declare internal variables
declare @IVolunteersFunderID int, @ICharityCurrentTaxNo char(10),
@ITaxNoDateOfIssue date, @IFunderCharityRowFound tinyint

-- read relevant data into the appropriate variable
-- Business Rule 1
select @IVolunteersFunderID = VolunteersFunderID 
from dbo.VolunteerTBL
where VolunteerID = @EVolunteerID

select @ICharityCurrentTaxNo = CharityCurrentTaxNo, @ITaxNoDateOfIssue = TaxNoDateOfIssue
from Marketing.CharityTBL
where CharityID = @ECharityID

-- this counts rows in the table based on a certain CharityID and FunderID combo
select @IFunderCharityRowFound = count(*)
from dbo.FunderCharityTBL
where FunderID = @IVolunteersFunderID and CharityID = @ECharityID

-- ...and if the count is zero, it implies that a funder does not support a particular charity (breaches Business Rule 2, so the program terminates)
if @IFunderCharityRowFound = 0
	begin
	;throw 50001, 'Your funder does not support this charity. Contribution is refused.', 1
	end

-- checks part 1 of Business Rule 3 (that a charity tax number exists) and part 2 (the year of tax number issue must be the same as the current year)
-- if either one of these is not the case, Business Rule 3 is breached and the program terminates
if @ICharityCurrentTaxNo is null or datediff(year, @ITaxNoDateOfIssue, getdate()) <> 0
	begin
	;throw 50002, 'Tax number is out of date. Contribution is refused.', 1
	end

-- try to do the inserts and update -- catch an error if something goes wrong in the sub-sprocs
begin try
-- Business Rule 5; two different values are passed to the insert subsproc depending on whether a non-null date was passed into the master sproc
-- if it's null, the sproc instead uses the current date
-- adheres to Business Rule 1, as the funder ID is used for insertion
if @EContributionDate is null
	begin
	-- getdate() must be declared as another variable before being passed in; cannot pass functions into sprocs unless as variables
	-- feature
	declare @IDate date
	set @IDate = GETDATE()
	exec InsertContribution @EContributionAmount, @IDate, @ECharityID, @IVolunteersFunderID
	end
else
	-- do not use system date if a value for date is passed into the master sproc
	begin
	exec InsertContribution @EContributionAmount, @EContributionDate, @ECharityID, @IVolunteersFunderID
	end

-- Business Rule 4; same sproc call across both scenarios
exec UpdateTotalContribution @IVolunteersFunderID, @ECharityID, @EContributionAmount
end try
begin catch
;throw
end catch

-- success message
raiserror('Contribution successfully added', 10, 1)