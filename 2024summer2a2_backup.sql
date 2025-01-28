USE [S00233718finalSummer24]
GO

alter proc VA2AProc
as
/*
This view cannot be made into an indexed view because:
1. it's missing a COUNT_BIG() column while there is a GROUP BY
2. it's in a different schema than the underlying tables
*/

/*

SQL server generated a faulty view script so it's commented

ALTER VIEW [S00233718].[SumVA2A]
WITH SCHEMABINDING 
AS
SELECT        TOP (100) PERCENT dbo.ExplorerTBL.ExplorerID, dbo.ExplorerTBL.ExplorerName, COUNT(dbo.BookingForExplorersTBL.BookingID) AS NoOfBookings
FROM            dbo.ExplorerTBL LEFT OUTER JOIN
                         dbo.BookingForExplorersTBL ON dbo.ExplorerTBL.ExplorerID = dbo.BookingForExplorersTBL.ExplorerID
GROUP BY dbo.ExplorerTBL.ExplorerID, dbo.ExplorerTBL.ExplorerName
GO
*/


