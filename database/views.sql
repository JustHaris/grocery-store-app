-- ==========================================================
-- Database Administration and Management (DAM) Project
-- File: views.sql
-- Description: Views for reporting and data aggregation
-- ==========================================================

-- 1. View: vw_SalesReport
-- Provides a clean, aggregated look at total sales data per order
IF OBJECT_ID('vw_SalesReport', 'V') IS NOT NULL
    DROP VIEW vw_SalesReport;
GO

CREATE VIEW vw_SalesReport
AS
SELECT 
    o.OrderID,
    o.OrderDate,
    u.Username AS Customer,
    COUNT(oi.OrderItemID) AS ItemCount,
    SUM(oi.Quantity) AS TotalQuantity,
    o.TotalAmount
FROM Orders o
JOIN Users u ON o.UserID = u.UserID
JOIN OrderItems oi ON o.OrderID = oi.OrderID
WHERE o.Status = 'Completed'
GROUP BY o.OrderID, o.OrderDate, u.Username, o.TotalAmount;
GO

-- 2. View: vw_ProductInventory
-- Quick dashboard view of current products, their categories, and stock alerts
IF OBJECT_ID('vw_ProductInventory', 'V') IS NOT NULL
    DROP VIEW vw_ProductInventory;
GO

CREATE VIEW vw_ProductInventory
AS
SELECT 
    p.ProductID,
    p.Name AS Product,
    c.Name AS Category,
    p.Price,
    p.Stock,
    CASE 
        WHEN p.Stock = 0 THEN 'Out of Stock'
        WHEN p.Stock < 20 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS StockStatus
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID;
GO
