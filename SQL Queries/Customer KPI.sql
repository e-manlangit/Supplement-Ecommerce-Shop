--New customer count per month
SELECT 
  TO_CHAR(registration_date, 'YYYY-MM') AS month,
  COUNT(*) AS new_customers
FROM customers
GROUP BY month
ORDER BY month;

--Average order value per State
WITH state_orders AS (
  SELECT 
    c.state,
    SUM(p.quantity * pr.price) AS total_revenue,
    COUNT(p.purchaseid) AS total_orders
  FROM purchases p
  JOIN products pr ON p.sku = pr.sku
  JOIN customers c ON p.customerid = c.customer_id
  WHERE c.state IS NOT NULL
  GROUP BY c.state
)
SELECT 
  state,
  ROUND(total_revenue * 1.0 / total_orders, 2) AS average_order_value
FROM state_orders
ORDER BY average_order_value DESC;

--Customer lifetime value
SELECT
	c.customer_name AS customer_name,
	EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.registration_date)) * 12 +
	EXTRACT(MONTH FROM AGE(CURRENT_DATE, c.registration_date)) AS months_registered,
	SUM(pr.price * p.quantity) AS revenue
FROM purchases p
JOIN products pr ON p.sku = pr.sku
JOIN customers c ON c.customer_id = p.customerid
GROUP BY 1, 2
ORDER BY 3 DESC;

--Churn or inactivity rate
SELECT
	c.customer_name AS customer_name,
	MAX(p.purchase_date) AS last_purchased,
	CURRENT_DATE - MAX(p.purchase_date) AS days_inactive
FROM customers c
JOIN purchases p ON c.customer_id = p.customerid
GROUP BY 1
ORDER BY 3 DESC;

--Average days between purchases per customer
WITH purchase_activity AS(
	SELECT
		customerid,
		MIN(purchase_date) AS first_purchase,
		MAX(purchase_date) AS last_purchase,
		COUNT(purchase_date) AS purchase_count
	FROM purchases
	GROUP BY customerid
)

SELECT
	customerid,
	((last_purchase - first_purchase) / (purchase_count - 1)) AS avg_active_days_per_customer
FROM purchase_activity
WHERE purchase_count > 1
ORDER BY 2 DESC;

--Tenure bands for the average days between purchases per customer
WITH purchase_activity AS(
	SELECT
		customerid,
		MIN(purchase_date) AS first_purchase,
		MAX(purchase_date) AS last_purchase,
		COUNT(purchase_date) AS purchase_count
	FROM purchases
	GROUP BY customerid
),
avg_active_days AS(
	SELECT
		customerid,
		((last_purchase - first_purchase) / (purchase_count - 1)) AS avg_days
	FROM purchase_activity
	WHERE purchase_count > 1
	ORDER BY 2 DESC
)

SELECT 
	CASE
		WHEN avg_days <= 30 THEN '≤ 30 days'
		WHEN avg_days <= 90 THEN '31-90 days'
		WHEN avg_days <= 120 THEN '91-120 days'
		WHEN avg_days <= 210 THEN '121-210 days'
		WHEN avg_days <= 300 THEN '212-300 days'
		ELSE '365+ days'
	END AS frequency_band,
	COUNT (*) AS avg_active_days_count
FROM avg_active_days
GROUP BY 1
ORDER BY 2 DESC;

--Active/inactive customer count and percentages
WITH purchase_activity AS(
	SELECT
		customerid,
		MIN(purchase_date) AS first_purchase,
		MAX(purchase_date) AS last_purchase,
		COUNT(purchase_date) AS purchase_count
	FROM purchases
	GROUP BY customerid
),
avg_active_days AS(
	SELECT
		customerid,
		first_purchase,
		last_purchase,
		purchase_count,
		((last_purchase - first_purchase) / (purchase_count - 1)) AS avg_days,
		CURRENT_DATE - last_purchase AS days_since_last_purchase
	FROM purchase_activity
	WHERE purchase_count > 1
	ORDER BY 2 DESC
),
segmented_customers AS(
	SELECT
		customerid,
		first_purchase,
		last_purchase,
		purchase_count,
		ROUND(avg_days, 1) AS avg_days_between,
		days_since_last_purchase,
		CASE
			WHEN avg_days <= 30 THEN '≤ 30 days'
			WHEN avg_days <= 90 THEN '31-90 days'
			WHEN avg_days <= 120 THEN '91-120 days'
			WHEN avg_days <= 210 THEN '121-210 days'
			WHEN avg_days <= 300 THEN '212-300 days'
			ELSE '365+ days'
		END AS frequency_band,
		CASE
			WHEN days_since_last_purchase > 2 * avg_days THEN 'inactive'
			ELSE 'active'
		END AS status
	FROM avg_active_days
	WHERE purchase_count > 1
)

SELECT 
	status,
	COUNT(*) AS customer_count,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*))OVER (), 2) AS percentage
FROM segmented_customers
GROUP BY status
ORDER BY status DESC;
