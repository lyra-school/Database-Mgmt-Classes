use S00233718SQLExam
go
create proc JanEx5
as
select count(distinct a.FunderID) as NumberOfPatrons
from Patrons.FunderTBL as a
left join Marketing.ContributionsTBL as b on
a.FunderID = b.FunderID
where b.FunderID is not null and a.EmailPromotion like 'Weekly Newsletter'