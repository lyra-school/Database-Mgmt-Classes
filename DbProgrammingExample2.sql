use S00233718
go
alter proc dbo.InsertOrder
@ECustomerID int, @ECurrentDate date, @OOrderID int output
as
begin try
insert into dbo.OrderTBL
(CustomerID, OrderDate)
values
(@ECustomerID, @ECurrentDate)
select @OOrderID = SCOPE_IDENTITY()
end try
begin catch
;throw
end catch