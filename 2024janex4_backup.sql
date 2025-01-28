use S00233718finalJan24
go
create proc jan_ex4
as
select sum(a.Mass)
from dbo.PlanetTBL as a
where a.PlanetType like 'Ocean World'