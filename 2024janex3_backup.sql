use S00233718finalJan24
go
create proc jan_ex3
as
select count(*)
from dbo.ExplorerTBL as a
where a.HomePlanet like 'Earth' and (a.Skills like 'Engineering' or a.Skills like 'Astrobiology')