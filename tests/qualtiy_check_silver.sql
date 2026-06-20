/*
===============================================================================
Quality Checks: Silver Layer
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' schema. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ============================================================================
-- silver.crm_cust_info
-- ============================================================================

-- Check for duplicates and nulls in primary key
-- Expectation: No duplicates or nulls
SELECT
    cst_id,
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(cst_id) > 1 
   OR cst_id IS NULL;

-- Check for extra spaces at beginning or end of string fields
-- Expectation: No extra spaces
SELECT 
    -- cst_key,
    -- cst_firstname,
    cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Data consistency and standardization check
SELECT DISTINCT
    cst_marital_status
    -- cst_gndr
FROM silver.crm_cust_info;


-- ============================================================================
-- silver.crm_prd_info
-- ============================================================================

-- Check for duplicates and nulls in primary key
-- Expectation: No nulls and duplicates
SELECT
    prd_id,
    COUNT(*) AS record_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 
   OR prd_id IS NULL;

-- Check for extra spaces
SELECT
    prd_nm 
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check for negative values and nulls in costs
SELECT
    prd_cost 
FROM silver.crm_prd_info
WHERE prd_cost < 0 
   OR prd_cost IS NULL;

-- Check for data integrity / allowed values
SELECT DISTINCT
    prd_line 
FROM silver.crm_prd_info;

-- Check for invalid date logical ranges
SELECT
    prd_id,
    prd_key,
    prd_start_dt,
    prd_end_dt
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;


-- ============================================================================
-- silver.crm_sales_details
-- ============================================================================

-- Check for extra spaces in order numbers
SELECT 
    sls_ord_num
    -- sls_prd_key
FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- Check for referential integrity (Orphaned records)
-- Finds values in sales table that do not exist in the customer dimension
SELECT
    -- sls_prd_key,
    sls_cust_id
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (
    SELECT cst_id 
    FROM silver.crm_cust_info
);

-- Check for invalid logical date order
-- Order date must be older than or equal to due date and ship date
SELECT
    -- sls_order_dt,
    -- sls_due_dt,
    sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;
   -- sls_ship_dt <= 0 
   -- OR LEN(sls_ship_dt) != 8 OR
   -- sls_ship_dt > CAST('20500101' AS DATE)
   -- OR sls_ship_dt < CAST('19000101' AS DATE)

-- Check for sales financial formulas, negatives, and nulls
-- Formula verification: sales = price * quantity
SELECT DISTINCT
    sls_sales,
    sls_price,
    sls_quantity
FROM silver.crm_sales_details
WHERE sls_price * sls_quantity <> sls_sales
   OR sls_price <= 0 
   OR sls_quantity <= 0 
   OR sls_sales <= 0
   OR sls_price IS NULL 
   OR sls_quantity IS NULL 
   OR sls_sales IS NULL;

-- SELECT * FROM silver.crm_sales_details;


-- ============================================================================
-- silver.erp_cust_az12
-- ============================================================================

-- Check for future/invalid birthdates
SELECT 
    bdate 
FROM silver.erp_cust_az12
WHERE bdate > GETDATE();

-- Data standardization review
SELECT DISTINCT
    gen 
FROM silver.erp_cust_az12;


-- ============================================================================
-- silver.erp_loc_a101
-- ============================================================================

-- Data standardization review
SELECT DISTINCT 
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;


-- ============================================================================
-- silver.erp_px_cat_g1v2
-- ============================================================================

-- Check for extra spaces
SELECT
    -- subcat,
    maintenance
FROM silver.erp_px_cat_g1v2
WHERE TRIM(maintenance) != maintenance;

-- Data standardization review
SELECT DISTINCT
    -- subcat,
    maintenance
FROM silver.erp_px_cat_g1v2;
