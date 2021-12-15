/*Declare @StartDate date; 
Declare @EndDate date;

SELECT @StartDate = '2013-01-01', @EndDate = '2025-12-31';

Declare @DateInProcess datetime = @StartDate;

While @DateInProcess <= @EndDate
	Begin
		SELECT student.StudentID, InstructorID, LecturerID, DrivesDone
		FROM 
		(
			SELECT
				id_pesel_meetingId.ID AS [StudentID],
				COUNT(m.PK_Id) AS [DrivesDone]
			FROM
			(
				SELECT ID, PESEL, FK_Meeting_Id FROM 
				(
					SELECT PK_PESEL
					FROM [DrivingSchool16].[dbo].Student
				) s
				JOIN 
				(
					SELECT ID, PESEL
					FROM [hurtownia].[dbo].t_student 
				) ts
				ON s.PK_PESEL = ts.PESEL
				JOIN 
				(
					SELECT *
					FROM [DrivingSchool16].[dbo].Participation
				) p
				ON s.PK_PESEL = p.FK_Student_PESEL
				GROUP BY ts.ID, ts.PESEL, p.FK_Meeting_Id
			) id_pesel_meetingId
			JOIN
			(
				SELECT PK_Id, [Type], Begin_date, End_date
				FROM [DrivingSchool16].[dbo].Meeting
			) m
			ON id_pesel_meetingId.FK_Meeting_Id = m.PK_Id 
				AND [Type] = 'Lecture' /* 'Practice' */
				AND DATEPART(MONTH, @DateInProcess) = DATEPART(MONTH, m.Begin_date)
				AND DATEPART(YEAR, @DateInProcess) = DATEPART(YEAR, m.Begin_date)
			GROUP BY id_pesel_meetingId.ID
		) student
		LEFT JOIN 
		(
			SELECT
				ts.ID AS [StudentID],
				e.ID AS [InstructorID]
			FROM
				[DrivingSchool16].[dbo].Student s
				JOIN [hurtownia].[dbo].t_student ts
				ON s.PK_PESEL = ts.PESEL
				JOIN [DrivingSchool16].[dbo].Participation p
				ON s.PK_PESEL = p.FK_Student_PESEL
				JOIN [DrivingSchool16].[dbo].Meeting m
				ON p.FK_Meeting_Id = m.PK_Id 
					AND m.Type = 'Practice'
					AND DATEPART(MONTH, @DateInProcess) = DATEPART(MONTH, m.Begin_date)
					AND DATEPART(YEAR, @DateInProcess) = DATEPART(YEAR, m.Begin_date)
				JOIN [hurtownia].[dbo].t_employee e
				ON m.FK_Employee_PESEL = e.PESEL
		) instructor
		ON student.StudentID = instructor.StudentID
		LEFT JOIN
		(
			SELECT
				ts.ID AS [StudentID],
				e.ID AS [LecturerID]
			FROM
				[DrivingSchool16].[dbo].Student s
				JOIN [hurtownia].[dbo].t_student ts
				ON s.PK_PESEL = ts.PESEL
				JOIN [DrivingSchool16].[dbo].Participation p
				ON s.PK_PESEL = p.FK_Student_PESEL
				JOIN [DrivingSchool16].[dbo].Meeting m
				ON p.FK_Meeting_Id = m.PK_Id 
					AND m.Type = 'Lecture'
					AND DATEPART(MONTH, @DateInProcess) = DATEPART(MONTH, m.Begin_date)
					AND DATEPART(YEAR, @DateInProcess) = DATEPART(YEAR, m.Begin_date)
				JOIN [hurtownia].[dbo].t_employee e
				ON m.FK_Employee_PESEL = e.PESEL
		) lecturer
		ON student.StudentID = lecturer.LecturerID
		

		DECLARE @MonthId int
		SELECT TOP 1 
			@MonthId = ID
		FROM [hurtownia].[dbo].t_date
		WHERE
			DateYear = DATEPART(YEAR, @DateInProcess)
			AND DateMonth = DATEPART(MONTH, @DateInProcess)
			AND DateDay IS NULL	 
		Set @DateInProcess = DateAdd(m, 1, @DateInProcess);
		PRINT @MonthId
	End
	*/

IF (object_id('etlCourseParticipationDrivesDone') is not null) DROP VIEW etlCourseParticipationDrivesDone
GO

CREATE VIEW etlCourseParticipationDrivesDone AS
SELECT
	id_pesel_meetingId.ID AS [StudentID],
	COUNT(m.PK_Id) * 4 AS [DrivesDone],
    d.ID AS MonthID
FROM
	(
		SELECT ID, PESEL, FK_Meeting_Id FROM 
		(
			SELECT PK_PESEL
			FROM [DrivingSchool16].[dbo].Student
		) s
		JOIN 
		(
			SELECT ID, PESEL
			FROM [hurtownia].[dbo].t_student 
		) ts
		ON s.PK_PESEL = ts.PESEL
		JOIN 
		(
			SELECT *
			FROM [DrivingSchool16].[dbo].Participation
		) p
		ON s.PK_PESEL = p.FK_Student_PESEL
		GROUP BY ts.ID, ts.PESEL, p.FK_Meeting_Id
	) id_pesel_meetingId
	JOIN [DrivingSchool16].[dbo].Meeting m 
    ON id_pesel_meetingId.FK_Meeting_Id = m.PK_Id AND [Type] = 'Lecture' /* 'Practice' */
    JOIN [hurtownia].[dbo].t_date d
    ON d.DateYear = DATEPART(year, m.Begin_date) AND d.DateMonth = DATEPART(month, m.Begin_date) AND d.DateDay IS NULL
	GROUP BY id_pesel_meetingId.ID, d.ID
GO

