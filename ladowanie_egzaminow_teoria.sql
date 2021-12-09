CREATE FUNCTION dbo.Unpolishify(@STR varchar(85))
RETURNS varchar(85)
AS
BEGIN
SET @STR = REPLACE ( @STR COLLATE Latin1_General_CS_AI, 'ą', 'a')
SET @STR = REPLACE ( @STR COLLATE Latin1_General_CS_AI, 'ć', 'c')
SET @STR = REPLACE ( @STR COLLATE Latin1_General_CS_AI, 'ę', 'e')
SET @STR = REPLACE ( @STR COLLATE Latin1_General_CS_AI, 'ł', 'l')
SET @STR = REPLACE ( @STR COLLATE Latin1_General_CS_AI, 'ń', 'n')
SET @STR = REPLACE ( @STR COLLATE Latin1_General_CS_AI, 'ó', 'o')
SET @STR = REPLACE ( @STR COLLATE Latin1_General_CS_AI, 'ś', 's')
SET @STR = REPLACE ( @STR COLLATE Latin1_General_CS_AI, 'ź', 'z')
SET @STR = REPLACE ( @STR COLLATE Latin1_General_CS_AI, 'ż', 'z')
return @STR
END
GO

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
    ON r.city = dbo.Unpolishify(w.CityName)
    JOIN [DrivingSchool16].[dbo].[Student] st
    ON r.pesel = st.PK_PESEL
    JOIN [hurtownia].[dbo].t_result tr 
    ON r.attempt_number = tr.TakeNumber AND tr.IsPassed=IIF(r.score > 91.8, 1, 0)
GO

INSERT INTO [hurtownia].[dbo].t_theoretical_national_exam_take
VALUES
    (StudentID, DateID, WordID, Score, TimeFromCourseEnd, ExamResultID
FROM 
    etlTheoreticalNationalExamTake
EXCEPT
SELECT
    StudentID, DateID, WordID, Score, TimeFromCourseEnd, ExamResultID
FROM
    [hurtownia].[dbo].t_theoretical_national_exam_take
GO

DROP VIEW etlTheoreticalNationalExamTake
DROP TABLE dbo.ResultTemp