UPDATE [DrivingSchool16].[dbo].Meeting
SET [Type] = 'Practice'
WHERE DATEDIFF(HOUR, [Begin_date], [End_date]) > 2