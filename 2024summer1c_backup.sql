use S00233718finalSummer24
go
create proc SumIDX1c
as
-- did you mean PlanetTBL? OrbitalPeriod does not exist on PlanetEcosystemTBL
CREATE STATISTICS IX_Orbitalperiod on dbo.PlanetTBL (OrbitalPeriod)
with sample 75 percent