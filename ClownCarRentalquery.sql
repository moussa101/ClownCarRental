-- Step 1: Create the Database
CREATE DATABASE ClownCarRental;
GO

-- Step 2: Use the Database
USE ClownCarRental;
GO

-- Step 3: Create the Tables

-- Customers Table
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    PhoneNumber VARCHAR(15) NOT NULL
);
GO

-- Clown Cars Table
CREATE TABLE ClownCars (
    CarID INT IDENTITY(1,1) PRIMARY KEY,
    CarName VARCHAR(50) NOT NULL,
    CarType VARCHAR(50) NOT NULL,
    Color VARCHAR(30),
    SeatingCapacity INT NOT NULL,
    AvailabilityStatus VARCHAR(20) DEFAULT 'Available' CHECK (AvailabilityStatus IN ('Available', 'Rented', 'Maintenance')),
    DailyRentalRate DECIMAL(10, 2) NOT NULL
);
GO

-- Rentals Table
CREATE TABLE Rentals (
    RentalID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL FOREIGN KEY REFERENCES Customers(CustomerID),
    CarID INT NOT NULL FOREIGN KEY REFERENCES ClownCars(CarID),
    RentalStartDate DATE NOT NULL,
    RentalEndDate DATE NOT NULL,
    TotalCost DECIMAL(10, 2),
    RentalStatus VARCHAR(20) DEFAULT 'Active' CHECK (RentalStatus IN ('Active', 'Completed', 'Cancelled'))
);
GO

-- Staff Table
CREATE TABLE Staff (
    StaffID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    JobTitle VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    PhoneNumber VARCHAR(15)
);
GO

-- Step 4: Insert Sample Data

-- Insert Customers
INSERT INTO Customers (FirstName, LastName, Email, PhoneNumber)
VALUES ('John', 'Doe', 'john.doe@example.com', '123-456-7890'),
       ('Jane', 'Smith', 'jane.smith@example.com', '987-654-3210');
GO

-- Insert Clown Cars
INSERT INTO ClownCars (CarName, CarType, Color, SeatingCapacity, DailyRentalRate)
VALUES ('Tiny Wonder', 'Compact', 'Red', 4, 19.99),
       ('Rainbow Rider', 'Sedan', 'Rainbow', 6, 29.99);
GO

-- Insert Staff
INSERT INTO Staff (FirstName, LastName, JobTitle, Email, PhoneNumber)
VALUES ('Ronald', 'McDonald', 'Manager', 'ronald@example.com', '111-222-3333'),
       ('Penny', 'Wise', 'Technician', 'penny@example.com', '444-555-6666');
GO

-- Step 5: Create Trigger to Calculate TotalCost
CREATE TRIGGER trg_CalculateTotalCost
ON Rentals
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE Rentals
    SET TotalCost = DATEDIFF(DAY, RentalStartDate, RentalEndDate) * cc.DailyRentalRate
    FROM Rentals r
    JOIN ClownCars cc ON r.CarID = cc.CarID
    WHERE r.TotalCost IS NULL;
END;
GO

-- Example Query: List all available cars
SELECT * 
FROM ClownCars
WHERE AvailabilityStatus = 'Available';
GO

-- Create the Trigger
CREATE TRIGGER trg_CheckSeatingCapacity
ON ClownCars
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    -- Check for seating capacity less than 50
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE SeatingCapacity < 50
    )
    BEGIN
        RAISERROR ('Seating capacity cannot be less than 50.', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        -- Allow the operation to proceed
        IF EXISTS (SELECT 1 FROM inserted)
        BEGIN
            INSERT INTO ClownCars (CarName, CarType, Color, SeatingCapacity, AvailabilityStatus, DailyRentalRate)
            SELECT CarName, CarType, Color, SeatingCapacity, AvailabilityStatus, DailyRentalRate
            FROM inserted;
        END
        
        IF EXISTS (SELECT 1 FROM deleted)
        BEGIN
            UPDATE ClownCars
            SET CarName = i.CarName,
                CarType = i.CarType,
                Color = i.Color,
                SeatingCapacity = i.SeatingCapacity,
                AvailabilityStatus = i.AvailabilityStatus,
                DailyRentalRate = i.DailyRentalRate
            FROM ClownCars c
            INNER JOIN inserted i ON c.CarID = i.CarID
            INNER JOIN deleted d ON c.CarID = d.CarID;
        END
    END
END;
GO
