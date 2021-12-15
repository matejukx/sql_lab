use hurtownia
go

Declare @Proba int;

SELECT @Proba = 1;

While @Proba <= 300
	Begin
	--Add a row into the date dimension table for this date
		INSERT INTO [hurtownia].[dbo].t_exam_result(IsPassed, TakeNumber)
		Values ( 
		  0, CONCAT('Proba ',CAST(@Proba AS VARCHAR))
		);  
        INSERT INTO [hurtownia].[dbo].t_exam_result(IsPassed, TakeNumber)
		Values ( 
		  1, CONCAT('Proba ',CAST(@Proba AS VARCHAR))
		);  
		-- Add a day and loop again
		Set @Proba = @Proba + 1;
	End
go