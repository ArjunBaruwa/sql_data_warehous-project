/*
==============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
==============================================================================

Purpose: 
	This stored procedure loads data into the bronze schema from external CSV files.
	This performs below tasks:
		- Truncate bronze tables before loading data
		- Uses 'Bulk Insert' to load data from the files to the tables

Parameters: None

Usage Example: 
	EXEC bronze.load_bronze;
==============================================================================
*/


CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @procedure_start_time DATETIME, @procedure_end_time DATETIME
	BEGIN TRY
		SET @procedure_start_time = GETDATE();
		PRINT '================================';
		PRINT 'Loading Bronze Layer';
		PRINT '================================';

		PRINT '--------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '--------------------------------';

		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info

		PRINT '>>Inserting Data Into: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM '/tmp/data/cust_info.csv'  -- Location of CSV file
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '   ----------------';

		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info

		PRINT '>>Inserting Data Into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM '/tmp/data/prd_info.csv'  -- Location of CSV file
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '   ----------------';


		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details

		PRINT '>>Inserting Data Into: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM '/tmp/data/sales_details.csv'  -- Location of CSV file
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '   ----------------';

		PRINT '--------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '--------------------------------';
		
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12

		PRINT '>>Inserting Data Into: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM '/tmp/data/cust_az12.csv'   -- Location of CSV file
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '   ----------------';

		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101

		PRINT '>>Inserting Data Into: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM '/tmp/data/loc_a101.csv'  -- Location of CSV file
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '   ----------------';

		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.erp_px_cat_glv2';
		TRUNCATE TABLE bronze.erp_px_cat_glv2

		PRINT '>>Inserting Data Into: bronze.erp_px_cat_glv2';
		BULK INSERT bronze.erp_px_cat_glv2
		FROM '/tmp/data/px_cat_g1v2.csv'  -- Location of CSV file
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();

		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		

		SET @procedure_end_time = GETDATE();
		PRINT '===================================================';
		PRINT 'Loading Bronze Layer Is Completed';
		PRINT '   Load Duration: ' + CAST(DATEDIFF(second, @procedure_start_time, @procedure_end_time) AS NVARCHAR) + ' seconds';
		PRINT '===================================================';

	END TRY
	BEGIN CATCH
		PRINT '===========================';
		PRINT 'Error occured during loading data into bronze layer';
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '===========================';
	END CATCH
END
