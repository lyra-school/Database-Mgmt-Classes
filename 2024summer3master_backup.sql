use S00233718finalSummer24
go
alter proc InsertBookingMaster
	@EExplorerID int,
	@EPlanetID int,
	@EBookingDate date,
	@ETourDate date,
	@ESpecialRequests varchar(500),
	@EStatus varchar(255)
as
-- declare all variables that will be used
declare @IPlanetType varchar(255),
		@IPlanetTypeFound int,
		@ISuccessMessage varchar(255),
		@INewBookingID int = 0

-- read data
select @IPlanetType = PlanetType
from dbo.PlanetTBL
where PlanetID = @EPlanetID

-- the name of the AllowedPlanetTypes column implies that it could be a comma-separated list instead of a single planet type
select @IPlanetTypeFound = count(*)
from dbo.ExplorerTBL
where ExplorerID = @EExplorerID and
AllowedPlanetTypes like '%' + @IPlanetType + '%'

-- evaluate conformance to business rule
if @IPlanetTypeFound = 0
	begin
	;throw 50001, 'The planet type does not match the allowed planet type, the insert is rejected', 1
	end

-- try to insert; throw error if failed
begin try
	exec InsertBooking @EExplorerID, @EPlanetID, @EBookingDate, @ETourDate, @ESpecialRequests, @EStatus, @ONewBookingID = @INewBookingID out

	-- send success message if insert went through + the new ID
	set @ISuccessMessage = concat('Insert has been accepted. ID of the new booking: ',@INewBookingID)
	print(@ISuccessMessage)
end try
begin catch
;throw 50002, 'The insert has failed', 1
end catch