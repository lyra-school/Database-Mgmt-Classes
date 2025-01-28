use S00233718finalJan24
go
create proc jan_ex2
	@InputID int
as
select a.ContactInfo
from dbo.ExplorerTBL as a
inner join dbo.BookingForExplorersTBL as b
on a.ExplorerID = b.ExplorerID
where @InputID = b.PlanetID