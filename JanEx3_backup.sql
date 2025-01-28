use S00233718SQLExam
go
create proc JanEx3
as
select distinct a.CharityID
from Marketing.ContributionsTBL as a
where a.ContributionAmount <
	(
		select avg(a.ContributionAmount)
		from Marketing.ContributionsTBL as a
	)