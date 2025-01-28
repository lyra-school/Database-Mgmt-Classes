alter proc InsertContribution
	@EContributionAmount money,
	@EDateOfContribution date,
	@ECharityID  int,
	@EFunderID int
as
-- sproc used for inserting values to the ContributionsTBL according to brief
begin try
	insert into Marketing.ContributionsTBL (ContributionAmount, DateOfContribution, CharityID, FunderID)
	values (@EContributionAmount, @EDateOfContribution, @ECharityID, @EFunderID)
end try
begin catch
;throw
end catch