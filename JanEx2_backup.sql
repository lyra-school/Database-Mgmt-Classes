use S00233718SQLExam
go
create proc JanEx2
	@InputID smallint
as
select a.VolunteerID, a.FirstName, a.LastName
from dbo.VolunteerTBL as a
where @InputID = a.VolunteerID