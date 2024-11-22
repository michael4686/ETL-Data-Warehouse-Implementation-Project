CREATE DATABASE ProductManagement1;

USE ProductManagement1;

CREATE TABLE Store (
    StoreID INT PRIMARY KEY IDENTITY(1,1),
    StoreName NVARCHAR(100) NOT NULL,
    Location NVARCHAR(255)
);

CREATE TABLE ProductCategory (
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL
);

CREATE TABLE Supplier (
    SupplierID INT PRIMARY KEY IDENTITY(1,1),
    SupplierName NVARCHAR(100) NOT NULL,
    ContactInfo NVARCHAR(255)
);

CREATE TABLE Product (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100) NOT NULL,
    Price DECIMAL(10, 2),
    CategoryID INT,
    SupplierID INT,
    FOREIGN KEY (CategoryID) REFERENCES ProductCategory(CategoryID),
    FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID)
);

CREATE TABLE Inventory (
    InventoryID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT,
    StoreID INT,
    StockLevel INT,
    ReorderLevel INT,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    FOREIGN KEY (StoreID) REFERENCES Store(StoreID)
);

CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    CustomerName NVARCHAR(100) NOT NULL,
    ContactInfo NVARCHAR(255)
);

CREATE TABLE Discounts (
    DiscountID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT,
    DiscountPercentage DECIMAL(5, 2), -- Example: 10.00 for 10% discount
    StartDate DATE,
    EndDate DATE,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);


CREATE TABLE Sales (
    SalesID INT PRIMARY KEY IDENTITY(1,1),
	StoreID INT NOT NULL,
    SaleDate DATE NOT NULL DEFAULT GETDATE(),
    ProductID INT NOT NULL,
    QuantitySold INT NOT NULL,
    CustomerID INT,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);