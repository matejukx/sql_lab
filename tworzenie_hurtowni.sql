CREATE database hurtownia
GO     

USE hurtownia

CREATE table t_date(
    ID int IDENTITY(1,1) PRIMARY KEY,
    DateYear int,
    DateMonth int,
    DateDay int,
    Season varchar(6),

    CONSTRAINT CHK_DATE CHECK (
            DateDay>=1
        AND 
        (
            (DateMonth=1 AND DateDay<=31) OR 
            (DateMonth=2 AND (DateYear%4 = 0 AND DateDay<=29) OR DateDay<=28) OR 
            (DateMonth=3 AND DateDay<=31) OR 
            (DateMonth=4 AND DateDay<=30) OR 
            (DateMonth=5 AND DateDay<=31) OR 
            (DateMonth=6 AND DateDay<=30) OR 
            (DateMonth=7 AND DateDay<=31) OR 
            (DateMonth=8 AND DateDay<=31) OR 
            (DateMonth=9 AND DateDay<=30) OR 
            (DateMonth=10 AND DateDay<=31) OR 
            (DateMonth=11 AND DateDay<=30) OR 
            (DateMonth=12 AND DateDay<=31)
        )
        AND
            DateYear>=1 
        AND
        (
            Season='wiosna' OR
            Season='lato' OR
            Season='jesien' OR
            Season='zima'  
        )
        
    )
)
GO


CREATE table t_employee(
    ID int IDENTITY(1,1) PRIMARY KEY,
    PESEL varchar(11) NOT NULL,
    EmployeeName varchar(100) NOT NULL,
    Gender varchar(9) NOT NULL,
    EmploymentDateID int NOT NULL FOREIGN KEY REFERENCES t_date(ID),
    EmployeeRole varchar(10) NOT NULL,
    Wage varchar(10) NOT NULL,
    IsCurrent int NOT NULL,
    CONSTRAINT CHK_EMPLOYEE CHECK (
        (
            Gender='Mezczyzna' OR 
            Gender='Kobieta' OR 
            Gender='Inna'
        )
        AND
        (
            EmployeeRole='Wykladowca' OR 
            EmployeeRole='Instruktor'
        )
        AND
        (
            Wage='niska' OR 
            Wage='przecietna' OR 
            Wage='wysoka'
        )
        AND
        (
            IsCurrent=0 OR 
            IsCurrent=1
        )
    )

)
GO

CREATE table t_student(
    ID int IDENTITY(1,1) PRIMARY KEY,
    PESEL varchar(11) NOT NULL,
    StudentName varchar(100) NOT NULL,
    Gender varchar(9) NOT NULL,
    IsCurrent int NOT NULL,

    CONSTRAINT CHK_STUDENT CHECK (
        (
            Gender='Mezczyzna' OR 
            Gender='Kobieta' OR 
            Gender='Inna'
        )
        AND
        (
            IsCurrent=0 OR 
            IsCurrent=1
        )
    )
)
GO

CREATE table t_course_rating(
    ID int IDENTITY(1,1) PRIMARY KEY,
    StudentID int NOT NULL FOREIGN KEY REFERENCES t_student(ID),
    Rating int NOT NULL,

    CONSTRAINT CHK_COURSE_RATING CHECK (
        Rating>=1 AND Rating <=10
    )
)
GO

CREATE table t_employee_rating(
    ID int IDENTITY(1,1) PRIMARY KEY,
    StudentID int NOT NULL FOREIGN KEY REFERENCES t_student(ID),
    EmployeeID int NOT NULL FOREIGN KEY REFERENCES t_employee(ID),
    Rating int NOT NULL,

    CONSTRAINT CHK_EMPLOYEE_RATING CHECK (
        Rating>=1 AND Rating<=10
    )
)
GO

CREATE table t_course_participation(
    ID int IDENTITY(1,1) PRIMARY KEY,
    StudentID int NOT NULL FOREIGN KEY REFERENCES t_student(ID),
    StartDateID int NOT NULL FOREIGN KEY REFERENCES t_date(ID),
    EndDateID int NOT NULL FOREIGN KEY REFERENCES t_date(ID),
    InstructorID int NOT NULL FOREIGN KEY REFERENCES t_employee(ID),
    LecturerID int NOT NULL FOREIGN KEY REFERENCES t_employee(ID),
    DrivesDone int NOT NULL,
	AdditionalDrivesDone AS IIF(DrivesDone-30<0, 0,DrivesDone-30),
    InternalTheoreticalExamTakes int NOT NULL,
    InternalPracticalExamTakes int NOT NULL,
    TheoreticalCourseTime int,
    PracticalCourseTime int,

    CONSTRAINT CHK_COURSE_PARTICIPATION CHECK (
        DrivesDone>=0 AND
        InternalTheoreticalExamTakes>=0 AND
        InternalPracticalExamTakes>=0 AND
        TheoreticalCourseTime>=0 AND
        PracticalCourseTime>=0 
    )
)
GO

CREATE table t_course_monthly_participation(
    ID int IDENTITY(1,1) PRIMARY KEY,
    StudentID int NOT NULL FOREIGN KEY REFERENCES t_student(ID),
    InstructorID int NOT NULL FOREIGN KEY REFERENCES t_employee(ID),
    LecturerID int NOT NULL FOREIGN KEY REFERENCES t_employee(ID),
    MonthId int NOT NULL FOREIGN KEY REFERENCES t_date(ID),
    DrivesDone int NOT NULL,

    CONSTRAINT CHK_COURSE_MONTHLY_PARTICIPATION CHECK (
        DrivesDone>=0 
    )
)
GO

CREATE table t_exam_result(
    ID int IDENTITY(1,1) PRIMARY KEY,
    IsPassed int NOT NULL,
    TakeNumber int NOT NULL,

    CONSTRAINT CHK_EXAM_RESULT CHECK (
		(
			IsPassed=1 OR
			IsPassed=0
		)
		AND
        TakeNumber>=1
    )
)
GO

CREATE table t_word(
    ID int IDENTITY(1,1) PRIMARY KEY,
    CityName varchar(85) NOT NULL,
    Province varchar(85) NOT NULL,
    Word_Name varchar(85) NOT NULL
)
GO

CREATE table t_practical_national_exam_take(
    ID int IDENTITY(1,1) PRIMARY KEY,
    StudentID int NOT NULL FOREIGN KEY REFERENCES t_student(ID),
	InstructorID int NOT NULL FOREIGN KEY REFERENCES t_employee(ID),
	DateID int NOT NULL FOREIGN KEY REFERENCES t_date(ID),
    WordID int NOT NULL FOREIGN KEY REFERENCES t_word(ID),
    TimeFromCourseEnd int NOT NULL,
    ExamResultID int NOT NULL FOREIGN KEY REFERENCES t_exam_result(ID)
)
GO

CREATE table t_theoretical_national_exam_take(
    ID int IDENTITY(1,1) PRIMARY KEY,
    StudentID int NOT NULL FOREIGN KEY REFERENCES t_student(ID),
	LecturerID int NOT NULL FOREIGN KEY REFERENCES t_employee(ID),
	DateID int NOT NULL FOREIGN KEY REFERENCES t_date(ID),
    WordID int NOT NULL FOREIGN KEY REFERENCES t_word(ID),
    Score int NOT NULL,
    TimeFromCourseEnd int NOT NULL,
    ResultID int NOT NULL FOREIGN KEY REFERENCES t_exam_result(ID),

    CONSTRAINT CHK_THEORETICAL_NATIONAL_EXAM_TAKE CHECK (
        Score>=0 AND Score<=74
    )
)
GO