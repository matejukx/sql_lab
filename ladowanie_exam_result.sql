use hurtownia
go

Declare @Proba int;

SELECT @Proba = 1;

While @Proba <= 300
	Begin
	--Add a row into the date dimension table for this date
		INSERT INTO [hurtownia].[dbo].t_exam_result(IsPassed, TakeNumber)
		Values ( 
		  0, @Proba
		);  
        INSERT INTO [hurtownia].[dbo].t_exam_result(IsPassed, TakeNumber)
		Values ( 
		  1, @Proba
		);  
		-- Add a day and loop again
		Set @Proba = @Proba + 1;
	End
go