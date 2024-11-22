CREATE DATABASE ProductManagementDW;
GO
USE ProductManagementDW;
GO

-- Partition Function and Scheme for Fact tables
CREATE PARTITION FUNCTION PF_Monthly (INT)  
AS RANGE RIGHT FOR VALUES 
(20240101, 20240201, 20240301, 20240401, 20240501, 20240601, 20240701, 20240801, 20240901, 20241001);  

CREATE PARTITION SCHEME PS_Monthly  
AS PARTITION PF_Monthly ALL TO ([PRIMARY]);  

-- Date Dimension
CREATE TABLE Dim_Date
(
    DateKey INT PRIMARY KEY,
    Date DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    Month INT NOT NULL,
    MonthName NVARCHAR(10) NOT NULL,
    Week INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName NVARCHAR(10) NOT NULL,
    IsWeekend BIT NOT NULL,
    FiscalYear INT NOT NULL
);

CREATE NONCLUSTERED INDEX IX_Dim_Date_Date 
    ON Dim_Date(Date);

CREATE NONCLUSTERED INDEX IX_Dim_Date_FiscalYear_Month 
    ON Dim_Date(FiscalYear, Month)
    INCLUDE (Quarter, MonthName);


DECLARE @StartDate DATE = '2024-01-01';
DECLARE @EndDate DATE = '2024-10-11';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO Dim_Date (DateKey, Date, Year, Quarter, Month, MonthName, Week, DayOfWeek, DayName, IsWeekend, FiscalYear)
    VALUES (
        CONVERT(INT, FORMAT(@StartDate, 'yyyyMMdd')),
        @StartDate,
        YEAR(@StartDate),
        DATEPART(QUARTER, @StartDate),
        MONTH(@StartDate),
        DATENAME(MONTH, @StartDate),
        DATEPART(WEEK, @StartDate),
        DATEPART(WEEKDAY, @StartDate),
        DATENAME(WEEKDAY, @StartDate),
        CASE WHEN DATEPART(WEEKDAY, @StartDate) IN (1, 7) THEN 1 ELSE 0 END,  -- 1=Sunday, 7=Saturday
        YEAR(@StartDate)  -- Assuming fiscal year aligns with calendar year
    );
    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;

-- Store Dimension
CREATE TABLE Dim_Store
(
    StoreKey INT PRIMARY KEY IDENTITY(1,1),
    StoreID INT NOT NULL,
    StoreName NVARCHAR(100) NOT NULL,
    Location NVARCHAR(255) NOT NULL,
    ValidFrom DATETIME2 NOT NULL,
    ValidTo DATETIME2 NULL,
    IsCurrent BIT NOT NULL
);

CREATE NONCLUSTERED INDEX IX_Dim_Store_StoreID 
    ON Dim_Store(StoreID, IsCurrent)
    INCLUDE (StoreName, Location);

CREATE NONCLUSTERED INDEX IX_Dim_Store_Location 
    ON Dim_Store(Location)
    INCLUDE (StoreName)
    WHERE IsCurrent = 1;

-- Product Category Dimension
CREATE TABLE Dim_ProductCategory
(
    CategoryKey INT PRIMARY KEY IDENTITY(1,1),
    CategoryID INT NOT NULL,
    CategoryName NVARCHAR(100) NOT NULL,
    ValidFrom DATETIME2 NOT NULL,
    ValidTo DATETIME2 NULL,
    IsCurrent BIT NOT NULL
);

CREATE NONCLUSTERED INDEX IX_Dim_ProductCategory_CategoryID 
    ON Dim_ProductCategory(CategoryID, IsCurrent)
    INCLUDE (CategoryName);

-- Supplier Dimension
CREATE TABLE Dim_Supplier
(
    SupplierKey INT PRIMARY KEY IDENTITY(1,1),
    SupplierID INT NOT NULL,
    SupplierName NVARCHAR(100) NOT NULL,
    ContactInfo NVARCHAR(255) NOT NULL,
    ValidFrom DATETIME2 NOT NULL,
    ValidTo DATETIME2 NULL,
    IsCurrent BIT NOT NULL
);

CREATE NONCLUSTERED INDEX IX_Dim_Supplier_SupplierID 
    ON Dim_Supplier(SupplierID, IsCurrent)
    INCLUDE (SupplierName);

-- Product Dimension
CREATE TABLE Dim_Product
(
    ProductKey INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT NOT NULL,
    ProductName NVARCHAR(100) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    CategoryKey INT NOT NULL,
    SupplierKey INT NOT NULL,
    ValidFrom DATETIME2 NOT NULL,
    ValidTo DATETIME2 NULL,
    IsCurrent BIT NOT NULL,
    FOREIGN KEY (CategoryKey) REFERENCES Dim_ProductCategory(CategoryKey),
    FOREIGN KEY (SupplierKey) REFERENCES Dim_Supplier(SupplierKey)
);

CREATE NONCLUSTERED INDEX IX_Dim_Product_ProductID 
    ON Dim_Product(ProductID, IsCurrent)
    INCLUDE (ProductName, Price);

CREATE NONCLUSTERED INDEX IX_Dim_Product_CategoryKey 
    ON Dim_Product(CategoryKey)
    INCLUDE (ProductName, Price)
    WHERE IsCurrent = 1;

CREATE NONCLUSTERED INDEX IX_Dim_Product_Price 
    ON Dim_Product(Price)
    INCLUDE (ProductName)
    WHERE IsCurrent = 1;

-- Customer Dimension
CREATE TABLE Dim_Customer
(
    CustomerKey INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    CustomerName NVARCHAR(100) NOT NULL,
    ContactInfo NVARCHAR(255) NOT NULL,
    ValidFrom DATETIME2 NOT NULL,
    ValidTo DATETIME2 NULL,
    IsCurrent BIT NOT NULL
);

CREATE NONCLUSTERED INDEX IX_Dim_Customer_CustomerID 
    ON Dim_Customer(CustomerID, IsCurrent)
    INCLUDE (CustomerName);

-- Weather Dimension
CREATE TABLE Dim_Weather
(
    WeatherKey INT PRIMARY KEY IDENTITY(1,1),
    Location NVARCHAR(255) NOT NULL,
    Latitude DECIMAL(9,6) NOT NULL,
    Longitude DECIMAL(9,6) NOT NULL,
    Temperature DECIMAL(5,2) NOT NULL,
    WindSpeed DECIMAL(5,2) NOT NULL,
    Description NVARCHAR(255) NOT NULL,
    ValidFrom DATETIME2 NOT NULL,
    ValidTo DATETIME2 NULL,
    IsCurrent BIT NOT NULL
);

CREATE NONCLUSTERED INDEX IX_Dim_Weather_Location 
    ON Dim_Weather(Location, ValidFrom)
    INCLUDE (Temperature, WindSpeed, Description);

-- Junk Dimension for Discount Attributes
CREATE TABLE Dim_DiscountType
(
    DiscountTypeKey INT PRIMARY KEY IDENTITY(1,1),
    DiscountPercentageRange NVARCHAR(50) NOT NULL,
    DiscountSeason NVARCHAR(50) NOT NULL
);

CREATE NONCLUSTERED INDEX IX_Dim_DiscountType_Season 
    ON Dim_DiscountType(DiscountSeason)
    INCLUDE (DiscountPercentageRange);

-- Fact Table: Sales
CREATE TABLE Fact_Sales
(
    SalesKey BIGINT IDENTITY(1,1) not null,
    DateKey INT NOT NULL,
    StoreKey INT NOT NULL,
    ProductKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    WeatherKey INT NOT NULL,
    DiscountTypeKey INT NULL,
    SalesID INT NOT NULL,
    QuantitySold INT NOT NULL,
    TotalPrice DECIMAL(10, 2) NOT NULL,
    UnitPrice DECIMAL(10, 2) NOT NULL,
    DiscountAmount DECIMAL(10, 2) NULL,
	PRIMARY KEY CLUSTERED (SalesKey, DateKey) ON PS_Monthly(DateKey),
    FOREIGN KEY (DateKey) REFERENCES Dim_Date(DateKey),
    FOREIGN KEY (StoreKey) REFERENCES Dim_Store(StoreKey),
    FOREIGN KEY (ProductKey) REFERENCES Dim_Product(ProductKey),
    FOREIGN KEY (CustomerKey) REFERENCES Dim_Customer(CustomerKey),
    FOREIGN KEY (WeatherKey) REFERENCES Dim_Weather(WeatherKey),
    FOREIGN KEY (DiscountTypeKey) REFERENCES Dim_DiscountType(DiscountTypeKey),
) ON PS_Monthly(DateKey);

CREATE CLUSTERED COLUMNSTORE INDEX CCI_Sales 
    ON Fact_Sales
    ON PS_Monthly(DateKey);

CREATE NONCLUSTERED INDEX IX_Fact_Sales_DateKey 
    ON Fact_Sales(DateKey)
    INCLUDE (StoreKey, ProductKey, QuantitySold, TotalPrice)
    ON PS_Monthly(DateKey);

CREATE NONCLUSTERED INDEX IX_Fact_Sales_StoreProduct 
    ON Fact_Sales(StoreKey, ProductKey, DateKey)
    INCLUDE (QuantitySold, TotalPrice)
    ON PS_Monthly(DateKey);

-- Fact Table: Inventory
CREATE TABLE Fact_Inventory
(
    InventoryKey BIGINT IDENTITY(1,1),
    DateKey INT NOT NULL,
    StoreKey INT NOT NULL,
    ProductKey INT NOT NULL,
    StockLevel INT NOT NULL,
    ReorderLevel INT NOT NULL,
    DaysOfSupply INT NULL,
	PRIMARY KEY CLUSTERED (InventoryKey, DateKey) ON PS_Monthly(DateKey),
    FOREIGN KEY (DateKey) REFERENCES Dim_Date(DateKey),
    FOREIGN KEY (StoreKey) REFERENCES Dim_Store(StoreKey),
    FOREIGN KEY (ProductKey) REFERENCES Dim_Product(ProductKey)
) ON PS_Monthly(DateKey);

CREATE CLUSTERED COLUMNSTORE INDEX CCI_Inventory 
    ON Fact_Inventory
    ON PS_Monthly(DateKey);

CREATE NONCLUSTERED INDEX IX_Fact_Inventory_StoreProduct 
    ON Fact_Inventory(StoreKey, ProductKey, DateKey)
    INCLUDE (StockLevel, ReorderLevel)
    ON PS_Monthly(DateKey);

-- Statistics
CREATE STATISTICS ST_Sales_DateStore 
    ON Fact_Sales(DateKey, StoreKey);

CREATE STATISTICS ST_Sales_DateProduct 
    ON Fact_Sales(DateKey, ProductKey);

CREATE STATISTICS ST_Inventory_DateStore 
    ON Fact_Inventory(DateKey, StoreKey);

-- Disable automatic statistics updates for fact tables
ALTER DATABASE ProductManagementDW
SET AUTO_UPDATE_STATISTICS OFF;
go
-- Create a stored procedure for statistics maintenance
CREATE OR ALTER PROCEDURE dbo.UpdateDWStatistics
AS
BEGIN
    UPDATE STATISTICS Fact_Sales WITH FULLSCAN;
    UPDATE STATISTICS Fact_Inventory WITH FULLSCAN;
END;
GO
