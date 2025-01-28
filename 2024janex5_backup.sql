use S00233718finalJan24
go
create proc jan_ex5
	@PlanetID int,
	@DetectionMethod varchar(255),
	@DateOfDetection date,
	@Description varchar(MAX)
as
BEGIN TRY
	insert into dbo.AlienLifeSignsTBL (PlanetID, DetectionMethod, DateOfDetection, DescriptionOfLifeSigns)
	values (@PlanetID, @DetectionMethod, @DateOfDetection, @Description)
END TRY
BEGIN CATCH
;THROW
END CATCH