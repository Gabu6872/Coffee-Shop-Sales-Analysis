 CREATE DATABASE coffee_shop_sales_db
SELECT * FROM [dbo].[Coffee_Shop_Sales]
SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM 
    INFORMATION_SCHEMA.COLUMNS

ALTER TABLE [dbo].[Coffee_Shop_Sales]
ADD FormattedOrderDate AS CONVERT(VARCHAR, [transaction_date], 105) PERSISTED;

SELECT TOP 10 * FROM [dbo].[Coffee_Shop_Sales]

-- Total Sales by Month
SELECT DISTINCT MONTH(transaction_date) AS "Month", ROUND(SUM(unit_price * transaction_qty),0) AS "Total Sales"
FROM [dbo].[Coffee_Shop_Sales]
GROUP BY MONTH(transaction_date)
ORDER BY "Month" ASC

-- Month-to-month increase/decrease in sales
WITH MonthlySales AS (
    SELECT 
        MONTH(transaction_date) AS "Month",
        SUM(unit_price * transaction_qty) AS "Total Sales"
    FROM 
        [dbo].[Coffee_Shop_Sales]
    GROUP BY 
        MONTH(transaction_date)
)
, SalesWithLag AS (
    SELECT 
        "Month",
        "Total Sales",
        LAG("Total Sales", 1) OVER (ORDER BY "Month") AS PreviousMonthSales -- Obtains sales from the previous month
    FROM 
        MonthlySales
)

SELECT 
    "Month",
    "Total Sales",
    PreviousMonthSales,
	"Total Sales" - PreviousMonthSales AS SalesDifference,
    CASE 
        WHEN PreviousMonthSales IS NULL THEN NULL
        ELSE ROUND((("Total Sales" - PreviousMonthSales) / PreviousMonthSales) * 100, 2)
    END AS "Month-to-Month % Change"
FROM 
    SalesWithLag
ORDER BY 
    "Month";

-- Total Orders by Month
SELECT DISTINCT MONTH(transaction_date) AS "Month", COUNT(transaction_id) AS "Total Orders"
FROM [dbo].[Coffee_Shop_Sales]
GROUP BY MONTH(transaction_date)
ORDER BY "Month" ASC

-- Month-to-month increase/decrease in orders
SET QUERY_GOVERNOR_COST_LIMIT  15000;
WITH MonthlyOrders AS (
	SELECT 
		MONTH(transaction_date) AS "Month",
		COUNT(transaction_id) AS "Total Orders"
	FROM
		[dbo].[Coffee_Shop_Sales]
	GROUP BY
		MONTH(transaction_date)
)
, OrdersWithLag AS (
	SELECT
		"Month",
		"Total Orders",
		LAG("Total Orders", 1) OVER (ORDER BY "Month") AS "PreviousMonthOrders"
	FROM
		MonthlyOrders
)

SELECT 
	"Month",
	"Total Orders",
	"PreviousMonthOrders",
	"Total Orders" - PreviousMonthOrders AS OrdersDifference,
CASE
	WHEN "PreviousMonthOrders" IS NULL THEN NULL
	ELSE ROUND((CAST("Total Orders" AS FLOAT) - CAST("PreviousMonthOrders" AS FLOAT)) / CAST("PreviousMonthOrders" AS FLOAT) * 100, 2)
END AS "Month-to-month % Change"
FROM OrdersWithLag
ORDER BY "Month";

-- Total Quantities by Month
SELECT DISTINCT MONTH(transaction_date) AS "Month", SUM(transaction_qty) AS "Total Quantities"
FROM [dbo].[Coffee_Shop_Sales]
GROUP BY MONTH(transaction_date)
ORDER BY "Month" ASC

-- Month-to-month increase/decrease in quantities sold
WITH MonthlyOrders AS (
	SELECT 
		MONTH(transaction_date) AS "Month",
		SUM(transaction_qty) AS "Total Quantities"
	FROM
		[dbo].[Coffee_Shop_Sales]
	GROUP BY
		MONTH(transaction_date)
)
, OrdersWithLag AS (
	SELECT
		"Month",
		"Total Quantities",
		LAG("Total Quantities", 1) OVER (ORDER BY "Month") AS "PreviousMonthQuantities"
	FROM
		MonthlyOrders
)

SELECT 
	"Month",
	"Total Quantities",
	"PreviousMonthQuantities",
	"Total Quantities" - PreviousMonthQuantities AS QuantitiesDifference,
CASE
	WHEN "PreviousMonthQuantities" IS NULL THEN NULL
	ELSE ROUND((CAST("Total Quantities" AS FLOAT) - CAST("PreviousMonthQuantities" AS FLOAT)) / CAST("PreviousMonthQuantities" AS FLOAT) * 100, 2)
END AS "Month-to-month % Change"
FROM OrdersWithLag
ORDER BY "Month";

-- Total sales, quantity and orders for a specific day
SELECT TOP 5 * FROM [dbo].[Coffee_Shop_Sales]
SELECT 
	CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000, 2), 'K') AS "Total Sales", 
	SUM(transaction_qty) AS "Total Quantity", COUNT(transaction_id) AS "Total Orders"
FROM [dbo].[Coffee_Shop_Sales]
WHERE transaction_date = '2023-01-01'

-- Sales analysis by weekday and weekend
SELECT 
	CASE
		WHEN DATEPART(WEEKDAY, transaction_date) IN (1,7) THEN 'Weekend'
		ELSE 'Weekday'
		END AS "Day Type",
		CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000, 2), 'K') AS "Total Sales"
	FROM [dbo].[Coffee_Shop_Sales]
	WHERE MONTH(transaction_date) = 5
	GROUP BY 
		CASE
		WHEN DATEPART(WEEKDAY, transaction_date) IN (1,7) THEN 'Weekend'
		ELSE 'Weekday'
		END

--  Sales value by store location for a particular month
SELECT 
	DISTINCT(store_location) AS "Store Location", 
	CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000, 2), 'K') AS "Total Sales"
FROM 
	[dbo].[Coffee_Shop_Sales]
WHERE MONTH(transaction_date) IN (5)
GROUP BY store_location
ORDER BY "Total Sales" DESC

-- Daily sales analysis for specific month
SET QUERY_GOVERNOR_COST_LIMIT 2000
SELECT 
	DISTINCT DAY(transaction_date) AS "Day", 
	ROUND(SUM(transaction_qty * unit_price), 2) AS "Total Sales"
FROM [dbo].[Coffee_Shop_Sales]
WHERE MONTH(transaction_date) IN (5)
GROUP BY DAY(transaction_date)
ORDER BY "Day" ASC

-- Average sales for a specific month
SELECT AVG("Total Sales") AS "Avg. Sales"
FROM (
	SELECT 
		ROUND(SUM(transaction_qty * unit_price), 2) AS "Total Sales"
	FROM [dbo].[Coffee_Shop_Sales]
	WHERE MONTH(transaction_date) IN (5)
	GROUP BY transaction_date
) AS "Internal Query"

-- Sales above or below average
SELECT 
    day_of_month,
    CASE 
        WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_status,
    total_sales
FROM (
    SELECT 
        DAY(transaction_date) AS day_of_month,
        SUM(unit_price * transaction_qty) AS total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
    FROM 
        coffee_shop_sales
    WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        DAY(transaction_date)
) AS sales_data
ORDER BY 
    day_of_month;

-- Sales by product category
SELECT 
	product_category, 
	ROUND(SUM(transaction_qty * unit_price),2) AS "Total Sales" 
FROM [dbo].[Coffee_Shop_Sales]
WHERE MONTH(transaction_date) IN (5)
GROUP BY product_category
ORDER BY "Total Sales" DESC

-- Top 10 products by sales
SELECT TOP 10 product_type, ROUND(SUM(transaction_qty * unit_price), 2) AS "Total Sales"
FROM Coffee_Shop_Sales
WHERE MONTH(transaction_date) IN (5)
GROUP BY product_type
ORDER BY "Total Sales" DESC
 
 -- Sales values by hours
SELECT 
	DISTINCT DATEPART(hour, transaction_time) AS "Day",
	ROUND(SUM(transaction_qty * unit_price), 2) AS "Total Sales"
FROM Coffee_Shop_Sales
WHERE MONTH(transaction_date) IN (5)
GROUP BY DATEPART(hour, transaction_time)
ORDER BY "Day"

--  Sales value by day of the week
SELECT 
	CASE
		WHEN DATEPART(WEEKDAY, transaction_date) = 1 THEN 'Sunday'
		WHEN DATEPART(WEEKDAY, transaction_date) = 2 THEN 'Monday'
		WHEN DATEPART(WEEKDAY, transaction_date) = 3 THEN 'Tuesday'
		WHEN DATEPART(WEEKDAY, transaction_date) = 4 THEN 'Wednesday'
		WHEN DATEPART(WEEKDAY, transaction_date) = 5 THEN 'Thursday'
		WHEN DATEPART(WEEKDAY, transaction_date) = 6 THEN 'Friday'
		ELSE 'Saturday'
		END AS "Day of the week",
	ROUND(SUM(transaction_qty *unit_price), 0) AS "Total Sales"
FROM Coffee_Shop_Sales
WHERE MONTH(transaction_date) IN (5)
GROUP BY 
	CASE
		WHEN DATEPART(WEEKDAY, transaction_date) = 1 THEN 'Sunday'
		WHEN DATEPART(WEEKDAY, transaction_date) = 2 THEN 'Monday'
		WHEN DATEPART(WEEKDAY, transaction_date) = 3 THEN 'Tuesday'
		WHEN DATEPART(WEEKDAY, transaction_date) = 4 THEN 'Wednesday'
		WHEN DATEPART(WEEKDAY, transaction_date) = 5 THEN 'Thursday'
		WHEN DATEPART(WEEKDAY, transaction_date) = 6 THEN 'Friday'
		ELSE 'Saturday'
		END