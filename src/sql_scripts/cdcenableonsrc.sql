-- Step 1: Enable Change Data Capture on the Source Database
USE ProductManagement1;

EXEC sys.sp_cdc_enable_db;

-- Step 2: Enable CDC on All Tables Except Store and Supplier and ProductCategory
EXEC sys.sp_cdc_enable_table 
    @source_schema = N'dbo',  -- Adjust if the schema is different
    @source_name = N'Customer',
    @role_name = NULL;  -- NULL for all users

EXEC sys.sp_cdc_enable_table 
    @source_schema = N'dbo',
    @source_name = N'Product',
    @role_name = NULL;

EXEC sys.sp_cdc_enable_table 
    @source_schema = N'dbo',
    @source_name = N'Inventory',
    @role_name = NULL;

EXEC sys.sp_cdc_enable_table 
    @source_schema = N'dbo',
    @source_name = N'Discounts',
    @role_name = NULL;

EXEC sys.sp_cdc_enable_table 
    @source_schema = N'dbo',
    @source_name = N'Sales',
    @role_name = NULL;

-- Note: Make sure your SQL Server version supports CDC and the database is in full recovery model.
