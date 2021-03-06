USE [StoreManagement]
GO

CREATE SCHEMA [usr]
GO

DROP TABLE [usr].[User]
GO

CREATE TABLE [usr].[User] (
	ID UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY NOT NULL,
	Email VARCHAR(50) UNIQUE NOT NULL,
	FirstName VARCHAR(40) NOT NULL,
	LastName VARCHAR(40) NOT NULL,
	Pass BINARY(64) NOT NULL,
	Salt UNIQUEIDENTIFIER NOT NULL,
	DepartmentCode CHAR(5) NOT NULL,
	isStaff BIT NOT NULL DEFAULT 0
)
ALTER TABLE [usr].[User]
ADD FOREIGN KEY (DepartmentCode) REFERENCES [usr].[Department](code)
GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [usr].[CreateUser]
(
    @Email VARCHAR(50), 
    @Password VARCHAR(50),
    @FirstName VARCHAR(40) = NULL, 
    @LastName VARCHAR(40) = NULL,
	@DepartmentCode CHAR(5),
	@isStaff BIT = 0,
    @responseMessage NVARCHAR(250) OUTPUT
)
AS

BEGIN
    SET NOCOUNT ON

    DECLARE @salt UNIQUEIDENTIFIER=NEWID()
    BEGIN TRY

        INSERT INTO [usr].[User] (Email, FirstName, LastName, Pass, Salt,DepartmentCode, isStaff)
        VALUES(@Email, @FirstName, @LastName, HASHBYTES('SHA2_512', @Password+CAST(@salt AS NVARCHAR(36))), @salt, @DepartmentCode,@isStaff)

       SET @responseMessage='Success'

    END TRY
    BEGIN CATCH
        SET @responseMessage='Failure'
    END CATCH

END
GO

ALTER PROCEDURE [usr].[UserLogin]
    @Email VARCHAR(50), 
    @Password VARCHAR(50),
    @responseMessage VARCHAR(50)='' OUTPUT
AS
BEGIN

    SET NOCOUNT ON

    DECLARE @userID UNIQUEIDENTIFIER

    IF EXISTS (SELECT TOP 1 ID FROM [usr].[User] WHERE Email=@Email)
    BEGIN
        SET @userID=(SELECT ID FROM [usr].[User] WHERE Email=@Email AND Pass=HASHBYTES('SHA2_512', @Password+CAST(Salt AS NVARCHAR(36))))

       IF(@userID IS NULL)
           SET @responseMessage='Incorrect password'
       ELSE 
           SET @responseMessage='Login successful'
    END
    ELSE
       SET @responseMessage='Invalid username'

END
GO

CREATE PROCEDURE [usr].[getUser](
	@Email VARCHAR(50)
)
AS
	IF EXISTS (SELECT TOP 1 ID FROM [usr].[User] WHERE Email=@Email)
	BEGIN
		SELECT
			[Email],
			[Firstname],
			[LastName],
			[DepartmentCode],
			[isStaff]
		FROM [usr].[User]
		WHERE [Email] = @Email
	END
		
GO

CREATE TABLE [usr].[Department]
(
	Code CHAR(5) PRIMARY KEY,
	[Name] VARCHAR(25)
)
GO

CREATE SCHEMA [itm]
GO

CREATE TABLE [itm].[Unit]
(
	UnitName VARCHAR(50) PRIMARY KEY,
	Val VARCHAR(25),
	DataType VARCHAR(25)
)
GO

CREATE TABLE [itm].[Item]
(
	Code VARCHAR(10) PRIMARY KEY,
	[Name] VARCHAR(25),
	Variant VARCHAR(25),
	UnitName VARCHAR(50),
	Risk BIT,
	Price float
)
ALTER TABLE [itm].[Item]
ADD FOREIGN KEY (UnitName) REFERENCES [itm].[Unit](UnitName)

GO

CREATE TABLE [itm].[Stock]
(
	StockCode VARCHAR(10) PRIMARY KEY,
	ItemCode VARCHAR(10) FOREIGN KEY REFERENCES [itm].[Item](Code),
	Quantity VARCHAR(10),
	UnitName VARCHAR(50) FOREIGN KEY REFERENCES [itm].[Unit](UnitName),
	MinThreshold VARCHAR(10),
	MaxThreshold VARCHAR(10)
)
GO

CREATE TABLE [itm].[Transaction]
(
	TransactionID UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY NOT NULL,
	UserID UNIQUEIDENTIFIER FOREIGN KEY REFERENCES [usr].[User](ID),
	ItemCode VARCHAR(10) FOREIGN KEY REFERENCES [itm].[Item](Code),
	Quantity VARCHAR(10),
	TransactionDate DATE,
	isRefund BIT DEFAULT 0
)
GO