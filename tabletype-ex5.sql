create proc [dbo].[MasterOrder2025]
--external variables
@EcustomerID int, @ePONumber int, @EOrderDetails details readonly
as
--Declare internal variables
Declare @IEnoughCreditLimit money, @IEnoughStock smallint
, @ICustomersOrderQty int, @ITotalOrdersQty int, @IDiscount money
, @ICostOfOrder money, @IAverageOrdered float, @IOrderDetails IorderDetails
,@OOrderNo int
-- now perform the necessary reads
-- get the credit limit for the customer

select @IEnoughCreditLimit = CreditLimit
from oct.CustomerTBL
where CustomerID = @EcustomerID

-- is there enough stock for all the items being ordered

select @IEnoughStock= count(*)
from dbo.ProductTBL as p
join @EOrderDetails as ed on
p.ProductID=ed.ProductID
where isnull(p.Quantity,0) < ed.OrderQty

select @ICustomersOrderQty = AVG(QuantityOrdered)
from dbo.OrderDetailsTBL as od
inner join dbo.OrderTBL as o
on od.OrderNo = o.OrderNo
where CustomerID = @EcustomerID and DATEDIFF(MONTH, OrderDate, GETDATE()) = 0

select @ITotalOrdersQty = AVG(QuantityOrdered)
from dbo.OrderDetailsTBL as od
inner join dbo.OrderTBL as o
on od.OrderNo = o.OrderNo
where DATEDIFF(MONTH, OrderDate, GETDATE()) = 0

-- normally you'd check for a divide by zero error
-- but padraig says never to do anything outside of exact requirements
select @IAverageOrdered = @ICustomersOrderQty / @ITotalOrdersQty

-- there's no rule for between 65% and 70% ?
select @IDiscount =
case
	when @IAverageOrdered < 0.5 then 0
	when @IAverageOrdered = 0.5 then 0.05
	when @IAverageOrdered < 0.55 then 0.055
	when @IAverageOrdered < 0.6 then 0.06
	when @IAverageOrdered < 0.65 then 0.065
	else 0.07
end

SELECT @ICostOFOrder = sum(((p.UnitPrice*ed.OrderQty)*(1 - @IDiscount)))
FROM dbo.ProductTBL AS p
join @EOrderDetails AS ED ON
p.ProductID = ed.ProductID


-- what is the cost of the order
--SELECT @ICostOFOrder = sum(((p.UnitPrice*ed.OrderQty)-ed.Discount))
--FROM dbo.ProductTBL AS p
--join @EOrderDetails AS ED ON
--p.ProductID = ed.ProductID
-- now do business logic



if @IEnoughCreditLimit<@ICostOfOrder
begin
;throw 500001, 'CustomerCreditLimit is exceeded order is refused', 1
end

If @IEnoughStock >0
begin
;throw 500001, 'Not enough stock order is refused', 1
End


begin try
exec dbo.InserOrder @eCustomerID, @EPoNumber
, @EOrderNo=@OOrderNo output
end try
begin catch
;throw
end catch


update @EOrderDetails
set Discount = @IDiscount

-- now we need to update the @IOrderDetails variable with all the column data
-- first insert the 2 columns for the external table variable
insert into @IOrderDetails
(ProductID, OrderQty, Discount)
select *
from @EOrderDetails

-- then update the order no column
Update @IOrderDetails
set OrderNo = @OOrderNo

-- finally update the price for each product being ordered
update @IOrderDetails
set Price = unitPrice
from dbo.ProductTBL as p
inner join @IOrderDetails as od on
p.ProductID=od.ProductID

-- phew we got to insert the order details
-- so execute the sub sproc
begin try
exec InsertOrderDetils2025 @IOrderDetails
end try
begin catch
;throw
end catch

raiserror ('yes order has been inserted', 16, 1)
return 0
