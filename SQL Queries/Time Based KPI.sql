--Time Based Key Performance Indicators (KPI)

--Sales trend per year
SELECT 
	EXTRACT(YEAR FROM purchase_date) AS year,
	SUM(quantity * price) AS total_revenue
FROM purchases
JOIN products USING (sku)
GROUP BY year
ORDER BY year;

--Sales trend per quarter
SELECT
	TO_CHAR(purchase_date, 'YYYY-Q') AS quarters,
	SUM (quantity * price) AS total_revenue
FROM purchases
JOIN products USING (sku)
GROUP BY quarters
ORDER BY quarters;

--Sales trend per month
SELECT 
  TO_CHAR(purchase_date, 'Month') AS month_name,
  SUM(quantity * price) AS total_revenue
FROM purchases
JOIN products USING (sku)
GROUP BY month_name
ORDER BY month_name;

--Sales trend per day
SELECT
	TO_CHAR(purchase_date, 'Day') AS day,
	SUM(quantity) AS purchases,
	SUM(quantity * price) AS revenue
FROM purchases
JOIN products USING (sku)
GROUP BY 1
ORDER BY 2 DESC;

--Sales trend per hour
SELECT
	EXTRACT(HOUR FROM purchase_time) AS hours_of_day,
	SUM(quantity) AS purchases,
	SUM(quantity * price) AS revenue
FROM purchases
JOIN products USING (sku)
GROUP BY 1
ORDER BY 2 DESC;

--Average Order Value (AOV) per Month
WITH month_orders AS (
  SELECT 
    TO_CHAR(purchase_date, 'MM') AS month,
    SUM(quantity * price) AS total_revenue,
    COUNT(purchaseid) AS total_orders
  FROM purchases
  JOIN products USING (sku)
  GROUP BY 1
)
SELECT 
  month,
  ROUND(total_revenue * 1.0 / total_orders, 2) AS average_order_value
FROM month_orders
ORDER BY average_order_value DESC;

--Average Order Value (AOV) per day of the week
WITH day_orders AS(
	SELECT
		TO_CHAR(purchase_date, 'Day') AS day_of_week,
		SUM(quantity * price) AS total_revenue,
		COUNT(purchaseid) AS total_orders
	FROM purchases
  		JOIN products USING (sku)
  		GROUP BY 1
)
SELECT
	day_of_week,
	ROUND(total_revenue * 1.0 / total_orders, 2) AS average_order_value
FROM day_orders
ORDER BY average_order_value DESC;

--Average Order Value LYTD vs YTD
WITH aov_years AS (
  SELECT
    CASE 
      WHEN purchase_date BETWEEN DATE_TRUNC('year', CURRENT_DATE) AND CURRENT_DATE THEN 'YTD'
      WHEN purchase_date BETWEEN DATE_TRUNC('year', CURRENT_DATE - INTERVAL '1 year') 
           AND CURRENT_DATE - INTERVAL '1 year' THEN 'LYTD'
    END AS period,
    quantity * price AS revenue,
    purchaseid
  FROM products
  JOIN purchases USING (sku)
  WHERE purchase_date BETWEEN DATE_TRUNC('year', CURRENT_DATE - INTERVAL '1 year') AND CURRENT_DATE
)

SELECT
  period,
  ROUND(SUM(revenue) * 1.0 / COUNT(purchaseid), 2) AS average_order_value
FROM aov_years
WHERE period IS NOT NULL
GROUP BY period
ORDER BY period;
