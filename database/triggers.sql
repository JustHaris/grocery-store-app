-- ==========================================================
-- Database Administration and Management (DAM) Project
-- File: triggers.sql
-- Description: Triggers for stock management and data integrity
-- ==========================================================

-- 1. Trigger: trg_AutoUpdateStock
-- Automatically deducts stock when an order is placed.
IF OBJECT_ID('trg_AutoUpdateStock', 'TR') IS NOT NULL
    DROP TRIGGER trg_AutoUpdateStock;
GO

/* 
-- DISABLED: Stock management is now handled by Flask backend within atomic transactions
-- to ensure consistent user feedback and prevent double deduction.
-- This trigger remains here for documentation of DAM concepts.

CREATE TRIGGER trg_AutoUpdateStock
ON OrderItems
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.Stock = p.Stock - i.Quantity
    FROM Products p
    JOIN inserted i ON p.ProductID = i.ProductID;
END;
*/
GO

-- 2. Trigger: trg_PreventNegativeStock
-- Safety net to ensure stock never falls below 0.
IF OBJECT_ID('trg_PreventNegativeStock', 'TR') IS NOT NULL
    DROP TRIGGER trg_PreventNegativeStock;
GO

CREATE TRIGGER trg_PreventNegativeStock
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted WHERE Stock < 0)
    BEGIN
        RAISERROR ('Insufficient stock. Transaction cancelled to prevent negative inventory.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
