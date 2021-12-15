USE hurtownia
GO

If (object_id('dbo.RatingTemp') is not null) DROP TABLE dbo.RatingTemp;
CREATE TABLE dbo.RatingTemp(pesel varchar(11), lecturer_rating int, instructor_rating int, course_rating int)
GO 
BULK INSERT dbo.RatingTemp
    FROM 'C:\Users\mmatejuk\Downloads\essa\essa\AssesmentForms.csv'
    WITH
    (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',  --CSV field delimiter
    ROWTERMINATOR = '\n',   --Use to shift the control to next row
    TABLOCK
    )
GO

IF (object_id('etlCourseRating') is not null) DROP VIEW etlCourseRating
GO
CREATE VIEW etlCourseRating AS
SELECT 
    s.ID as [StudentID],
    t.course_rating as [Rating]
FROM 
    dbo.RatingTemp t JOIN [hurtownia].[dbo].t_student s
    ON t.pesel = s.PESEL AND s.isCurrent = 1
GO

INSERT INTO [hurtownia].[dbo].t_course_rating(StudentID, Rating)
SELECT
    StudentID, Rating
FROM
    etlCourseRating
EXCEPT
SELECT
    StudentID, Rating
FROM
    [hurtownia].[dbo].t_course_rating
GO

IF (object_id('etlLecturerRating') is not null) DROP VIEW etlLecturerRating
GO
CREATE VIEW etlLecturerRating AS
SELECT
    s.ID AS [StudentID],
    p.LecturerID AS [EmployeeID],
    t.lecturer_rating AS [Rating]
FROM
    dbo.RatingTemp t JOIN [hurtownia].[dbo].t_student s
    ON t.pesel = s.PESEL AND s.isCurrent = 1
    JOIN
    [hurtownia].[dbo].t_course_participation p
    ON s.ID = p.StudentID
GO

IF (object_id('etlInstructorRating') is not null) DROP VIEW etlInstructorRating
GO
CREATE VIEW etlInstructorRating AS
SELECT
    s.ID AS [StudentID],
    p.LecturerID AS [EmployeeID],
    t.instructor_rating AS [Rating]
FROM
    dbo.RatingTemp t JOIN [hurtownia].[dbo].t_student s
    ON t.pesel = s.PESEL AND s.isCurrent = 1
    JOIN
    [hurtownia].[dbo].t_course_participation p
    ON s.ID = p.StudentID
GO

INSERT INTO [hurtownia].[dbo].t_employee_rating(StudentID, EmployeeID, Rating)
SELECT
    StudentID, EmployeeID, Rating
FROM
    etlInstructorRating
EXCEPT
SELECT
    StudentID, EmployeeID, Rating
FROM
    [hurtownia].[dbo].t_employee_rating
GO

INSERT INTO [hurtownia].[dbo].t_employee_rating(StudentID, EmployeeID, Rating)
SELECT
    StudentID, EmployeeID, Rating
FROM
    etlLecturerRating
EXCEPT
SELECT
    StudentID, EmployeeID, Rating
FROM
    [hurtownia].[dbo].t_employee_rating
GO

DROP VIEW etlLecturerRating
DROP VIEW etlInstructorRating
DROP VIEW etlCourseRating
DROP TABLE dbo.RatingTemp