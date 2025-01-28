use S00233718finalSummer24
go
alter proc SumIDX1d
as
/*
Assuming that IX_Orbitalperiod statistics are ignored and the question is just on Table 1

1. Part of whether these statistics are reliable or not depends on whether the optimizer considers April 10, 2024
(date of last update) to not be recent enough
Otherwise, while it has a 30% sample rate and 200 steps, the table is large enough that the amount of rows affected may be well representative 
of the underlying data, meaning that it is reliable

2. 30%

3. 200

4. Yes, as the density is very low (0.00154%)
*/
dbcc show_statistics("dbo.PlanetTBL", IX_Orbitalperiod)