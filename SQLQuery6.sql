use S00233718
go
SELECT a.FirstName, a.LastName
FROM oct.CustomerTBL as a
WHERE a.CreditLimit >=
(
 SELECT avg(CreditLimit)
 from oct.CustomerTBL
 WHERE AddressLine1 like a.AddressLine1
)