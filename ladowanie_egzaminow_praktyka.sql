USE hurtownia
GO

If (object_id('dbo.ResultTemp') is not null) DROP TABLE dbo.ResultTemp;
CREATE TABLE dbo.ResultTemp(pesel varchar(11), exam_type varchar(8), isPassed varchar(10), attempt_number int, exam_date date, city varchar(85))
GO 
BULK INSERT dbo.ResultTemp
    FROM 'C:\Users\Kuba\Downloads\essa\essa\PRACTICEExamForms.csv'
    WITH
    (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',  --CSV field delimiter
    ROWTERMINATOR = '\n',   --Use to shift the control to next row
    TABLOCK
    )
GO

CREATE VIEW etlPracticalNationalExamTake AS
SELECT 
    s.ID AS [StudentID],
	e.ID AS [InstructorID],
    d.ID AS [DateID],
    w.ID AS [WordID],
    DATEDIFF(day, st.End_date, r.exam_date) AS [TimeFromCourseEnd],
    tr.ID AS [ResultID]
FROM
    dbo.ResultTemp r 
	JOIN [hurtownia].[dbo].t_student s
    ON r.pesel = s.PESEL
	JOIN [DrivingSchool16].[dbo].Participation p
	ON r.pesel = p.FK_Student_PESEL
	JOIN [DrivingSchool16].[dbo].Meeting m
	ON p.FK_Meeting_Id = m.PK_Id
	JOIN [hurtownia].[dbo].t_employee e
	ON m.FK_Employee_PESEL = e.PESEL AND e.EmployeeRole = 'Instructor'
    JOIN [hurtownia].[dbo].t_date d
    ON d.DateYear = DATEPART(year, r.exam_date) AND d.DateMonth = DATEPART(month, r.exam_date) AND d.DateDay = DATEPART(day, r.exam_date)
    JOIN [hurtownia].[dbo].t_word w
    ON r.city = w.CityName
    JOIN [DrivingSchool16].[dbo].[Student] st
    ON r.pesel = st.PK_PESEL
	JOIN [hurtownia].[dbo].t_exam_result tr 
    ON r.attempt_number = tr.TakeNumber AND tr.IsPassed=IIF(r.isPassed = 'zdany', 1, 0)
GO

SELECT * FROM etlPracticalNationalExamTake
/*
INSERT INTO [hurtownia].[dbo].t_theoretical_national_exam_take(StudentID, InstructorID, DateID, WordID, Score, TimeFromCourseEnd, ResultID)
SELECT
    StudentID, InstructorID, DateID, WordID, Score, TimeFromCourseEnd, ResultID
FROM
    etlPracticalNationalExamTake
EXCEPT
SELECT
    StudentID, InstructorID, DateID, WordID, Score, TimeFromCourseEnd, ResultID
FROM
    [hurtownia].[dbo].t_theoretical_national_exam_take
GO
*/
DROP VIEW etlPracticalNationalExamTake
DROP TABLE dbo.ResultTemp