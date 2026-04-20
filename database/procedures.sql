-- ==========================================================
-- Database Administration and Management (DAM) Project
-- File: procedures.sql
-- Description: Stored procedures for transactional logic and reporting
-- ==========================================================

-- 1. Stored Procedure: PlaceOrder (Simplified for SSMS Testing)
-- This procedure handles a single item order and manages stock.
IF OBJECT_ID('PlaceOrder', 'P') IS NOT NULL
    DROP PROCEDURE PlaceOrder;
GO

CREATE PROCEDURE PlaceOrder
    @UserID INT,
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Price DECIMAL(10,2);
        DECLARE @Stock INT;
        DECLARE @OrderID INT;

        -- Get current product price and stock levels
        SELECT @Price = Price, @Stock = Stock
        FROM Products
        WHERE ProductID = @ProductID;

        -- Validate stock availability
        IF @Stock < @Quantity
        BEGIN
            RAISERROR('Insufficient inventory for this request.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert order header
        INSERT INTO Orders(UserID, Status, TotalAmount, OrderDate)
        VALUES(@UserID, 'Completed', @Price * @Quantity, GETDATE());

        SET @OrderID = SCOPE_IDENTITY();

        -- Insert order item
        INSERT INTO OrderItems(OrderID, ProductID, Quantity, Price)
        VALUES(@OrderID, @ProductID, @Quantity, @Price);

        -- Atomic Stock Deduction (Handled in Flask also, but kept here for DB-level logic)
        UPDATE Products
        SET Stock = Stock - @Quantity
        WHERE ProductID = @ProductID;

        COMMIT TRANSACTION;
        PRINT 'Order #'+ CAST(@OrderID AS VARCHAR) + ' placed successfully.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO


-- 2. Stored Procedure: PlaceOrderJSON (For Flask Integration)
-- Handles multiple items in a single transaction using JSON input.
IF OBJECT_ID('PlaceOrderJSON', 'P') IS NOT NULL
    DROP PROCEDURE PlaceOrderJSON;
GO

CREATE PROCEDURE PlaceOrderJSON
    @UserId INT,
    @ItemsJSON NVARCHAR(MAX), -- Format: '[{"product_id": 1, "quantity": 2, "price": 3.99}, ...]'
    @TotalAmount DECIMAL(12, 2),
    @NewOrderId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Create Order Header
        INSERT INTO Orders (UserID, TotalAmount, Status, OrderDate)
        VALUES (@UserId, @TotalAmount, 'Completed', GETDATE());

        SET @NewOrderId = SCOPE_IDENTITY();

        -- Bulk Insert Order Items from JSON
        INSERT INTO OrderItems (OrderID, ProductID, Quantity, Price)
        SELECT 
            @NewOrderId,
            product_id,
            quantity,
            price
        FROM OPENJSON(@ItemsJSON)
        WITH (
            product_id INT '$.product_id',
            quantity INT '$.quantity',
            price DECIMAL(10, 2) '$.price'
        );

        -- Note: Stock update is handled by Flask route logic for better user feedback,
        -- but can be added here if full DB-side logic is preferred.

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW; 
    END CATCH
END;
GO


-- 3. Stored Procedure: GetSalesReport
-- Generates analytics for a specific date range
IF OBJECT_ID('GetSalesReport', 'P') IS NOT NULL
    DROP PROCEDURE GetSalesReport;
GO

CREATE PROCEDURE GetSalesReport
    @StartDate DATETIME,
    @EndDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        o.OrderDate,
        o.OrderID,
        u.Username AS Customer,
        p.Name AS Product,
        c.Name AS Category,
        oi.Quantity,
        oi.Price AS UnitPrice,
        (oi.Quantity * oi.Price) AS TotalPrice
    FROM Orders o
    JOIN OrderItems oi ON o.OrderID = oi.OrderID
    JOIN Products p ON oi.ProductID = p.ProductID
    JOIN Categories c ON p.CategoryID = c.CategoryID
    JOIN Users u ON o.UserID = u.UserID
    WHERE o.OrderDate >= @StartDate 
      AND o.OrderDate <= @EndDate
      AND o.Status = 'Completed'
    ORDER BY o.OrderDate DESC;
END;
GO
