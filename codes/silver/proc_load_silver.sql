/*
==============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
==============================================================================

Purpose: 
	This stored procedure perform ETL (Extract, Transform, Load) process to 
	insert data into the silver tables from bronze schema.
	This performs below tasks:
		- Truncate silver tables before loading data
		- Inserts cleansed, transformed data from bronze to silver tables

Parameters: None

Usage Example: 
	EXEC silver.load_silver;
==============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS	
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME 
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		
		PRINT '===================================================================';
		PRINT 'Loading Data Into Silver Layer';
		PRINT '===================================================================';
		
		PRINT '-------------------------------------------------------------------';
		PRINT 'Loading Data Related To CRM System';
		PRINT '-------------------------------------------------------------------';
		
		SET @start_time = GETDATE();
		PRINT '--<< Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		--Inserting data into silver table crm_cust_info from bronze layer
		PRINT '--<< Inserting Data Into: silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info (
			cst_id, 
			cst_key, 
			cst_firstname, 
			cst_lastname, 
			cst_matrial_status, 
			cst_gender, 
			cst_create_date
		)
		SELECT cust_id
			  ,cust_key
			  ,TRIM([cust_firstname]) AS cust_firstname --remove any extra spaces
			  ,TRIM([cust_lastname]) AS cust_lastname   --remove any extra spaces
			  ,CASE                                     --This case when statement implements readability and data consistancy
				WHEN UPPER(TRIM(cust_matrial_status)) = 'S' THEN 'Single'
				WHEN UPPER(TRIM(cust_matrial_status)) = 'M' THEN 'Married'
				ELSE 'N/A'
				END cust_matrial_status
			  ,CASE                                     --This case when statement implements readability and data consistancy
					WHEN UPPER(TRIM(cust_gender)) = 'F' THEN 'Female'
					WHEN UPPER(TRIM(cust_gender)) = 'M' THEN 'Male'
					ELSE 'N/A'
				END cust_gender
			  ,[cust_create_date]
		FROM (
			SELECT *, 
				ROW_NUMBER() OVER(PARTITION BY cust_id ORDER BY cust_create_date DESC) AS row_number 
			FROM bronze.crm_cust_info 
			WHERE cust_id IS NOT NULL)t
		WHERE row_number = 1;

		SET @end_time = GETDATE();
		
		PRINT 'Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------';
		
		SET @start_time = GETDATE();
		PRINT '--<< Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		--Inserting data into silver table crm_prd_info from bronze layer
		PRINT '--<< Inserting Data Into: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_name,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') as cat_id,
			SUBSTRING(prd_key, 7, LEN(prd_key)) as prd_key,
			prd_name,
			ISNULL(prd_cost, 0) AS prd_cost,
			CASE UPPER(TRIM(prd_line)) --This case when statement implemented readability for row cust_gender
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				ELSE 'N/A'
			END prd_line,
			CAST(prd_start_dt AS DATE) AS prd_start_dt,
			CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
		FROM bronze.crm_prd_info;
		
		SET @end_time = GETDATE();
		
		PRINT 'Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '--<< Truncating Table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details
		--Inserting data into silver table crm_sales_details from bronze layer
		PRINT '--<< Inserting Data Into: silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT sls_ord_num,
			   sls_prd_key,
			   sls_cust_id,
			   CASE
				WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_order_dt AS NVARCHAR) AS DATE)
			   END AS sls_order_dt,
			   CASE
				WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS NVARCHAR) AS DATE)
			   END AS sls_ship_dt,
			   CASE
				WHEN sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_due_dt AS NVARCHAR) AS DATE)
			   END AS sls_due_dt,
			   CASE WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * sls_price
					THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
			   END sls_sales,
			   sls_quantity,
			   CASE WHEN sls_price IS NULL OR sls_price <= 0
				   THEN sls_sales / NULLIF(sls_quantity, 0)
			       ELSE sls_price
			   END sls_price
		FROM bronze.crm_sales_details
		 
		SET @end_time = GETDATE();
		
		PRINT 'Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------';
		
		PRINT '-------------------------------------------------------------------';
		PRINT 'Loading Data Related To ERP System';
		PRINT '-------------------------------------------------------------------';
		
		SET @start_time = GETDATE();
		PRINT '--<< Truncating Table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12
		--Inserting data into silver table erp_cust_az12 from bronze layer
		PRINT '--<< Inserting Data Into: silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12 (
			cid, 
			bdate, 
			gen
		)
		SELECT
			CASE
				WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
				ELSE cid
			END cid,
			CASE WHEN bdate > GETDATE() THEN NULL
				ELSE bdate
			END bdate,
			CASE UPPER(LEFT(TRIM(gen), 1))
				WHEN 'F'  THEN 'Female'
				WHEN 'M'  THEN 'Male'
				ELSE 'N/A'
			END AS gen
		FROM bronze.erp_cust_az12
		
		SET @end_time = GETDATE();
		
		PRINT 'Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------';

		SET @start_time = GETDATE();
		--Inserting data into silver table erp_loc_a101 from bronze layer
		PRINT '--<< Inserting Data Into: silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101 (cid, cntry)
		SELECT
			REPLACE(cid, '-', '') AS cid,
			CASE c.clean_cntry
				WHEN 'DE'  THEN 'Germany'
				WHEN 'US'  THEN 'United States'
				WHEN 'USA' THEN 'United States'
				WHEN ''    THEN 'N/A'
				ELSE COALESCE(c.clean_cntry, 'N/A')
			END AS n_cntry
		FROM bronze.erp_loc_a101
		CROSS APPLY (
		--below line is to trim below spaces
			SELECT UPPER(TRIM(CHAR(13) + CHAR(10) + CHAR(9) + CHAR(160) + ' ' FROM cntry)) AS clean_cntry
		) c;
		
		
		SET @end_time = GETDATE();
		
		PRINT 'Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------';
		
		SET @start_time = GETDATE();
		PRINT '--<< Truncating Table: silver.erp_px_cat_glv2';
		TRUNCATE TABLE silver.erp_px_cat_glv2
		--Inserting data into silver table erp_px_cat_glv2 from bronze layer
		PRINT '--<< Inserting Data Into: silver.erp_px_cat_glv2';
		INSERT INTO silver.erp_px_cat_glv2 (
			id, 
			cat, 
			subcat, 
			maintenance
		)
		SELECT
			id,
			cat,
			subcat,
			CASE c.clean_maintenance
				WHEN 'NO' THEN 'No'
				WHEN 'YES' THEN 'Yes'
				ELSE 'N/A'
			END AS maintenance
		FROM bronze.erp_px_cat_glv2
		CROSS APPLY(
		--below line is to trim below spaces
			SELECT TRIM(CHAR(13) + CHAR(10) + CHAR(9) + CHAR(160) + ' ' FROM maintenance) AS clean_maintenance
		) c;
		
		SET @end_time = GETDATE();
		
		PRINT 'Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------';
		
		SET @batch_end_time= GETDATE();
		PRINT '==========================================================';
		PRINT 'Loading Date Into Silver Layer Is Completed';
		PRINT 'Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '==========================================================';
		
	END TRY
	BEGIN CATCH
		PRINT '==========================================================';
		PRINT 'Error occured during loading data into Silver layer';
		PRINT 'Error Message:' + ERROR_MESSAGE();
		PRINT 'Error Message:' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message:' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT '==========================================================';
	END CATCH
	
END
