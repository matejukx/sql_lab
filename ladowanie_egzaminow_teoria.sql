USE hurtownia
GO

If (object_id('dbo.ResultTemp') is not null) DROP TABLE dbo.ResultTemp;
CREATE TABLE dbo.ResultTemp(pesel varchar(11), exam_type varchar(6), score float, attempt_number int, exam_date date, city varchar(85))
GO 
BULK INSERT dbo.ResultTemp
    FROM 'C:\Users\Kuba\Downloads\essa\essa\THEORYExamForms.csv'
    WITH
    (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',  --CSV field delimiter
    ROWTERMINATOR = '\n',   --Use to shift the control to next row
    TABLOCK
    )
GO

CREATE VIEW etlTheoreticalNationalExamTake AS
SELECT 
    s.ID AS [StudentID],
	e.ID AS [LecturerID],
    d.ID AS [DateID],
    w.ID AS [WordID],
    CAST(score AS int) AS [Score],
    DATEDIFF(day, st.End_date, r.exam_date) AS [TimeFromCourseEnd],
    tr.ID AS [ResultID]
FROM
    dbo.ResultTemp r 
	JOIN [hurtownia].[dbo].t_student s
    ON r.pesel = s.PESEL
	JOIN [DrivingSchool16].[dbo].Participation p
	ON r.pesel = p.FK_Student_PESEL
	JOIN [DrivingSchool16].[dbo].Meeting m
	ON p.FK_Meeting_Id = m.PK_Id and m.Type = 'Lecture'
	JOIN [hurtownia].[dbo].t_employee e
	ON m.FK_Employee_PESEL = e.PESEL
    JOIN [hurtownia].[dbo].t_date d
    ON d.DateYear = DATEPART(year, r.exam_date) AND d.DateMonth = DATEPART(month, r.exam_date) AND d.DateDay = DATEPART(day, r.exam_date)
    JOIN [hurtownia].[dbo].t_word w
    ON r.city = w.CityName
    JOIN [DrivingSchool16].[dbo].[Student] st
    ON r.pesel = st.PK_PESEL
    JOIN [hurtownia].[dbo].t_exam_result tr 
    ON r.attempt_number = tr.TakeNumber AND tr.IsPassed=IIF(r.score > 91.8, 1, 0)
GO

INSERT INTO [hurtownia].[dbo].t_theoretical_national_exam_take(StudentID, LecturerID, DateID, WordID, Score, TimeFromCourseEnd, ResultID)
SELECT
    StudentID, LecturerID, DateID, WordID, Score, TimeFromCourseEnd, ResultID
FROM
    etlTheoreticalNationalExamTake
EXCEPT
SELECT
    StudentID, LecturerID, DateID, WordID, Score, TimeFromCourseEnd, ResultID
FROM
    [hurtownia].[dbo].t_theoretical_national_exam_take
GO

DROP VIEW etlTheoreticalNationalExamTake
DROP TABLE dbo.ResultTemp