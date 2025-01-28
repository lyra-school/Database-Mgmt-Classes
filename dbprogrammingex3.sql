use S00233718
go
create proc DeleteCustomer
@ECustomerID int
as
--internal vars
declare @ICreditLimit money
--read operations = tables into internal vars
select @ICreditLimit = CreditLimit
from oct.CustomerTBL
where CustomerID = @ECustomerID
--get orders for customer that are over 2 years old