use S00233718finalSummer24
go

create proc Sum2b
as
select ExplorerID, ExplorerName
from S00233718.SumVA2A
where NoOfBookings = 0