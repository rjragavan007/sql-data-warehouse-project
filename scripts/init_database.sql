/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouse' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.
	
WARNING:
    Running this script will drop the entire 'DataWarehouse' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
--check if database named DataWarehouse exists and drops if it exists for the purpose of recreation
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;

GO
-- GO=> Act as separator
  
--creation of database warehouse
CREATE DATABASE DataWarehouse;
USE DataWarehouse;

--creation of schemas for 3 different layers
GO
--create bronze layer
create schema bronze;
GO
--create silver layer
create schema silver;
GO
--create gold layer
create schema gold;
