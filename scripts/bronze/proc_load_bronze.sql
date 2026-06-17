/*
========================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
========================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the 'BULK INSERT' command to load data from csv Files to bronze tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
========================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME,@end_time DATETIME,@bronze_start_time DATETIME,@bronze_end_time DATETIME;
	BEGIN TRY
		SET @bronze_start_time=GETDATE();
		----------------
		PRINT'=========================';
		PRINT'Loading from CRM Sources';
		PRINT'=========================';
		PRINT'FULL LOAD-bronze.crm_cust_info';
		PRINT '----------------------------'
		SET @start_time=GETDATE();
		TRUNCATE TABLE bronze.crm_cust_info;
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\rjrag\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			--to determine first row of the file
			FIRSTROW=2,
			--to determine the separator
			FIELDTERMINATOR=',',
			--locking entire table while loading 
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT '>>Load duration: '+CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+' seconds';
		PRINT '----------------------------'
		-----------------------------
		PRINT'FULL LOAD-bronze.crm_prd_info';
		PRINT '----------------------------'
		SET @start_time=GETDATE();
		TRUNCATE TABLE bronze.crm_prd_info;
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\rjrag\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT '>>Load duration: '+CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+' seconds';
		PRINT '----------------------------'
		---------------------------------
		PRINT'FULL LOAD-bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT '----------------------------'
		SET @start_time=GETDATE();
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\rjrag\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT '>>Load duration: '+CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+' seconds';
		PRINT '----------------------------'
		---------------------------------------
		PRINT'=========================';
		PRINT'Loading from ERP Sources';
		PRINT'=========================';
		PRINT'FULL LOAD-bronze.erp_cust_az12';
		PRINT '----------------------------'
		SET @start_time=GETDATE();
		TRUNCATE TABLE bronze.erp_cust_az12;
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\rjrag\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT '>>Load duration: '+CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+' seconds';
		PRINT '----------------------------'
		---------------------------------------
		PRINT'FULL LOAD-bronze.erp_loc_a101';
		PRINT '----------------------------'
		SET @start_time=GETDATE();
		TRUNCATE TABLE bronze.erp_loc_a101;
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\rjrag\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT '>>Load duration: '+CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+' seconds';
		PRINT '----------------------------'
		-------------------------------------
		PRINT'FULL LOAD-bronze.erp_px_cat_g1v2'
		PRINT '----------------------------'
		SET @start_time=GETDATE();
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\rjrag\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT '>>Load duration: '+CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+' seconds';
		PRINT '----------------------------'
		SET @bronze_end_time=GETDATE();
		PRINT'LOADING BRONZE LAYER IS COMPLETED'
		PRINT '>>> Bronze Layer Loading duration: '+CAST(DATEDIFF(second,@bronze_start_time,@bronze_end_time) AS NVARCHAR)+' seconds';
	END TRY
	BEGIN CATCH
		PRINT'==========================================='
		PRINT'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT'Error message: '+ERROR_MESSAGE();
		PRINT'Error line: '+ERROR_LINE();
		PRINT'Error number: '+CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT'Error state: '+CAST(ERROR_STATE() AS NVARCHAR);
		PRINT'==========================================='
	END CATCH
END

--EXEC bronze.load_bronze
