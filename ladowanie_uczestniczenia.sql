IF (object_id('etlCourseParticipationDrivesDone') is not null) DROP VIEW etlCourseParticipationDrivesDone
GO

CREATE VIEW etlCourseParticipationDrivesDone AS
SELECT
	id_pesel_meetingId.ID AS [StudentID],
	COUNT(m.PK_Id) * 4 AS [DrivesDone],
	IIF(COUNT(m.PK_Id) * 4 - 30 > 0, COUNT(m.PK_Id) * 4 - 30, 0) AS [AdditionalDrivesDone]
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
		) ts
		ON s.PK_PESEL = ts.PESEL
		GROUP BY ts.ID, ts.PESEL, Begin_date, End_date
	) student
	JOIN
	(
		SELECT FK_Student_PESEL, [Type], [Date], MAX(Attempt_number) AS [InternalTheoreticalExamTakes]
		FROM [DrivingSchool16].[dbo].Exam
		GROUP BY FK_Student_PESEL, [Type], [Date]
	) te
	ON student.PESEL = te.FK_Student_PESEL AND te.[Type] = 'ExamType.THEORY'
	JOIN
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
	ON s.PK_PESEL = ts.PESEL
	JOIN [hurtownia].[dbo].t_date sd
	ON sd.DateYear = DATEPART(year, s.Begin_date) AND sd.DateMonth = DATEPART(month, s.Begin_date) AND sd.DateDay = DATEPART(day, s.Begin_date)
	LEFT JOIN [hurtownia].[dbo].t_date ed
	ON ed.DateYear = DATEPART(year, s.End_date) AND ed.DateMonth = DATEPART(month, s.End_date) AND ed.DateDay = DATEPART(day, s.End_date)
GO

SELECT
	p.StudentID,
	p.StartDateID,
	p.EndDateID,
	e.InternalTheoreticalExamTakes,
	e.InternalPracticalExamTakes,
	e.TheoreticalCourseTime,
	e.PracticalCourseTime,
	d.DrivesDone,
	d.AdditionalDrivesDone
FROM
(
	etlCourseParticipation p
	JOIN
	etlCourseParticipationExamTakes e
	ON p.StudentID = e.StudentID
	JOIN
	etlCourseParticipationDrivesDone d
	ON p.StudentID = d.StudentID
) ORDER BY p.StudentID

DROP VIEW etlCourseParticipationExamTakes
DROP VIEW etlCourseParticipationDrivesDone
DROP VIEW etlCourseParticipation
