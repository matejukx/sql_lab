IF (object_id('nullEmployee') is not null) DROP VIEW nullEmployee
GO

CREATE VIEW nullEmployee AS
SELECT * 
FROM [hurtownia].[dbo].t_employee 
WHERE PESEL IS NULL AND EmployeeName IS NULL
GO

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

IF (object_id('etlInstructor') is not null) DROP VIEW etlInstructor
GO

CREATE VIEW etlInstructor AS
SELECT
	id_pesel_meetingId.ID AS [StudentID],
	IIF(e.ID IS NULL, (SELECT TOP 1 ID FROM nullEmployee) ,e.ID) AS [InstructorID]
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
		[DrivingSchool16].[dbo].Meeting m
	ON id_pesel_meetingId.FK_Meeting_Id = m.PK_Id AND m.[Type] = 'Practice'
	LEFT JOIN [hurtownia].[dbo].t_employee e
	ON e.PESEL = m.[FK_Employee_PESEL]
	GROUP BY id_pesel_meetingId.ID , e.ID
GO

IF (object_id('etlLecturer') is not null) DROP VIEW etlLecturer
GO

CREATE VIEW etlLecturer AS
SELECT
	id_pesel_meetingId.ID AS [StudentID],
	IIF(e.ID IS NULL, (SELECT TOP 1 ID FROM nullEmployee) ,e.ID) AS [LecturerID]
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
		[DrivingSchool16].[dbo].Meeting mt
	ON id_pesel_meetingId.FK_Meeting_Id = mt.PK_Id AND mt.[Type] = 'Lecture'
	LEFT JOIN [hurtownia].[dbo].t_employee e
	ON e.PESEL = mt.[FK_Employee_PESEL]
	GROUP BY id_pesel_meetingId.ID , e.ID
GO

Declare @StartID int; 
Declare @EndID int;

SELECT 
	@StartID=MIN(MonthID), 
	@EndID=MAX(MonthID)
FROM
	etlCourseParticipationDrivesDone d
	LEFT JOIN etlInstructor i
	ON d.StudentID = i.StudentID
	LEFT JOIN etlLecturer l
	ON d.StudentID = l.StudentID

Declare @CurrentID int = @StartID;
While @CurrentID <= @EndID
	Begin
		SELECT d.StudentID, InstructorID, LecturerID, MonthID, DrivesDone
		FROM
			etlCourseParticipationDrivesDone d
			LEFT JOIN etlInstructor i
			ON d.StudentID = i.StudentID
			LEFT JOIN etlLecturer l
			ON d.StudentID = l.StudentID
		WHERE
			d.MonthID = @CurrentID
		SET @CurrentID = @CurrentID + 1
	End
GO