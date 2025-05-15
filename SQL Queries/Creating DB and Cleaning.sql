CREATE TABLE products (
    sku TEXT PRIMARY KEY,
    brand TEXT,
    product_name TEXT,
    type TEXT,
    flavor TEXT,
    price NUMERIC,
    weight_lbs NUMERIC,
    weight_g INTEGER,
    serving_size NUMERIC,
    price_serving NUMERIC
);

CREATE TABLE customers (
	customer_id TEXT PRIMARY KEY,
	name TEXT,
	email TEXT,
	phone TEXT,
	address TEXT,
	registration_date DATE
);

CREATE TABLE purchases (
	purchaseid TEXT,
	customerid TEXT,
	SKU TEXT,
	quantity NUMERIC,
	datetime_sold TIMESTAMP
);

CREATE TABLE inventory (
	inventoryid TEXT PRIMARY KEY,
	SKU TEXT,
	quantity_received NUMERIC,
	date_received DATE
);

--NULL CHECK

SELECT
	COUNT (*) FILTER (WHERE sku IS NULL) AS null_sku,
	COUNT (*) FILTER (WHERE brand IS NULL) AS null_brand,
	COUNT (*) FILTER (WHERE product_name IS NULL) AS null_prodname,
	COUNT (*) FILTER (WHERE type IS NULL) AS null_type,
	COUNT (*) FILTER (WHERE flavor IS NULL) AS null_flavor,
	COUNT (*) FILTER (WHERE price IS NULL) AS null_price,
	COUNT (*) FILTER (WHERE weight_lbs IS NULL) AS null_weightlbs,
	COUNT (*) FILTER (WHERE weight_g IS NULL) AS null_weightg,
	COUNT (*) FILTER (WHERE serving_size IS NULL) AS null_servsize,
	COUNT (*) FILTER (WHERE price_serving IS NULL) AS null_priceserv
FROM products;

SELECT
	COUNT (*) FILTER (WHERE purchaseid IS NULL) AS null_purchid,
	COUNT (*) FILTER (WHERE customerid IS NULL) AS null_custid,
	COUNT (*) FILTER (WHERE sku IS NULL) AS null_sku,
	COUNT (*) FILTER (WHERE quantity IS NULL) AS null_quantity,
	COUNT (*) FILTER (WHERE datetime_sold IS NULL) AS null_datetimesold
FROM purchases;

SELECT
	COUNT (*) FILTER (WHERE inventoryid IS NULL) AS null_invid,
	COUNT (*) FILTER (WHERE sku IS NULL) AS null_sku,
	COUNT (*) FILTER (WHERE quantity_received IS NULL) AS null_quantrec,
	COUNT (*) FILTER (WHERE date_received IS NULL) AS null_daterec
FROM inventory;

SELECT
	COUNT (*) FILTER (WHERE customer_id IS NULL) AS null_customerid,
	COUNT (*) FILTER (WHERE name IS NULL) AS null_name,
	COUNT (*) FILTER (WHERE email IS NULL) AS null_email,
	COUNT (*) FILTER (WHERE phone IS NULL) AS null_phone,
	COUNT (*) FILTER (WHERE address IS NULL) AS null_address,
	COUNT (*) FILTER (WHERE registration_date IS NULL) AS null_regdate
FROM customers;

--FORMATTING / CONSISTENCY CHECK

SELECT DISTINCT brand
FROM products;

SELECT DISTINCT flavor
FROM products;

--FOREIGN KEY CHECK
SELECT p.*
FROM purchases p
LEFT JOIN customers c ON p.customerid = c.customer_id
WHERE c.customer_id IS NULL;

SELECT p.*
FROM purchases p
LEFT JOIN products pr ON p.sku = pr.sku
WHERE pr.sku IS NULL;

SELECT inv.*
FROM inventory inv
LEFT JOIN products pr ON inv.sku = pr.sku
WHERE pr.sku IS NULL;

--LINKING PARENT TABLE TO FOREIGN KEYS

ALTER TABLE purchases
ADD CONSTRAINT fk_customer
FOREIGN KEY (customerid)
REFERENCES customers(customer_id);

ALTER TABLE purchases
ADD CONSTRAINT fk_purchuses_sku
FOREIGN KEY (sku)
REFERENCES products(sku);


ALTER TABLE inventory
ADD CONSTRAINT fk_inventory_sku
FOREIGN KEY (sku)
REFERENCES products(sku);

--SPELLING ERROR ON FOREIGN KEY / DROP AND RE-ADDED

ALTER TABLE purchases
DROP CONSTRAINT fk_purchuses_sku;

ALTER TABLE purchases
ADD CONSTRAINT fk_purchases_sku
FOREIGN KEY (sku)
REFERENCES products(sku);

--CREATING INDEX FOR BOTH purchase_sku and inventory_sku FOREIGN KEY

CREATE INDEX idx_inventory_sku ON inventory(sku);
CREATE INDEX idx_purchases_sku ON purchases(sku);

--ADJUSTING TABLE AND SPLIT ADDRESS INTO SEPARATE COLUMNS

ALTER TABLE customers
ADD COLUMN street_address TEXT,
ADD COLUMN city TEXT,
ADD COLUMN state TEXT,
ADD COLUMN zipcode TEXT;

UPDATE customers
SET
  street_address = split_part(address, ',', 1),
  city = split_part(address, ',', 2),
  state = split_part(split_part(address, ',', 3), ' ', 2),
  zipcode = split_part(split_part(address, ',', 3), ' ', 3);

--NULL CHECK; OBSERVED NULL VALUES IN STATE AND ZIPCODE FROM MILITARY ADDERSSES

SELECT COUNT (*)
FROM customers
WHERE state IS NULL OR TRIM(state) = '';

SELECT COUNT (*)
FROM customers
WHERE zipcode IS NULL OR TRIM(zipcode) = '';

SELECT *
FROM customers
WHERE TRIM(state) = '';

--TESTED UPDATE QUERY BELOW; HOWEVER NO UPDATES OBSERVED

UPDATE customers
SET 
  city = split_part(city, ' ', 1),
  state = split_part(city, ' ', 2),
  zipcode = split_part(city, ' ', 3)
WHERE city LIKE 'DPO %' OR city LIKE 'FPO %' OR city LIKE 'APO %';

--TESTED ANOTHER QUERY BELOW; HOWEVER NO RESULTS PULLED

SELECT 
  customer_id,
  split_part(city, ' ', 1) AS city,
  split_part(city, ' ', 2) AS state,
  split_part(city, ' ', 3) AS zipcode
FROM customers
WHERE city LIKE 'DPO %' OR city LIKE 'FPO %' OR city LIKE 'APO %';

--TESTED CTE WITH TRIM FUNCTION AND WORKED CORRECTLY

WITH military_addresses AS (
SELECT 
  customer_id,
  split_part(city, ' ', 2) AS clean_city,
  split_part(city, ' ', 3) AS clean_state,
  split_part(city, ' ', 4) AS clean_zipcode
FROM customers
WHERE TRIM(city) LIKE 'DPO %' 
   OR TRIM(city) LIKE 'FPO %' 
   OR TRIM(city) LIKE 'APO %'
)

UPDATE customers
SET
	city = m.clean_city,
	state = m.clean_state,
	zipcode = m.clean_zipcode
FROM military_addresses m
WHERE customers.customer_id = m.customer_id;

--SPLITTING datetime_sold INTO SEPARATE COLUMNS

ALTER TABLE purchases
ADD COLUMN purchase_date DATE,
ADD COLUMN purchase_time TIME;

--TESTED QUERY BEFORE UPDATE

SELECT 
	datetime_sold,
	datetime_sold::DATE AS purchase_date,
	datetime_sold::TIME AS purchase_time
FROM purchases
LIMIT 10;

--QUERY WORKED; UPDATED COLUMNS

UPDATE purchases
SET 
	purchase_date = datetime_sold::DATE,
	purchase_time = datetime_sold::TIME;
