create proc CheckProduct
@ECustomerId int
, @EProductId int
, @EProductQuantity smallint
as
declare @ICreditLimit money
, @IProductUnitPrice money

select @ICreditLimit = CreditLimit
from oct.CustomerTBL
where CustomerID = @ECustomerId

select @IProductUnitPrice = UnitPrice
from dbo.ProductTBL
where ProductID = @EProductId

if @ICreditLimit < @EProductQuantity * @IProductUnitPrice
	begin
		print N'You do not have enough credit for the purchase'
		return
	end

print N'You have enough credit for the purchase'