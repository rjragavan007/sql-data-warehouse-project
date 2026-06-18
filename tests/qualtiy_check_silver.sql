/*
===============================================================================
Quality Checks
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
--check for duplicates and nulls in primary key of crm_cust_info
--expectation: no duplicates
--=======================
  --silver.crm_cust_info
--=======================
SELECT
cst_id,
count(*)
FROM silver.crm_cust_info
group by cst_id
having count(cst_id)>1 
or cst_id is null

--check for extra spaces at beginning or end of the names,etc
--expectation: no extra spaces
select 
--cst_key
--cst_firstname
cst_lastname
from silver.crm_cust_info
where cst_lastname!=TRIM(cst_lastname)

--data consistency and standardization
select distinct
cst_marital_status
--cst_gndr
from silver.crm_cust_info
--=========================================================================
--=======================
  --silver.crm_prd_info
--=======================
--check for duplicates in primary key
--expecation: No nulls and duplicates
select
prd_id,
count(*)
from silver.crm_prd_info
group by prd_id
having count(*)>1 or prd_id is null

--check for extra spaces
select
prd_nm 
from silver.crm_prd_info
where prd_nm!=TRIM(prd_nm)

--check for negatives and nulls
select
prd_cost from silver.crm_prd_info
where prd_cost<0 or prd_cost is null

--check for data integrity
select distinct
prd_line 
from silver.crm_prd_info

--check for date validation
select
prd_id,
prd_key,
prd_start_dt,
prd_end_dt
from silver.crm_prd_info
where (prd_start_dt>prd_end_dt)
--=========================================================================
--check for EXTRA SPACES
--=======================
  --silver.crm_sales_details
--=======================
SELECT 
sls_ord_num
--sls_prd_key
FROM silver.crm_sales_details
WHERE sls_ord_num!=TRIM(sls_ord_num)

--check for existence in other tables(helpful for joining)
--to find values in one table which is not in another table
SELECT
--sls_prd_key
sls_cust_id
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id from silver.crm_cust_info)

--CHECK FOR INVALID DATES
select
--sls_order_dt
--sls_due_dt
sls_ship_dt
from silver.crm_sales_details
where sls_order_dt>sls_ship_dt OR sls_order_dt>sls_due_dt
--sls_ship_dt<=0 
--OR LEN(sls_ship_dt)!=8 OR
--sls_ship_dt>CAST('20500101' AS DATE)
--OR sls_ship_dt<CAST('19000101' AS DATE)
--orderdate must be greater than due date and ship date

--check for sales,price and quantity=>can not be negative or null
--sales=price*quantity
select DISTINCT
sls_sales,
sls_price,
sls_quantity
from silver.crm_sales_details
WHERE sls_price*sls_quantity<>sls_sales
or sls_price<=0 or sls_quantity<=0 or sls_sales<=0
or sls_price is null or sls_quantity is null or sls_sales is null

--SELECT * FROM silver.crm_sales_details
--=============================================================================
--=======================
  --silver.erp_cust_az12
--=======================
--check for invalid dates
SELECT 
bdate 
from silver.erp_cust_az12
where bdate>GETDATE()

--data standardization
SELECT DISTINCT
gen 
FROM silver.erp_cust_az12
--=============================================================================
--=======================
  --silver.erp_loc_a101
--=======================
--data standardization
select distinct 
cntry
from silver.erp_loc_a101
order by cntry
----=============================================================================
--=======================
  --silver.erp_px_cat_g1v2
--=======================
--extra space check
SELECT
--subcat
maintenance
from silver.erp_px_cat_g1v2
WHERE TRIM(maintenance)!=maintenance

--data standardization
SELECT DISTINCT
--subcat
maintenance
from silver.erp_px_cat_g1v2
