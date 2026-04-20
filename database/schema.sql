-- ==========================================================
-- Database Administration and Management (DAM) Project
-- Grocery Store Management System - Full Schema
-- File: schema.sql
-- Description: Sets up the full database structure and seed data.
-- ==========================================================

-- 1. Drop existing tables in reverse order of dependencies
IF OBJECT_ID('Wishlist', 'U') IS NOT NULL DROP TABLE Wishlist;
IF OBJECT_ID('OrderItems', 'U') IS NOT NULL DROP TABLE OrderItems;
IF OBJECT_ID('Orders', 'U') IS NOT NULL DROP TABLE Orders;
IF OBJECT_ID('Products', 'U') IS NOT NULL DROP TABLE Products;
IF OBJECT_ID('Categories', 'U') IS NOT NULL DROP TABLE Categories;
IF OBJECT_ID('Suppliers', 'U') IS NOT NULL DROP TABLE Suppliers;
IF OBJECT_ID('Users', 'U') IS NOT NULL DROP TABLE Users;

-- 2. Create Tables

-- USERS TABLE: Stores authentication and role data
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username VARCHAR(50) NOT NULL UNIQUE,
    Email VARCHAR(100) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    Role VARCHAR(20) DEFAULT 'Customer' CHECK (Role IN ('Customer', 'Admin')),
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- CATEGORIES TABLE: Product classification
CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    Name VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT,
    ImageUrl VARCHAR(255)
);

-- PRODUCTS TABLE: Catalog details
CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    Name VARCHAR(150) NOT NULL,
    Description TEXT,
    Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    Stock INT NOT NULL DEFAULT 0 CHECK (Stock >= 0),
    CategoryID INT,
    ImageUrl VARCHAR(255),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID) ON DELETE SET NULL
);

-- ORDERS TABLE: Transaction headers
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT,
    OrderDate DATETIME DEFAULT GETDATE(),
    Status VARCHAR(20) DEFAULT 'Processing' CHECK (Status IN ('Processing', 'Completed', 'Cancelled', 'Delivered')),
    TotalAmount DECIMAL(10,2) DEFAULT 0,
    CONSTRAINT FK_Orders_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);

-- ORDER ITEMS TABLE: Transaction details (Atomic units)
CREATE TABLE OrderItems (
    OrderItemID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT,
    ProductID INT,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0), -- Price captured at time of purchase
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItems_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE NO ACTION
);

-- WISHLIST TABLE: Customer favorites
CREATE TABLE Wishlist (
    WishlistID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT,
    ProductID INT,
    CONSTRAINT FK_Wishlist_Users FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    CONSTRAINT FK_Wishlist_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE,
    CONSTRAINT UQ_User_Product UNIQUE(UserID, ProductID)
);

-- SUPPLIERS TABLE: Procurement partners
CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY IDENTITY(1,1),
    Name VARCHAR(100) NOT NULL,
    ContactPerson VARCHAR(100),
    Category VARCHAR(50),
    Email VARCHAR(100),
    Phone VARCHAR(20),
    Address TEXT
);

-- 3. Performance Indexes
CREATE NONCLUSTERED INDEX IX_Products_Name ON Products(Name);
CREATE NONCLUSTERED INDEX IX_Products_CategoryID ON Products(CategoryID);
CREATE NONCLUSTERED INDEX IX_Orders_UserID ON Orders(UserID);
CREATE NONCLUSTERED INDEX IX_OrderItems_OrderID ON OrderItems(OrderID);

-- 4. Initial Seed Data

-- INSERT ADMIN (Password: admin123)
-- Uses Werkzeug scrypt hash for Flask compatibility
INSERT INTO Users (Username, Email, PasswordHash, Role)
VALUES ('Admin', 'admin@gmail.com', 'scrypt:32768:8:1$NRl8Sx0YWWjI9TbB$d12ef0acf66feb9e7be15db3fd06d2cfff1df9c502f201575cb372810b11b5c597355b78f25c66f8e63a45fff2cd64571725b0e0f98b28ea54f24797f5aba62f', 'Admin');

-- INSERT CATEGORIES
INSERT INTO Categories (Name, Description, ImageUrl) VALUES
('Fruits & Vegetables', 'Fresh and organic produce', 'fruits_vegetables.jpg'),
('Bakery', 'Breads and baked goods', 'bakery.jpg'),
('Dairy & Breakfast', 'Milk and eggs', 'dairy.jpg'),
('Meat & Poultry', 'Fresh meat products', 'meat.jpg'),
('Snacks & Biscuits', 'Chips and snacks', 'chips.jpg'),
('Oils & Ghee', 'Cooking oils', 'oil.jpg'),
('Pulses & Masala', 'Spices and pulses', 'lentils.jpg'),
('Beverages', 'Juices and sodas', 'beverages.jpg');

-- INSERT PRODUCTS
INSERT INTO Products (Name, Price, Stock, CategoryID, ImageUrl, Description) VALUES
('Fresh Apples', 490.00, 40, 1, 'apple.jpg', 'Premium quality red apples.'),
('Whole Wheat Bread', 150.00, 30, 2, 'Bread.jpg', 'Healthy whole grain bread.'),
('Organic Milk', 220.00, 100, 3, 'milk.jpg', 'Pure organic farm milk.'),
('Chicken Breast', 1250.00, 40, 4, 'chicken.jpg', 'Freshly cut chicken breast.'),
('Salted Chips 150G', 200.00, 75, 5, 'chips.jpg', 'Crispy and lightly salted.'),
('Sunflower Oil', 1200.00, 60, 6, 'oil.jpg', 'Healthy cooking sunflower oil.'),
('Daal Masoor 500G', 250.00, 80, 7, 'lentils.jpg', 'High protein red lentils.'),
('Orange Juice', 340.00, 70, 8, 'juice.jpg', 'Freshly squeezed orange juice.'),
('Almond Milk (1L)', 1200.00, 20, 3, 'almond_milk.jpg', 'Dairy-free almond milk.'),
('Camel Milk (1L)', 400.00, 25, 3, 'camel_milk.jpg', 'Rich and nutritious camel milk.'),
('Cashew Milk (1L)', 1800.00, 50, 3, 'cashew_milk.jpg', 'Creamy cashew milk.'),
('Coconut Milk (1L)', 800.00, 40, 3, 'coconut_milk.jpg', 'Natural coconut milk.'),
('Goat Milk (1L)', 400.00, 30, 3, 'goat_milk.jpg', 'Fresh goat milk.'),
('Oat Milk (1L)', 1000.00, 35, 3, 'oat_milk.jpg', 'Heart-healthy oat milk.'),
('Pistachio Milk (1L)', 2500.00, 50, 3, 'pistachio_milk.jpg', 'Premium pistachio milk.'),
('Soy Milk (1L)', 1000.00, 50, 3, 'soy_milk.jpg', 'Plant-based soy milk.'),
('Seasons Canola Oil (3L)', 1745.00, 60, 6, 'seasons_canola.jpg', 'Refined canola oil.'),
('Sufi Canola Oil (3L)', 1745.00, 55, 6, 'sufi_canola.jpg', 'High quality canola oil.'),
('Sufi Sunflower Oil (3L)', 1845.00, 45, 6, 'sufi_sunflower.jpg', 'Pure sunflower cooking oil.'),
('Canolive Canola Oil (1L)', 656.00, 50, 6, 'canolive_canola_1ltr.jpg', 'Canola oil with olive oil extract.'),
('Naturelle Organic Oil (3L)', 1765.00, 30, 6, 'naturelle_organic.jpg', 'Certified organic cooking oil.'),
('Soya Supreme Oil (3L)', 1845.00, 40, 6, 'soya_supreme_3ltr.jpg', 'Premium soy-based cooking oil.');

-- Final Status
SELECT 'Database creation and seeding complete.' AS Status;
SELECT * FROM Categories;
SELECT * FROM Products;
SELECT UserID, Username, Role FROM Users;
GO


SELECT UserID, Username, Email, Role FROM Users WHERE Role = 'Admin';