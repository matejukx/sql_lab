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
    ON id_pesel_meetingId.FK_Meeting_Id = m.PK_Id AND [Type] = 'Practice' 
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

IF (object_id('etlMonthly') is not null) DROP VIEW etlMonthly
GO

CREATE VIEW etlMonthly AS
SELECT 
    d.StudentID,
    DrivesDone,
    MonthID,
    LecturerID,
    InstructorID
FROM 
    etlCourseParticipationDrivesDone d
    JOIN etlLecturer l ON d.StudentID = l.StudentID
    JOIN etlInstructor i ON d.StudentID = i.StudentID
GO

MERGE [hurtownia].[dbo].t_course_monthly_participation AS T
USING etlMonthly AS S 
ON T.StudentID = S.StudentID
 	AND T.MonthID = S.MonthID
	AND T.InstructorID = S.InstructorID
	AND T.LecturerID = S.LecturerID
WHEN NOT MATCHED BY TARGET
    THEN 
    INSERT (
		StudentID,
		MonthID,
		InstructorID,
		LecturerID,
		DrivesDone)
    VALUES (
		S.StudentID,
		S.MonthID,
		S.InstructorID,
		S.LecturerID,
		S.DrivesDone)
WHEN MATCHED 
	AND (
		T.InstructorID <> S.InstructorID
		OR T.DrivesDone <> S.DrivesDone
	)
    THEN
        UPDATE
        SET 
			T.InstructorID = S.InstructorID,
			T.DrivesDone = S.DrivesDone
;
INSERT INTO [hurtownia].[dbo].t_course_monthly_participation(
	StudentID,
	MonthID,
	InstructorID,
	LecturerID,
	DrivesDone)
SELECT
	StudentID,
	MonthID,
	InstructorID,
	LecturerID,
	DrivesDone
FROM
etlMonthly
EXCEPT
SELECT
	StudentID,
	MonthID,
	InstructorID,
	LecturerID,
	DrivesDone
FROM [hurtownia].[dbo].t_course_monthly_participation

DROP VIEW etlCourseParticipationDrivesDone
DROP VIEW nullEmployee
DROP VIEW etlLecturer
DROP VIEW etlInstructor
DROP VIEW etlMonthly