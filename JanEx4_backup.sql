use S00233718SQLExam
go
create proc JanEx4
as
select a.FunderID, a.FunderName, count(b.VolunteersFunderID) as VolunteerCount
from Patrons.FunderTBL as a
inner join dbo.VolunteerTBL as b on
a.FunderID = b.VolunteersFunderID
group by a.FunderID, a.FunderName