use S00233718SQLExam
go
create proc JanEx1
as
select a.CharityID, a.CharityName
from Marketing.CharityTBL as a
where a.CharityCurrentTaxNo is null