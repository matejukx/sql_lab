use hurtownia
go

-- Fill DimDates Lookup Table
-- Step a: Declare variables use in processing
Declare @StartDate date; 
Declare @EndDate date;
Declare @CurrentSeason varchar(6);

-- Step b:  Fill the variable with values for the range of years needed
SELECT @StartDate = '2013-01-01', @EndDate = '2025-12-31';

-- Step c: Insert NULL date
Insert Into [dbo].t_date
		( DateYear, DateMonth, DateDay, Season )
		Values ( NULL, NULL, NULL, NULL);

-- Step d:  Use a while loop to add dates to the table
Declare @DateInProcess datetime = @StartDate;

While @DateInProcess <= @EndDate
	Begin

		SET @CurrentSeason = CASE 
				WHEN DATEPART(month, @DateInProcess) IN (3) AND DATEPART(day, @DateInProcess)>=20 THEN 'wiosna'
				WHEN DATEPART(month, @DateInProcess) IN (4, 5) THEN 'wiosna'
				WHEN DATEPART(month, @DateInProcess) IN (6) AND DATEPART(day, @DateInProcess)<21 THEN 'wiosna'
				WHEN DATEPART(month, @DateInProcess) IN (6) AND DATEPART(day, @DateInProcess)>=21 THEN 'lato'
				WHEN DATEPART(month, @DateInProcess) IN (7, 8) THEN 'lato'
				WHEN DATEPART(month, @DateInProcess) IN (9) AND DATEPART(day, @DateInProcess)<23 THEN 'lato'
				WHEN DATEPART(month, @DateInProcess) IN (9) AND DATEPART(day, @DateInProcess)>=21 THEN 'jesien'
				WHEN DATEPART(month, @DateInProcess) IN (10, 11) THEN 'jesien'
				WHEN DATEPART(month, @DateInProcess) IN (12) AND DATEPART(day, @DateInProcess)<21 THEN 'jesien'
				WHEN DATEPART(month, @DateInProcess) IN (12) AND DATEPART(day, @DateInProcess)>=21 THEN 'zima'
				WHEN DATEPART(month, @DateInProcess) IN (3) AND DATEPART(day, @DateInProcess)<20 THEN 'zima'
				ELSE 'zima'
			END 
		--Add a row into the date dimension table for this date
		Insert Into [dbo].t_date
		( DateYear, DateMonth, DateDay, Season )
		Values ( 
		    Cast( Year(@DateInProcess) as varchar(4)) -- year
		  , Cast( Month(@DateInProcess) as int) -- month
		  , Cast( DATEPART(day, @DateInProcess) as int) -- day of month
		  , @CurrentSeason
		);

		-- Add a day and loop again
		Set @DateInProcess = DateAdd(d, 1, @DateInProcess);
	End

	-- Step e:  Use a while loop to add month-year dates to the table
Set @DateInProcess = @StartDate;

While @DateInProcess <= @EndDate
	Begin

		SET @CurrentSeason = CASE 
				WHEN DATEPART(month, @DateInProcess) IN (3) AND DATEPART(day, @DateInProcess)>=20 THEN 'wiosna'
				WHEN DATEPART(month, @DateInProcess) IN (4, 5) THEN 'wiosna'
				WHEN DATEPART(month, @DateInProcess) IN (6) AND DATEPART(day, @DateInProcess)<21 THEN 'wiosna'
				WHEN DATEPART(month, @DateInProcess) IN (6) AND DATEPART(day, @DateInProcess)>=21 THEN 'lato'
				WHEN DATEPART(month, @DateInProcess) IN (7, 8) THEN 'lato'
				WHEN DATEPART(month, @DateInProcess) IN (9) AND DATEPART(day, @DateInProcess)<23 THEN 'lato'
				WHEN DATEPART(month, @DateInProcess) IN (9) AND DATEPART(day, @DateInProcess)>=21 THEN 'jesien'
				WHEN DATEPART(month, @DateInProcess) IN (10, 11) THEN 'jesien'
				WHEN DATEPART(month, @DateInProcess) IN (12) AND DATEPART(day, @DateInProcess)<21 THEN 'jesien'
				WHEN DATEPART(month, @DateInProcess) IN (12) AND DATEPART(day, @DateInProcess)>=21 THEN 'zima'
				WHEN DATEPART(month, @DateInProcess) IN (3) AND DATEPART(day, @DateInProcess)<20 THEN 'zima'
				ELSE 'zima'
			END 
		--Add a row into the date dimension table for this month-year date
		Insert Into [dbo].t_date
		( DateYear, DateMonth, DateDay, Season )
		Values ( 
		    Cast( Year(@DateInProcess) as varchar(4)) -- year
		  , Cast( Month(@DateInProcess) as int) -- month
		  , NULL
		  , @CurrentSeason
		);

		-- Add a month and loop again
		Set @DateInProcess = DateAdd(m, 1, @DateInProcess);
	End
Go
