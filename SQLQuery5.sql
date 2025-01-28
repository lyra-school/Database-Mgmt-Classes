use S00233718
go
create proc GetCity
as
SELECT a.City, count(distinct a.CustomerID) as customerNo, sum(CreditLimit) as totalCreditLimit, count(*) as noOfOrders
FROM oct.CustomerTBL as a
inner join dbo.OrderTBL as b on
a.CustomerID = b.CustomerID
where year(OrderDate) = year(getdate())
group by a.City
having count(*) > 1