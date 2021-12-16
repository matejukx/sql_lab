IF (object_id('nullEmployee') is not null) DROP VIEW nullEmployee
GO

CREATE VIEW nullEmployee AS
SELECT * 
FROM [hurtownia].[dbo].t_employee 
WHERE PESEL IS NULL AND EmployeeName IS NULL
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
			WHERE IsCurrent = 1 
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
	ON e.PESEL = m.[FK_Employee_PESEL] AND e.IsCurrent = 1
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
			WHERE IsCurrent = 1 
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
	ON e.PESEL = mt.[FK_Employee_PESEL] AND e.IsCurrent = 1
	GROUP BY id_pesel_meetingId.ID , e.ID
GO

IF (object_id('etlCourseParticipationDrivesDone') is not null) DROP VIEW etlCourseParticipationDrivesDone
GO

CREATE VIEW etlCourseParticipationDrivesDone AS
SELECT
	id_pesel_meetingId.ID AS [StudentID],
	COUNT(m.PK_Id) * 4 AS [DrivesDone]
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
			WHERE IsCurrent = 1 
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
		SELECT PK_Id, [Type], [FK_Employee_PESEL]
		FROM [DrivingSchool16].[dbo].Meeting
	) m

	ON id_pesel_meetingId.FK_Meeting_Id = m.PK_Id AND [Type] = 'Practice' /* 'Practice' */
	GROUP BY id_pesel_meetingId.ID
GO

IF (object_id('etlCourseParticipationExamTakes') is not null) DROP VIEW etlCourseParticipationExamTakes
GO

CREATE VIEW etlCourseParticipationExamTakes AS
SELECT
	student.ID AS [StudentID],
	te.InternalTheoreticalExamTakes AS [InternalTheoreticalExamTakes],
	pe.InternalPracticalExamTakes AS [InternalPracticalExamTakes],
	DATEDIFF(DAY, student.Begin_date, te.[Date]) AS [TheoreticalCourseTime], /* nie jestem pewien czy liczymy czas do udanego egzaminu czy ostatniego spotkania */
	DATEDIFF(DAY, te.[Date], student.End_date) AS [PracticalCourseTime]
FROM
	(
		SELECT ID, PESEL, Begin_date, End_Date FROM 
		(
			SELECT PK_PESEL, Begin_date, End_date
			FROM [DrivingSchool16].[dbo].Student
		) s
		JOIN 
		(
			SELECT ID, PESEL
			FROM [hurtownia].[dbo].t_student 
			WHERE IsCurrent = 1 
		) ts
		ON s.PK_PESEL = ts.PESEL
		GROUP BY ts.ID, ts.PESEL, Begin_date, End_date
	) student
	LEFT JOIN
	(
		SELECT FK_Student_PESEL, [Type], [Date], MAX(Attempt_number)  AS [InternalTheoreticalExamTakes]
		FROM [DrivingSchool16].[dbo].Exam
		GROUP BY FK_Student_PESEL, [Type], [Date]
	) te
	ON student.PESEL = te.FK_Student_PESEL AND te.[Type] = 'ExamType.THEORY'
	LEFT JOIN
	(
		SELECT FK_Student_PESEL, [Type], [Date], MAX(Attempt_number) AS [InternalPracticalExamTakes]
		FROM [DrivingSchool16].[dbo].Exam
		GROUP BY FK_Student_PESEL, [Type], [Date]
	) pe
	ON student.PESEL = pe.FK_Student_PESEL AND pe.[Type] = 'ExamType.PRACTICE'
GO

IF (object_id('etlCourseParticipation') is not null) DROP VIEW etlCourseParticipation
GO

CREATE VIEW etlCourseParticipation AS
SELECT
	ts.ID AS [StudentID],
	sd.ID AS [StartDateID],
	IIF(
        ed.ID IS NULL, (
        SELECT TOP 1 ID 
        FROM [hurtownia].[dbo].t_date 
        WHERE DateYear IS NULL AND DateMonth IS NULL AND DateDay IS NULL),
        ed.ID) AS [EndDateID]
FROM
    [DrivingSchool16].[dbo].Student s
    JOIN [hurtownia].[dbo].t_student ts
	ON s.PK_PESEL = ts.PESEL AND ts.IsCurrent=1
	JOIN [hurtownia].[dbo].t_date sd
	ON sd.DateYear = DATEPART(year, s.Begin_date) AND sd.DateMonth = DATEPART(month, s.Begin_date) AND sd.DateDay = DATEPART(day, s.Begin_date)
	LEFT JOIN [hurtownia].[dbo].t_date ed
	ON ed.DateYear = DATEPART(year, s.End_date) AND ed.DateMonth = DATEPART(month, s.End_date) AND ed.DateDay = DATEPART(day, s.End_date)
GO

IF (object_id('etlFinalParticipation') is not null) DROP VIEW etlFinalParticipation
GO
CREATE VIEW etlFinalParticipation AS
SELECT
	p.StudentID,
	p.StartDateID,
	p.EndDateID,
	i.InstructorID,
	l.LecturerID,
	e.InternalTheoreticalExamTakes,
	e.InternalPracticalExamTakes,
	e.TheoreticalCourseTime,
	e.PracticalCourseTime,
	d.DrivesDone
FROM
(
	etlCourseParticipation p
	JOIN
	etlCourseParticipationExamTakes e
	ON p.StudentID = e.StudentID
	JOIN
	etlCourseParticipationDrivesDone d
	ON p.StudentID = d.StudentID
	JOIN 
	etlInstructor i 
	ON p.StudentID = i.StudentID
	JOIN 
	etlLecturer l
	ON p.StudentID = l.StudentID

)
GO

MERGE [hurtownia].[dbo].t_course_participation AS T
USING etlFinalParticipation AS S 
ON T.StudentID = S.StudentID
 	AND T.StartDateID = S.StartDateID
	AND T.EndDateID = S.EndDateID
WHEN NOT MATCHED BY TARGET
    THEN 
    INSERT (
		StudentID,
		StartDateID,
		EndDateID,
		InstructorID,
		LecturerID,
		InternalTheoreticalExamTakes,
		InternalPracticalExamTakes,
		TheoreticalCourseTime,
		PracticalCourseTime,
		DrivesDone)
    VALUES (
		S.StudentID,
		S.StartDateID,
		S.EndDateID,
		S.InstructorID,
		S.LecturerID,
		S.InternalTheoreticalExamTakes,
		S.InternalPracticalExamTakes,
		S.TheoreticalCourseTime,
		S.PracticalCourseTime,
		S.DrivesDone)
WHEN MATCHED 
	AND (
		T.InstructorID <> S.InstructorID
		OR T.LecturerID <> S.LecturerID
		OR T.InternalTheoreticalExamTakes <> S.InternalTheoreticalExamTakes
		OR T.InternalPracticalExamTakes <> S.InternalPracticalExamTakes
		OR T.TheoreticalCourseTime <> S.TheoreticalCourseTime
		OR T.PracticalCourseTime <> S.PracticalCourseTime
		OR T.DrivesDone <> S.DrivesDone
	)
    THEN
        UPDATE
        SET 
			T.InstructorID = S.InstructorID,
			T.LecturerID = S.LecturerID,
			T.InternalTheoreticalExamTakes = S.InternalTheoreticalExamTakes,
			T.InternalPracticalExamTakes = S.InternalPracticalExamTakes,
			T.TheoreticalCourseTime = S.TheoreticalCourseTime,
			T.PracticalCourseTime = S.PracticalCourseTime,
			T.DrivesDone = S.DrivesDone
;
INSERT INTO [hurtownia].[dbo].t_course_participation(
	StudentID,
	StartDateID,
	EndDateID,
	InstructorID,
	LecturerID,
	InternalTheoreticalExamTakes,
	InternalPracticalExamTakes,
	TheoreticalCourseTime,
	PracticalCourseTime,
	DrivesDone)
SELECT
	StudentID,
	StartDateID,
	EndDateID,
	InstructorID,
	LecturerID,
	InternalTheoreticalExamTakes,
	InternalPracticalExamTakes,
	TheoreticalCourseTime,
	PracticalCourseTime,
	DrivesDone
FROM
etlFinalParticipation
EXCEPT
SELECT
	StudentID,
	StartDateID,
	EndDateID,
	InstructorID,
	LecturerID,
	InternalTheoreticalExamTakes,
	InternalPracticalExamTakes,
	TheoreticalCourseTime,
	PracticalCourseTime,
	DrivesDone
FROM [hurtownia].[dbo].t_course_participation

DROP VIEW etlCourseParticipationExamTakes
DROP VIEW etlCourseParticipationDrivesDone
DROP VIEW etlCourseParticipation
DROP VIEW etlFinalParticipation
DROP VIEW etlInstructor
DROP VIEW etlLecturer
DROP VIEW nullEmployee