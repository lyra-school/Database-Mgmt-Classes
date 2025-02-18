create proc [dbo].[InsertOrderDetils2025]
@EOrderdetails IOrderDetails readonly
as
begin try
insert into dbo.OrderDetailsTBL
(OrderNo, ProductID, Price, QuantityOrdered, Discount)
select *
from @EOrderdetails
end try
begin catch
;throw
end catch
