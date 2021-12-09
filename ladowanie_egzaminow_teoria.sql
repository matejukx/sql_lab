USE hurtownia
GO

If (object_id('dbo.ResultTemp') is not null) DROP TABLE dbo.ResultTemp;
CREATE TABLE dbo.ResultTemp(pesel varchar(11), exam_type varchar(6), score float, attempt_number int, exam_date date, city varchar(85))
GO 
BULK INSERT dbo.ResultTemp
    FROM 'C:\Users\Kuba\Downloads\essa\essa\THEORYExamForms.csv'
    WITH
    (
    FIRSTROW = 1,
    FIELDTERMINATOR = ',',  --CSV field delimiter
    ROWTERMINATOR = '\n',   --Use to shift the control to next row
    TABLOCK
    )
GO

CREATE VIEW etlTheoreticalNationalExamTake AS
SELECT 
    s.ID AS [StudentID],
    d.ID AS [DateID],
    w.ID AS [WordID],
    CAST(score AS int) AS [Score],
    DATEDIFF(day, r.exam_date, st.End_date) AS [TimeFromCourseEnd],
    tr.ID AS [ResultID]
FROM
    dbo.ResultTemp r JOIN [hurtownia].[dbo].t_student s
    ON r.pesel = s.PESEL
    JOIN [hurtownia].[dbo].t_date d
    ON d.DateYear = DATEPART(year, r.exam_date) AND d.DateMonth = DATEPART(month, r.exam_date) AND d.DateDay = DATEPART(day, r.exam_date)
    JOIN [hurtownia].[dbo].t_word w
    ON r.city = w.CityName
    JOIN [DrivingSchool16].[dbo].[Student] st
    ON r.pesel = st.PK_PESEL
    JOIN [hurtownia].[dbo].t_result tr 
    ON r.attempt_number = tr.TakeNumber AND tr.IsPassed=IIF(r.score > 91.8, 1, 0)
GO

DROP VIEW etlTheoreticalNationalExamTake
DROP TABLE dbo.ResultTemp