use S00233718
go

CREATE TYPE [dbo].[details] AS TABLE(
	[ProductID] [int] NULL,
	[OrderQty] [smallint] NULL,
	[Discount] [money] NULL
)