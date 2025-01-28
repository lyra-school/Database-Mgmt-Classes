use S00233718finalJan24
go
create proc jan_ex6
as
select a.PlanetName, a.DiscoveryYear
from dbo.PlanetTBL as a
left join dbo.BookingForExplorersTBL as b
on a.PlanetID = b.PlanetID
where b.PlanetID is null and a.DiscoveryYear > 2000