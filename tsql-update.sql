alter proc UpdateTotalContribution
	@EFunderID int,
	@ECharityID int,
	@EContributionAmount money
as
-- sproc used for updating a specific row in the FunderCharityTBL according to brief
begin try
	update dbo.FunderCharityTBL
	set TotalContributions = TotalContributions + @EContributionAmount
	where FunderID = @EFunderID and CharityID = @ECharityID
end try
begin catch
;throw
end catch