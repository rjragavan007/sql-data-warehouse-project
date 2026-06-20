/*
===============================================================================
Quality Checks: Gold Layer
===============================================================================
Script Purpose:
    This script performs quality assurance checks to validate the integrity, 
    uniqueness, and relational consistency of the final business-level tables 
    in the 'gold' schema.
===============================================================================
*/

-- ============================================================================
-- gold.dim_customers
-- ============================================================================

-- Check for Uniqueness of Customer Key
-- Expectation: No results (customer_key must be unique)
SELECT
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Check Cross-System Data Integration Consistency
-- Reviewing alignment between CRM gender and ERP gender fields
SELECT DISTINCT
    ci.cst_gndr,
    ca.gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid
ORDER BY 1, 2;


-- ============================================================================
-- gold.fact_sales
-- ============================================================================

-- Referential Integrity / Data Validity Check
-- Ensures all sales records successfully map back to existing customers and products
-- Expectation: No orphaned records (No NULLs returned)
SELECT *
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers dc
    ON s.customer_key = dc.customer_key
LEFT JOIN gold.dim_products pr
    ON s.product_key = pr.product_key
WHERE dc.customer_key IS NULL 
   OR pr.product_key IS NULL;
