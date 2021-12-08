use hurtownia
go

-- Fill DimDates Lookup Table
-- Step a: Declare variables use in processing
Declare @StartDate date; 
Declare @EndDate date;

-- Step b:  Fill the variable with values for the range of years needed
SELECT @StartDate = '2013-01-01', @EndDate = '2025-12-31';

-- Step c:  Use a while loop to add dates to the table
Declare @DateInProcess datetime = @StartDate;

While @DateInProcess <= @EndDate
	Begin
	--Add a row into the date dimension table for this date
		Insert Into [dbo].t_date
		( DateYear, DateMonth, DateDay, Season )
		Values ( 
		    Cast( Year(@DateInProcess) as varchar(4)) -- year
		  , Cast( Month(@DateInProcess) as int) -- month
		  , Cast( DATEPART(day, @DateInProcess) as int) -- day of month
		  , CASE 
				WHEN DATEPART(month, @DateInProcess) IN (3) AND DATEPART(day, @DateInProcess)>=20 THEN 'wiosna'
				WHEN DATEPART(month, @DateInProcess) IN (4, 5) THEN 'wiosna'
				WHEN DATEPART(month, @DateInProcess) IN (6) AND DATEPART(day, @DateInProcess)<21 THEN 'wiosna'
				WHEN DATEPART(month, @DateInProcess) IN (6) AND DATEPART(day, @DateInProcess)>=21 THEN 'lato'
				WHEN DATEPART(month, @DateInProcess) IN (7, 8) THEN 'lato'
				WHEN DATEPART(month, @DateInProcess) IN (9) AND DATEPART(day, @DateInProcess)<23 THEN 'lato'
				WHEN DATEPART(month, @DateInProcess) IN (9) AND DATEPART(day, @DateInProcess)>=21 THEN 'jesień'
				WHEN DATEPART(month, @DateInProcess) IN (10, 11) THEN 'jesień'
				WHEN DATEPART(month, @DateInProcess) IN (12) AND DATEPART(day, @DateInProcess)<21 THEN 'jesień'
				WHEN DATEPART(month, @DateInProcess) IN (12) AND DATEPART(day, @DateInProcess)>=21 THEN 'zima'
				WHEN DATEPART(month, @DateInProcess) IN (3) AND DATEPART(day, @DateInProcess)<20 THEN 'zima'
				ELSE 'zima'
			END -- season
		);  
		-- Add a day and loop again
		Set @DateInProcess = DateAdd(d, 1, @DateInProcess);
	End
go
