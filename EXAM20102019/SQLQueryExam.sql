CREATE DATABASE Service

GO 

USE Service

GO
--DROP DATABASE 


CREATE TABLE Users(
Id INT PRIMARY KEY IDENTITY,
Username NVARCHAR(30) NOT NULL,
[Password] NVARCHAR(50) NOT NULL,
[Name] NVARCHAR (50) ,
Birthdate DATETIME ,
Age INT CHECK (Age>=14 AND Age <=110),
Email NVARCHAR (50) NOT NULL 
)

CREATE TABLE Departments(
Id INT PRIMARY KEY IDENTITY,
[Name] NVARCHAR (50) NOT NULL
)

CREATE TABLE Employees(
Id INT PRIMARY KEY IDENTITY,
FirstName NVARCHAR(25),
LastName NVARCHAR(25),
Birthdate DATETIME ,
Age INT CHECK (Age>=18 AND Age <=110),
DepartmentId INT FOREIGN KEY REFERENCES Departments(Id)
)

CREATE TABLE Categories(
Id INT PRIMARY KEY IDENTITY,
[Name] NVARCHAR (50) NOT NULL,
DepartmentId INT NOT NULL FOREIGN KEY REFERENCES Departments(Id)
)

CREATE TABLE [Status](
Id INT PRIMARY KEY IDENTITY,
[Label] NVARCHAR (30) NOT NULL,
)

CREATE TABLE Reports(
Id INT PRIMARY KEY IDENTITY,
CategoryId INT NOT NULL  FOREIGN KEY REFERENCES Categories(Id),
StatusId INT  NOT NULL FOREIGN KEY REFERENCES [Status](Id),
OpenDate DATETIME NOT NULL,
CloseDate DATETIME ,
[Description] NVARCHAR (200) NOT NULL,
UserId INT NOT NULL FOREIGN KEY REFERENCES Users(Id),
EmployeeId INT FOREIGN KEY REFERENCES Employees(Id)
)


 --2 INSERT

 INSERT INTO Employees(FirstName,LastName, Birthdate,DepartmentId)
 VALUES	('Marlo','O''Malley','1958-9-21',1),
		('Niki','Stanaghan','1969-11-26',4),
		('Ayrton','Senna','1960-03-21',9),
		('Ronnie','Peterson','1944-02-14',9),
		('Giovanna','Amati','1959-07-20',5)

INSERT INTO Reports(CategoryId, StatusId, OpenDate, CloseDate,[Description], UserId, EmployeeId)
 VALUES	(1,1,'2017-04-13',NULL,'Stuck Road on Str.133',6,2),
		(6,3,'2015-09-05','2015-12-06','Charity trail running',3,5),
		(14,2,'2015-09-07',NULL,'Falling bricks on Str.58',5,2),
		(4,3,'2017-07-03','2017-07-06','Cut off streetlight on Str.11',1,1)
		

-- 3 UPDATE

UPDATE Reports
SET CloseDate = GETDATE()
WHERE CloseDate IS NULL

-- 4 DELETE

DELETE FROM Reports
WHERE StatusId = 4

--	    5. 

SELECT [Description], FORMAT(OpenDate,'dd-MM-yyyy') --AS OpenDate
FROM Reports
WHERE EmployeeId IS NULL
ORDER BY OpenDate, [Description]


GO

--    6. 

SELECT Description,c.[Name] 
FROM Reports AS r
	JOIN Categories AS c
	ON r.CategoryId =c.Id
WHERE CategoryId IS NOT NULL
Order BY Description,c.[Name]

GO 
--     7. 

SELECT TOP(5) c.[Name] AS CategoryName, COUNT(r.Id) AS ReportsNumber
FROM Categories AS c
	JOIN Reports AS r
	ON c.Id = r.CategoryId
GROUP BY c.[Name]
ORDER BY ReportsNumber DESC, c.[Name]


GO
--     8. 

SELECT u.Username AS Username, c.Name AS CategpryNmae
FROM Users AS u
	JOIN Reports AS r
	ON u.Id =r.UserId
	JOIN Categories AS c
	ON c.Id=r.CategoryId
WHERE MONTH(r.OpenDate)=MONTH(u.Birthdate) 
	AND  DAY(r.OpenDate)=DAY(u.Birthdate)
ORDER BY u.Username , c.Name

--    9.
 
SELECT CONCAT(e.FirstName,' ',e.LastName) AS FullName, COUNT(DISTINCT u.Id) AS UsersCoun
FROM Employees AS e
	LEFT JOIN Reports AS r
	ON e.Id = r.EmployeeId
	LEFT JOIN [Users] AS u
	ON u.Id =r.UserId
GROUP BY e.FirstName,e.LastName 
ORDER BY COUNT(DISTINCT u.Id)DESC,FullName

-- 10 

SELECT CASE 
			WHEN e.FirstName IS NULL THEN 'None'
			ELSE (CONCAT(e.FirstName,' ',e.LastName))
			END AS Employee,
	ISNULL(d.[Name],'None') AS Department,
	c.[Name] AS Category,
	r.[Description],
	FORMAT(r.OpenDate,'dd.MM.yyyy'),
	s.Label AS [Status],
	u.Name AS Users

FROM Reports AS r
	LEFT JOIN Employees AS e
	ON r.EmployeeId =  e.Id
	LEFT JOIN Departments AS d
	ON e.DepartmentId = d.Id
	LEFT JOIN Categories AS c
	ON r.CategoryId = c.Id
	LEFT JOIN [Status] AS s
	ON r.StatusId  = s.Id
	LEFT JOIN Users AS u
	ON r.UserId  = u.Id
ORDER BY e.FirstName DESC, e.LastName DESC, d.Name,
		c.Name,r.Description, r.OpenDate,
		s.Label,u.Name


--    11. 
GO

CREATE FUNCTION udf_HoursToComplete(@StartDate DATETIME, @EndDate DATETIME) 
RETURNS INT 
AS
BEGIN 	
	DECLARE @result INT
	IF (@StartDate IS NULL OR @EndDate IS NULL) SET @result= 0;
	ELSE 
	BEGIN
		SET @result=DATEDIFF(HOUR,@StartDate, @EndDate)		
	END
	RETURN @result;
END


--    12. 
GO

CREATE PROC usp_AssignEmployeeToReport(@EmployeeId INT, @ReportId INT)
AS
BEGIN
	DECLARE @eDept INT
	SET @eDept = 
		(
		SELECT TOP(1) DepartmentId
		FROM Employees
		WHERE Id = @EmployeeId
		)

		DECLARE @rDept INT
		SET @rDept = 
		(
		SELECT TOP(1) DepartmentId
		FROM Categories AS c
			JOIN Reports AS r
			ON c.Id = r.CategoryId
		WHERE r.Id = @ReportId
		)

	IF (@eDept = @rDept)
		BEGIN 
		UPDATE Reports
		SET EmployeeId = @EmployeeId
		WHERE Id = @ReportId
		END
		
	ELSE
		BEGIN
		RAISERROR('Employee doesn''t belong to the appropriate department!', 16, 1)
		RETURN
		END
END


EXEC usp_AssignEmployeeToReport 30, 1

