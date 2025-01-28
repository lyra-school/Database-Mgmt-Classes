use S00233718SQLExam
go
create proc JanEX8
as
-- I'm not sure that I understood the question
select distinct a.CharityID, a.CharityName, b.FunderID, b.ContributionAmount
from Marketing.CharityTBL as a
inner join Marketing.ContributionsTBL as b on
a.CharityID = b.CharityID
where ContributionAmount = 
	(
	select max(c.ContributionAmount)
	from Marketing.ContributionsTBL as c
	group by c.FunderID
	having c.FunderID like b.FunderID
	)