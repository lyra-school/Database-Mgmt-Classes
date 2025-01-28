use S00233718SQLExam
go
alter proc JanEx7
as
select a.CharityID, a.CharityName
from Marketing.CharityTBL as a
where datediff(YEAR, a.TaxNoDateOfIssue, getdate()) >= 1