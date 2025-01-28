use S00233718finalSummer24
go
alter proc InsertBooking
	@EExplorerID int,
	@EPlanetID int,
	@EBookingDate date,
	@ETourDate date,
	@ESpecialRequests varchar(500),
	@EStatus varchar(255),
	@ONewBookingID int output
as
begin try
	insert into dbo.BookingForExplorersTBL (ExplorerID, PlanetID, BookingDate, TourDates, SpecialRequests, Status)
	values (@EExplorerID, @EPlanetID, @EBookingDate, @ETourDate, @ESpecialRequests, @EStatus)

	-- get the new booking ID
	select @ONewBookingID = SCOPE_IDENTITY()
	from dbo.BookingForExplorersTBL
end try
begin catch
;throw
end catch
