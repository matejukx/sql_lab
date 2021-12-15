IF (object_id('etlStudent') is not null) DROP VIEW etlStudent -- wyrzucenie widoku jesli juz jest
GO


CREATE VIEW etlStudent AS
SELECT 
    s.PK_PESEL AS PESEL,
    CAST(p.Name + ' ' + p.Surname AS varchar(100)) AS StudentName,
    CASE
        WHEN p.Gender = 'Female' THEN 'Kobieta'
        WHEN p.Gender = 'Male' THEN 'Mezczyzna'
        ELSE 'Inna'
    END AS Gender
FROM 
    [DrivingSchool16].[dbo].Student s JOIN [DrivingSchool16].[dbo].Person p
    ON s.PK_PESEL = p.PK_PESEL
GO

MERGE [hurtownia].[dbo].t_student AS T
USING etlStudent AS S 
ON T.PESEL = S.PESEL
WHEN NOT MATCHED BY TARGET
    THEN 
    INSERT (PESEL, StudentName, Gender, IsCurrent) 
    VALUES (S.PESEL, S.StudentName, S.Gender, 1)
WHEN NOT MATCHED BY Source
    THEN
        UPDATE
        SET T.IsCurrent = 0
WHEN MATCHED 
    AND (
        T.StudentName <> S.StudentName
        OR T.Gender <> S.Gender
        )
    THEN
        UPDATE
        SET T.IsCurrent = 0
;
INSERT INTO [hurtownia].[dbo].t_student(PESEL, StudentName, Gender, IsCurrent) 
SELECT 
    PESEL, StudentName, Gender, 1
FROM 
    etlStudent
EXCEPT
SELECT 
    PESEL, StudentName, Gender, 1
FROM 
    [hurtownia].[dbo].t_student
GO

DROP VIEW etlStudent 
