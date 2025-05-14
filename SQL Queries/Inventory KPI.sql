--Inventory Levels CTE
WITH inventory_summary AS (
	SELECT 
		i.sku,
		pr.product_name,
		SUM(i.quantity_received) AS total_stock,
		SUM(p.quantity) AS total_sold,
		MAX(purchase_date) - MIN(purchase_date) AS days_active
	FROM inventory i
	JOIN purchases p ON i.sku = p.sku
	JOIN products pr ON i.sku = pr.sku
	GROUP BY 1,2
),
avg_daily_sales AS(
	SELECT
		sku,
		product_name,
		total_sold / days_active AS daily_sales
	FROM inventory_summary
),
inventory_classification AS (
  SELECT
    i.sku,
    i.product_name,
    i.total_stock,
    a.daily_sales,
    ROUND(i.total_stock / NULLIF(a.daily_sales, 0), 2) AS days_on_hand,
    CASE
      WHEN i.total_stock = 0 THEN 'Stocked Out'
      WHEN (i.total_stock / NULLIF(a.daily_sales, 0)) < 4 THEN 'At Risk'
      WHEN (i.total_stock / NULLIF(a.daily_sales, 0)) < 7 THEN 'Low Stock'
      ELSE 'Healthy'
    END AS stock_status
  FROM inventory_summary i
  JOIN avg_daily_sales a ON i.sku = a.sku
)


--Turnover Rate for each product type
SELECT
	sku,
	product_name,
	ROUND(total_sold * 1.0 / NULLIF(total_stock, 0), 2) AS inventory_turnover
FROM inventory_summary
ORDER BY 3 ASC;

--Days on hand for each product type
SELECT
	i.sku,
	i.product_name,
	ROUND((i.total_stock / a.daily_sales),2) AS DOH
FROM inventory_summary i
JOIN avg_daily_sales a ON i.sku = a.sku
ORDER BY 3 DESC;

--Stock status for At Risk or Low Stock
SELECT *
FROM inventory_classification
WHERE  stock_status IN ('At Risk', 'Low Stock');
