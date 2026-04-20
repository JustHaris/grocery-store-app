-- ==========================================================
-- Database Administration and Management (DAM) Project
-- File: admin_scripts.sql
-- Description: RBAC setup and Backup/Restore scripts
-- ==========================================================

-- ==========================================
-- 1. Role-Based Access Control (RBAC)
-- ==========================================

-- Note: The following requires a running SQL Server with Mixed Mode Authentication or Windows Auth.
-- To test, uncomment and replace placeholders with actual database name.

-- Create Server Logins
-- CREATE LOGIN GroceryAdmin WITH PASSWORD = 'StrongPassword123!';
-- CREATE LOGIN GroceryManager WITH PASSWORD = 'StrongPassword123!';
-- CREATE LOGIN GroceryCustomer WITH PASSWORD = 'StrongPassword123!';

-- USE GroceryStore;
-- GO

-- Create Database Users linked to Logins
-- CREATE USER DB_Admin FOR LOGIN GroceryAdmin;
-- CREATE USER DB_Manager FOR LOGIN GroceryManager;
-- CREATE USER DB_Customer FOR LOGIN GroceryCustomer;

-- Create Database Roles
-- CREATE ROLE AppAdminRole;
-- CREATE ROLE AppManagerRole;
-- CREATE ROLE AppCustomerRole;

-- Assign Users to Roles
-- ALTER ROLE AppAdminRole ADD MEMBER DB_Admin;
-- ALTER ROLE AppManagerRole ADD MEMBER DB_Manager;
-- ALTER ROLE AppCustomerRole ADD MEMBER DB_Customer;

-- Grant Permissions
-- Admin gets full control
-- GRANT CONTROL ON DATABASE::GroceryStore TO AppAdminRole;

-- Manager gets reporting and view access
-- GRANT SELECT ON vw_SalesReport TO AppManagerRole;
-- GRANT SELECT ON vw_ProductInventory TO AppManagerRole;
-- GRANT EXECUTE ON OBJECT::GetSalesReport TO AppManagerRole;

-- Customer gets access to products, their own orders, and checkout procedure
-- GRANT SELECT ON Products TO AppCustomerRole;
-- GRANT SELECT ON Categories TO AppCustomerRole;
-- GRANT EXECUTE ON OBJECT::PlaceOrder TO AppCustomerRole;


-- ==========================================
-- 2. Database Backup & Recovery Scripts
-- ==========================================

-- FULL DATABASE BACKUP
/*
BACKUP DATABASE GroceryStore
TO DISK = 'C:\SQLBackups\GroceryStore_Full.bak'
WITH FORMAT, 
     MEDIANAME = 'GroceryStore_Backups',
     NAME = 'Full Backup of GroceryStore';
GO
*/

-- DIFFERENTIAL DATABASE BACKUP (Faster, captures changes since last full backup)
/*
BACKUP DATABASE GroceryStore
TO DISK = 'C:\SQLBackups\GroceryStore_Diff.bak'
WITH DIFFERENTIAL,
     NAME = 'Differential Backup of GroceryStore';
GO
*/

-- TRANSACTION LOG BACKUP (Point-in-time recovery)
/*
BACKUP LOG GroceryStore
TO DISK = 'C:\SQLBackups\GroceryStore_Log.trn'
WITH NAME = 'Transaction Log Backup of GroceryStore';
GO
*/

-- RESTORE DATABASE FROM BACKUP
/*
-- 1. Put database in single user mode to drop active connections
ALTER DATABASE GroceryStore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

-- 2. Restore full backup
RESTORE DATABASE GroceryStore
FROM DISK = 'C:\SQLBackups\GroceryStore_Full.bak'
WITH NORECOVERY, REPLACE; -- NORECOVERY allows applying diff/log backups next

-- 3. Restore differential backup
RESTORE DATABASE GroceryStore
FROM DISK = 'C:\SQLBackups\GroceryStore_Diff.bak'
WITH NORECOVERY;

-- 4. Restore log backup and bring database online
RESTORE LOG GroceryStore
FROM DISK = 'C:\SQLBackups\GroceryStore_Log.trn'
WITH RECOVERY;

-- 5. Put database back to multi-user mode
ALTER DATABASE GroceryStore SET MULTI_USER;
*/
