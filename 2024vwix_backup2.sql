alter proc Q1C
as
/*
Average length of the Charity Name column = 17.6 (bytes)
The average length shows both the average size that each value in the given column occupies on the disk,
which can sometimes correlate with index performance should it be placed on this column
(i.e. high average length = slower index)
The optimizer will ignore the index as it's a small table (20 rows) which therefore makes it more efficient
to do a full table scan instead.
*/
dbcc show_statistics ("dbo.CharityTBL", CharithyNameStats)