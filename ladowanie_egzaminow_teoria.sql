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
    [StudentID]
    [DateID]
    [WordID]
    [Score]
    [TimeFromCourseEnd]
    [ResultID]
FROM

GO

DROP TABLE dbo.ResultTemp