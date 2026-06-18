/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
Action Performed:
    - Truncates Silver tables.
    - Inserts transformed and cleansed data from Bronze into Silver tables.
    
Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME,@end_time DATETIME,@silver_st DATETIME,@silver_et DATETIME;
    BEGIN TRY
        SET @silver_st=GETDATE();
        
        PRINT'LOADING SILVER LAYER....';
        PRINT'=========================';
        PRINT'LOADING CRM TABLES.....'
        PRINT'=========================';
        PRINT'---------------------------------------'
        SET @start_time=GETDATE();
        PRINT 'Truncating table: silver.crm_cust_info'
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT 'Inserting into table: silver.crm_cust_info'
        Insert into silver.crm_cust_info
        (	cst_id,
	        cst_key,
	        cst_firstname,
	        cst_lastname,
	        cst_marital_status,
	        cst_gndr,
	        cst_create_date)
        select
        cst_id,
        cst_key,
        TRIM(cst_firstname) AS cst_firstname,
        TRIM(cst_lastname) AS cst_lastname,
        CASE
        WHEN TRIM(UPPER(cst_marital_status))='S' THEN  'Single'
        WHEN TRIM(UPPER(cst_marital_status))='M' THEN  'Married'
        ELSE 'n/a'
        END AS cst_marital_status,
        CASE
        WHEN TRIM(UPPER(cst_gndr))='F' THEN 'Female'
        WHEN TRIM(UPPER(cst_gndr))='M' THEN 'Male'
        ELSE 'n/a'
        END AS cst_gndr,
        cst_create_date
        from(
        select
        *,
        --rank based on latest date of creation ie cst_create_date
        ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
        from bronze.crm_cust_info
        --where cst_id=29466
        ) t
        where flag_last=1 and cst_id is not null;
        SET @end_time=GETDATE()
        PRINT 'Load duartion: '+CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR)+' seconds';
        PRINT'---------------------------------------'
        SET @start_time=GETDATE();
        PRINT 'Truncating table: silver.crm_prd_info'
        TRUNCATE TABLE silver.crm_prd_info;
        PRINT 'Inserting into table: silver.crm_prd_info'
        INSERT INTO silver.crm_prd_info(
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
            )
        SELECT
        prd_id,
        --derived columns
        REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
        SUBSTRING(prd_key,7,LEN(prd_key)) as prd_key,
        prd_nm,
        --replace nulls using ISNULL AND CASE
        ISNULL(prd_cost,0) as prd_cost,
        CASE UPPER(TRIM(prd_line))
        --data normalization
        WHEN 'M' THEN 'Mountains'
        WHEN 'R' THEN 'Roads'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a' 
        END AS prd_line,
        --data type changing=casting
        CAST(prd_start_dt AS DATE) prd_start_dt,
        --casting+data enrichment
        CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) prd_end_dt
        FROM bronze.crm_prd_info;
        SET @end_time=GETDATE()
        PRINT 'Load duartion: '+CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR)+' seconds';
        PRINT'---------------------------------------'
        SET @start_time=GETDATE();
        PRINT 'Truncating table: silver.crm_sales_details'
        TRUNCATE TABLE silver.crm_sales_details;
        PRINT 'Inserting into table: silver.crm_sales_details'
        INSERT INTO silver.crm_sales_details
        (	sls_ord_num,sls_prd_key,sls_cust_id,
	        sls_order_dt,sls_ship_dt,sls_due_dt,
	        sls_sales,sls_quantity,sls_price
        )
        SELECT 
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE
        WHEN (sls_order_dt<=0 OR LEN(sls_order_dt)!=8) THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
        END AS sls_order_dt,
        CASE
        WHEN (sls_ship_dt<=0 OR LEN(sls_ship_dt)!=8) THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
        END AS sls_ship_dt,
        CASE
        WHEN (sls_due_dt<=0 OR LEN(sls_due_dt)!=8) THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
        END AS sls_due_dt,
        CASE
        WHEN sls_sales<=0 or sls_sales!=ABS(sls_price)*sls_quantity 
        or sls_sales is null 
        THEN ABS(sls_price)*sls_quantity
        ELSE sls_sales
        END as sls_sales,
        sls_quantity,
        CASE
        WHEN sls_price<=0 or sls_price is null
        THEN sls_sales/NULLIF(sls_quantity,0)
        ELSE sls_price
        END as sls_price
        FROM bronze.crm_sales_details;
        SET @end_time=GETDATE()
        PRINT 'Load duartion: '+CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR)+' seconds';
        PRINT'=========================';
        PRINT'LOADING ERP TABLES.....'
        PRINT'=========================';
        PRINT'---------------------------------------'
        SET @start_time=GETDATE();
        PRINT 'Truncating table: silver.erp_cust_az12'
        TRUNCATE TABLE silver.erp_cust_az12;
        PRINT 'Inserting into table: silver.erp_cust_az12'
        INSERT INTO silver.erp_cust_az12
        (
        cid,bdate,gen
        )
        SELECT 
        CASE 
        WHEN cid like 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
        ELSE cid
        END AS cid,
        CASE 
        WHEN bdate>GETDATE() THEN NULL
        ELSE bdate
        END as bdate,
        CASE 
        WHEN TRIM(UPPER(gen)) IN ('M','MALE') THEN 'Male'
        WHEN TRIM(UPPER(gen)) IN ('F','FEMALE') THEN 'Female'
        ELSE 'n/a'
        END AS gen
        FROM bronze.erp_cust_az12;
        SET @end_time=GETDATE()
        PRINT 'Load duartion: '+CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR)+' seconds';
        PRINT'---------------------------------------'
        SET @start_time=GETDATE();
        PRINT 'Truncating table: silver.erp_loc_a101'
        TRUNCATE TABLE silver.erp_loc_a101;
        PRINT 'Inserting into table: silver.erp_loc_a101'
        INSERT INTO silver.erp_loc_a101
        (cid,cntry)
        SELECT
        REPLACE(cid,'-','') cid,
        CASE 
        WHEN UPPER(TRIM(cntry))='DE' THEN 'Germany'
        WHEN UPPER(TRIM(cntry)) IN ('US','USA') THEN 'United States'
        WHEN cntry IS NULL OR TRIM(cntry)='' THEN 'n/a'
        ELSE TRIM(cntry)
        END as cntry
        FROM bronze.erp_loc_a101;
        SET @end_time=GETDATE()
        PRINT 'Load duartion: '+CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR)+' seconds';
        PRINT'---------------------------------------'
        SET @start_time=GETDATE();
        PRINT 'Truncating table: silver.erp_px_cat_g1v2'
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        PRINT 'Inserting into table: silver.erp_px_cat_g1v2'
        INSERT INTO silver.erp_px_cat_g1v2
        (id,cat,subcat,maintenance)
        SELECT
        id,cat,subcat,maintenance
        FROM bronze.erp_px_cat_g1v2;
        SET @end_time=GETDATE()
        PRINT 'Load duartion: '+CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR)+' seconds';

        PRINT'+++++++++++++++++++++++++++++++++++++++++++++'
        SET @silver_et=GETDATE()
        PRINT'LOADING COMPLETE'
        PRINT 'SILVER LAYER Load duartion: '+CAST(DATEDIFF(second,@silver_st,@silver_et) as NVARCHAR)+' seconds';
    END TRY
    BEGIN CATCH
        PRINT'--------------------------------------------'
        PRINT'Error Occured'
        PRINT'--------------------------------------------'
        PRINT'Error Message: '+ERROR_MESSAGE();
        PRINT'Error Line: '+CAST(ERROR_LINE() AS NVARCHAR);
        PRINT'Error Number :'+CAST(ERROR_NUMBER() AS NVARCHAR);
    END CATCH
END
