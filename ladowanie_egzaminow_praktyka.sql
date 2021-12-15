USE hurtownia
GO

If (object_id('dbo.ResultTemp') is not null) DROP TABLE dbo.ResultTemp;
CREATE TABLE dbo.ResultTemp(pesel varchar(11), exam_type varchar(8), isPassed varchar(10), attempt_number int, exam_date date, city varchar(85))
GO 
BULK INSERT dbo.ResultTemp
    FROM 'C:\Users\mmatejuk\Downloads\essa\essa\PRACTICEExamForms.csv'
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
	p.InstructorID AS [InstructorID],
    d.ID AS [DateID],
    w.ID AS [WordID],
    DATEDIFF(day, st.End_date, r.exam_date) AS [TimeFromCourseEnd],
    tr.ID AS [ExamResultID]
FROM
    dbo.ResultTemp r 
	JOIN [hurtownia].[dbo].t_student s
    ON r.pesel = s.PESEL
	JOIN [hurtownia].[dbo].t_course_participation p
    ON p.ID = s.ID
    JOIN [hurtownia].[dbo].t_date d
    ON d.DateYear = DATEPART(year, r.exam_date) AND d.DateMonth = DATEPART(month, r.exam_date) AND d.DateDay = DATEPART(day, r.exam_date)
    JOIN [hurtownia].[dbo].t_word w
    ON r.city = w.CityName
    JOIN [DrivingSchool16].[dbo].[Student] st
    ON r.pesel = st.PK_PESEL
	JOIN [hurtownia].[dbo].t_exam_result tr 
    ON CONCAT('Proba ',CAST(r.attempt_number AS VARCHAR)) = tr.TakeNumber AND tr.IsPassed=IIF(r.isPassed = 'zdany', 1, 0)
GO

INSERT INTO [hurtownia].[dbo].t_practical_national_exam_take(StudentID, InstructorID, DateID, WordID, TimeFromCourseEnd, ExamResultID)
SELECT
    StudentID, InstructorID, DateID, WordID, TimeFromCourseEnd, ExamResultID
FROM
    etlPracticalNationalExamTake
EXCEPT
SELECT
    StudentID, InstructorID, DateID, WordID, TimeFromCourseEnd, ExamResultID
FROM
    [hurtownia].[dbo].t_practical_national_exam_take
GO

DROP VIEW etlPracticalNationalExamTake
DROP TABLE dbo.ResultTemp