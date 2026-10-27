/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' layer. It includes checks for:
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

/*
===============================================================================
Data Quality Tests: ERP Customer Data
Table: silver.crm_cust_info
===============================================================================
*/


-- Test 1: Check for NULLs or duplicate values in the primary key
-- Expected Result: No NULL values and no duplicate cst_id values.


-- Check for NULL primary keys
SELECT
    cst_id
FROM silver.crm_cust_info
WHERE prd_id IS NULL;

-- Check for duplicate primary keys
SELECT
    cst_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;



-- Test 2: Check for unwanted leading or trailing spaces
-- Table: silver.crm_cust_info
-- Expected Result: No results.


SELECT
    cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);



-- Test 3: Check data standardization and consistency
-- Table: silver.crm_cust_info
-- Purpose: Identify distinct gender values and verify standardization.
-- Expected Result: Only approved, standardized values (e.g., Male, Female).


SELECT DISTINCT
    cst_gender
FROM silver.crm_cust_info
ORDER BY cst_gender;


/*
===============================================================================
Table: silver.crm_prd_info
===============================================================================
*/


-- Test 1: Check for NULLs or duplicate values in the primary key
-- Expected Result: No NULL values and no duplicate prd_id values.


-- Check for NULL in primary key
SELECT
    prd_id
FROM silver.crm_prd_info
WHERE prd_id IS NULL;

-- Check for duplicate primary key
SELECT
    prd_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;



-- Test 2: Check for unwanted leading or trailing spaces
-- Table: silver.crm_prd_info
-- Expected Result: No results.


SELECT
    prd_line
FROM silver.crm_prd_info
WHERE prd_line != TRIM(prd_line);



-- Test 3: Check data standardization and consistency
-- Table: silver.crm_prd_info
-- Purpose: Identify distinct product line values and verify standardization.
-- Expected Result: Only approved, standardized values (e.g., Mountain, Other Sales, Road).


SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info
ORDER BY prd_line;


-- Test 4: Check data standardization and consistency
-- Table: silver.crm_prd_info
-- Purpose: Identify where the product start date is later than the
--          product end date.
-- Expected Result: no results


SELECT prd_id, prd_start_dt, prd_end_dt
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;



/*
===============================================================================
Table: silver.crm_sales_details
===============================================================================
*/


-- Test: Check for NULLs or duplicate values in the primary key
-- Expected Result: No NULL values and no duplicate values.


-- Check for duplicate primary keys
SELECT
    sls_ord_num,
	sls_prd_key,
    COUNT(*) AS duplicate_count
FROM silver.crm_sales_details
GROUP BY sls_ord_num, sls_prd_key
HAVING COUNT(*) > 1;


-- Test: Check data validation
-- Table: silver.crm_sales_details
-- Purpose: Identify where the order date is later than the
--          ship date or due date.
-- Expected Result: no results


SELECT sls_order_dt, sls_ship_dt, sls_due_dt
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt ;



-- Test: Validate Customer Referential Integrity
-- Purpose: Identify sales records referencing customers who do not exist
--          in the silver customer table.
-- Expected Result: No results.


SELECT
    s.sls_cust_id
FROM silver.crm_sales_details AS s
WHERE s.sls_cust_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM silver.crm_cust_info AS c
      WHERE c.cst_id = s.sls_cust_id
  );



-- Test: Validate Product Referential Integrity
-- Purpose: Identify sales records referencing products that do not exist
--          in the silver product table.
-- Expected Result: No results.


SELECT
    s.sls_prd_key
FROM silver.crm_sales_details AS s
WHERE s.sls_prd_key IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM silver.crm_prd_info AS p
      WHERE p.prd_key = s.sls_prd_key
  );



-- Test: Validate Order Date
-- Purpose: Identify invalid order dates based on format and business rules.
-- Expected Result: No results.


SELECT
    sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt IS NOT NULL
  AND (
         sls_order_dt <= 0
      OR LEN(CAST(sls_order_dt AS VARCHAR(20))) <> 8
      OR sls_order_dt > 20261026
      OR sls_order_dt < 19990101
  );



-- Test: Validate Due Date
-- Purpose: Identify invalid due dates based on format and business rules.
-- Expected Result: No results.


SELECT
    sls_due_dt
FROM silver.crm_sales_details
WHERE sls_due_dt IS NOT NULL
  AND (
         sls_due_dt <= 0
      OR LEN(CAST(sls_due_dt AS VARCHAR(20))) <> 8
      OR sls_due_dt > 20261026
      OR sls_due_dt < 19990101
  );




-- Test: Check data validation
-- Table: silver.crm_sales_details
-- Purpose: Sales = Quantity * Price
--		    Values must not be NULL, zero or negative
-- Expected Result: no results


SELECT sls_sales, sls_quantity, sls_price
FROM silver.crm_sales_details
WHERE sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
	OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
	OR sls_sales != sls_quantity * sls_price
	
	

/*
===============================================================================
Data Quality Tests: ERP Customer Data
Table: silver.erp_cust_az12
===============================================================================
*/



-- Test: Validate Customer ID Mapping
-- Purpose: Identify ERP customer IDs that match customer keys in the CRM table.
-- Expected Result: Matching records should be returned.


SELECT
    e.cid,
    e.bdate,
    e.gen
FROM silver.erp_cust_az12 AS e
WHERE e.cid NOT IN (
    SELECT cst_key
    FROM silver.crm_cust_info
);



-- Test: Validate Customer Birthdates
-- Purpose: Identify birthdates that are too old or in the future.
-- Expected Result: No results, based on the defined business rules.


SELECT
    cid,
    bdate
FROM silver.erp_cust_az12
WHERE bdate < '1910-10-25'
   OR bdate > GETDATE();



-- Test: Check for Unwanted Spaces in Gender Values
-- Purpose: Identify gender values containing leading or trailing spaces.
-- Expected Result: No results.


SELECT
    cid,
    gen
FROM silver.erp_cust_az12
WHERE gen <> TRIM(gen);



-- Test: Check data standardization and consistency
-- Table: silver.erp_cust_az12
-- Purpose: Identify distinct gender values and verify standardization.
-- Expected Result: Only approved, standardized values (e.g., Male, Female).


SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;



/*
===============================================================================
Table: silver.erp_loc_a101
===============================================================================
*/



-- Test: Validate Customer ID Mapping
-- Purpose: Identify ERP customer IDs that match customer keys in the CRM table.
-- Expected Result: Matching records should be returned.


SELECT
    e.cid,
    e.cntry
FROM silver.erp_loc_a101 AS e
WHERE e.cid NOT IN (
    SELECT cst_key
    FROM silver.crm_cust_info
);



-- Test: Check data standardization and consistency
-- Table: silver.erp_loc_a101
-- Purpose: Identify distinct country values and verify standardization.
-- Expected Result: Only approved, standardized values (e.g., USA, Canada).


SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101;



/*
===============================================================================
Table: silver.erp_px_cat_glv2
===============================================================================
*/



-- Test: Validate Customer ID Mapping
-- Purpose: Identify ERP customer IDs that match customer keys in the CRM table.
-- Expected Result: Matching records should be returned.


SELECT *,
    e.id
FROM silver.erp_px_cat_glv2 AS e
WHERE e.id NOT IN (
    SELECT cat_id
    FROM silver.crm_prd_info
);



-- Test: Check data standardization and consistency
-- Purpose: Identify distinct maintenance values and verify standardization.
-- Expected Result: Only approved, standardized values (e.g., Accessories, Components).

SELECT DISTINCT
    cat
FROM silver.erp_px_cat_glv2;


-- Test: Check for unwanted leading or trailing spaces
-- Expected Result: No results.


SELECT
    subcat
FROM silver.erp_px_cat_glv2
WHERE subcat != TRIM(subcat);
