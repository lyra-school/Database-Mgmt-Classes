use S00233718finalJan24
go
create proc jan_ex1
as
select a.PlanetID, a.PlanetName
from dbo.PlanetTBL as a
where a.AtmosphereComposition like '%Nitrogen%' and a.OrbitalPeriod < 12.23