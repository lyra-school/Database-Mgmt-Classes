use S00233718
go
alter proc MasterRecord
@ECustomerID int, @EProductID int
, @EQuantityOrdered smallint, @EDiscount money
as

declare @IUnitPrice money, @IQuantity smallint
, @ICreditLimit money, @ICurrentDate date = getdate()
, @IOrderID int

select @IUnitPrice = UnitPrice, @IQuantity = Quantity
from dbo.ProductTBL
where ProductID = @EProductID

select @ICreditLimit = CreditLimit
from oct.CustomerTBL
where CustomerID = @ECustomerID

if @IQuantity < @EQuantityOrdered
begin
;throw 50001, 'Out of stock', 1
end

if @ICreditLimit < ((@IUnitPrice - @EDiscount) * @EQuantityOrdered)
begin
;throw 50002, 'Out of credit', 1
end

begin try
exec dbo.InsertOrder @ECustomerID, @ICurrentDate, @OOrderID = @IOrderID output
end try
begin catch
;throw
end catch