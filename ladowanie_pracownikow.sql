IF (object_id('etlEmployee') is not null) DROP VIEW etlEmployee -- wyrzucenie widoku jesli juz jest
GO

CREATE VIEW etlEmployee AS
SELECT 
    e.PK_PESEL AS PESEL,
    CAST(p.Name + ' ' + p.Surname AS varchar(100)) AS EmployeeName,
    CASE
        WHEN p.Gender = 'Female' THEN 'Kobieta'
        WHEN p.Gender = 'Male' THEN 'Mezczyzna'
        ELSE 'Inna'
    END AS Gender,
    d.ID as EmploymentDateID,
    CASE
        WHEN e.Role = 'Lecturer' THEN 'Wykladowca'
        ELSE 'Instruktor'
    END AS EmployeeRole,
    CASE 
        WHEN e.Wage_per_hour <= 10 THEN 'niska'
        WHEN e.Wage_per_hour >= 12 THEN 'wysoka'
        ELSE 'przecietna'
    END AS Wage
FROM 
    [DrivingSchool16].[dbo].Employee e 
    JOIN [DrivingSchool16].[dbo].Person p
    ON e.PK_PESEL = p.PK_PESEL
    JOIN [hurtownia].[dbo].t_date d
    ON d.DateYear = DATEPART(year, e.Employment_date) AND d.DateMonth = DATEPART(month, e.Employment_date) AND d.DateDay = DATEPART(day, e.Employment_date)
GO

IF (object_id('nullEmployee') is not null) DROP VIEW nullEmployee-- wyrzucenie widoku jesli juz jest
GO

CREATE VIEW nullEmployee AS
SELECT 
    CAST(NULL AS varchar(11)) AS PESEL,
    CAST(NULL AS varchar(100)) AS EmployeeName,
    CAST(NULL AS varchar(9)) AS Gender,
    d.ID as EmploymentDateID,
    CAST(NULL AS varchar(10)) AS EmployeeRole,
    CAST(NULL AS varchar(10)) AS Wage
FROM [hurtownia].[dbo].t_date d
WHERE d.DateYear IS NULL AND d.DateMonth IS NULL AND d.DateDay IS NULL
GO

IF (object_id('etlFinalEmployee') is not null) DROP VIEW etlFinalEmployee-- wyrzucenie widoku jesli juz jest
GO
CREATE VIEW etlFinalEmployee AS
SELECT * FROM etlEmployee
UNION
SELECT * FROM nullEmployee
GO


MERGE [hurtownia].[dbo].t_employee AS T
USING etlFinalEmployee AS S 
ON T.PESEL = S.PESEL
WHEN NOT MATCHED BY TARGET
    THEN 
    INSERT (PESEL, EmployeeName, Gender, EmploymentDateID, EmployeeRole, Wage, IsCurrent) 
    VALUES (S.PESEL, S.EmployeeName, S.Gender, S.EmploymentDateID, S.EmployeeRole, S.Wage, 1)
WHEN NOT MATCHED BY Source
    THEN
        UPDATE
        SET T.IsCurrent = 0
WHEN MATCHED 
    AND (
        T.EmployeeName <> S.EmployeeName
        OR T.EmployeeRole <> S.EmployeeRole
        OR T.Wage <> S.Wage
        OR T.Gender <> S.Gender
        )
    THEN
        UPDATE
        SET T.IsCurrent = 0
;
INSERT INTO [hurtownia].[dbo].t_employee(PESEL, EmployeeName, Gender, EmploymentDateID, EmployeeRole, Wage, IsCurrent)
SELECT 
    PESEL, EmployeeName, Gender, EmploymentDateID, EmployeeRole, Wage, 1
FROM 
    etlFinalEmployee
EXCEPT
SELECT 
    PESEL, EmployeeName, Gender, EmploymentDateID, EmployeeRole, Wage, 1
FROM 
    [hurtownia].[dbo].t_employee
GO

DROP VIEW etlFinalEmployee 
DROP VIEW etlEmployee 

