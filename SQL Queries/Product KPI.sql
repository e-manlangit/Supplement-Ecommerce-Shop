--Revenue per brand
SELECT
	brand,
	SUM(price * quantity) AS total_revenue
FROM purchases
JOIN products USING(sku)
GROUP BY brand
ORDER BY total_revenue DESC;

--Revenue per product type
SELECT
	type AS product_type,
	SUM(price * quantity) AS total_revenue
FROM purchases 
JOIN products USING(sku)
GROUP BY product_type
ORDER BY total_revenue DESC;

--Revenue for each product type per brand
SELECT
	brand,
	type AS product_type,
	SUM(price * quantity) AS total_revenue
FROM purchases
JOIN products USING(sku)
GROUP BY brand, type
ORDER BY total_revenue DESC;

--AOV per brand
WITH sku_orders AS (
	SELECT
		product_name AS product_name,
		SUM(quantity * price) AS total_revenue,
   	 	COUNT(purchaseid) AS total_orders
	FROM purchases 
 	JOIN products USING (sku)
	GROUP BY 1

  --Total revenue each product generated, with the quantity sold and price per serving 
SELECT
	product_name,
	price_serving,
	SUM(quantity) AS quantity_sold,
	SUM(price * quantity) AS total_revenue
FROM products 
JOIN purchases
USING (sku)
GROUP BY 1,2
ORDER BY 4 DESC;

--Average sold per day for each product
SELECT
	product_name,
	ROUND(total_sold / NULLIF(days_with_sales, 0),2) AS average_sold_per_day
FROM (
	SELECT product_name, SUM(quantity) AS total_sold, COUNT(DISTINCT purchase_date) AS days_with_sales
	FROM products JOIN purchases USING (sku)
	GROUP BY 1
) sub
ORDER BY 2 DESC;

--Flavored vs Unflavored sold
WITH flavored AS(
SELECT
	'Flavored' AS flavor,
	SUM(quantity) total_sold,
	SUM(price * quantity) AS revenue
FROM products
JOIN purchases USING (sku)
WHERE flavor != 'Unflavored'
GROUP BY 1
),
unflavored AS(
SELECT
	'Unflavored' AS flavor,
	SUM(quantity) total_sold,
	SUM(price * quantity) AS revenue
FROM products
JOIN purchases USING (sku)
WHERE flavor = 'Unflavored'
)

SELECT * FROM flavored
UNION ALL
SELECT * FROM unflavored;

SELECT 
  CASE 
    WHEN flavor IS NULL OR flavor = 'Unflavored' THEN 'Unflavored'
    ELSE flavor
  END AS flavor_label,
  COUNT(*) AS product_count
FROM products
GROUP BY flavor_label
ORDER BY product_count DESC;
)
SELECT
	product_name,
	ROUND(total_revenue * 1.0 / total_orders,2) AS average_order_value
FROM sku_orders
ORDER BY 2 DESC;
