use S00233718finalJan24
go
create proc jan_ex7
as
select a.PlanetName, count(*) as NoOfBookings
from dbo.PlanetTBL as a
inner join dbo.BookingForExplorersTBL as b
on a.PlanetID = b.PlanetID
group by a.PlanetName
order by NoOfBookings desc