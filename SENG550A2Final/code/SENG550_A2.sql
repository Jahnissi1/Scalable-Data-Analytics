--CUSTOMER TABLE DIMENSTION
DROP TABLE IF EXISTS dim_customers;
CREATE TABLE dim_customers (
    id BIGSERIAL PRIMARY KEY,
    customer_id TEXT NOT NULL,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    city TEXT NOT NULL,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_to TIMESTAMPTZ,
    is_current BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_dim_customers_current
    ON dim_customers(customer_id, is_current);

	
-- Create dim_patients table
DROP TABLE iF EXISTS dim_products;
CREATE TABLE dim_products (
    id BIGSERIAL PRIMARY KEY,
    product_id TEXT NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_to TIMESTAMPTZ,
    is_current BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE INDEX idx_dim_products_current
ON dim_products (product_id, is_current);



--FACT TABLE
DROP TABLE IF EXISTS fact_orders;
CREATE TABLE fact_orders (
	order_id TEXT PRIMARY KEY,
	customer_id TEXT NOT NULL,
	product_id TEXT NOT NULL,
	order_date TIMESTAMPTZ NOT NULL,
	amount	NUMERIC(10, 2) NOT NULL
);


-- 1.Insert initial records
INSERT INTO dim_customers (customer_id, name, email, city, valid_from)
VALUES
    ('C1', 'Alice', 'alice@customer.com', 'New York', '2025-10-08 11:00-06'),
    ('C2', 'Bob', 'bob@customer.com', 'Boston', '2025-10-08 11:00-06');

INSERT INTO dim_products (product_id, name, category, price, valid_from)
VALUES
    ('P1', 'Laptop', 'Computers', '1000', '2025-10-08 11:00-06'),
    ('P2', 'Phone', 'Mobile Devices', '500', '2025-10-08 11:00-06');

-- 2.C1 buys P1 for 1000
INSERT INTO fact_orders
VALUES ('O1', 'C1', 'P1', '2025-10-08 11:10-06', 1000);

-- 3.Update C1 city → Chicago
UPDATE dim_customers 
SET valid_to = '2025-10-08 11:20-06', is_current = FALSE
WHERE customer_id = 'C1' AND is_current = TRUE;

INSERT INTO dim_customers (customer_id, name, email, city, valid_from, is_current)
SELECT customer_id, name, email, 'Chicago', '2025-10-08 11:20-06', TRUE
FROM dim_customers
WHERE customer_id = 'C1'
ORDER BY id DESC
LIMIT 1;

-- 4.Update P1 Price to 900
UPDATE dim_products
SET valid_to = '2025-10-08 11:30-06', 
    is_current = FALSE
WHERE product_id = 'P1' 
  AND is_current = TRUE;



INSERT INTO dim_products (product_id, name, category, price, valid_from, is_current)
SELECT product_id, name, category, 900.00, '2025-10-08 11:30-06', TRUE
FROM dim_products
WHERE product_id = 'P1'
ORDER BY id DESC
LIMIT 1; 

-- 5.C1 buys P1 for 850
INSERT INTO fact_orders
VALUES ('O2', 'C1', 'P1', '2025-10-08 11:40-06', 850);

-- 6.Update C2 City to Calgary
 UPDATE dim_customers
    SET valid_to='2025-10-08 11:50-6', is_current=FALSE
WHERE customer_id='C2' AND is_current=TRUE;

INSERT INTO dim_customers (customer_id, name, email, city, valid_from, is_current)
SELECT customer_id, name, email, 'Calgary', '2025-10-08 11:50-6', TRUE
FROM dim_customers
WHERE customer_id='C2'
ORDER BY id DESC
LIMIT 1;

-- 7.C2 buys P2 for 500
INSERT INTO fact_orders
VALUES ('O3', 'C2', 'P2', '2025-10-08 12:00-06', 500.00);

-- 8. C1 buys P1 for 900
INSERT INTO fact_orders
VALUES ('O4', 'C1', 'P1', '2025-10-08 12:10-06', 900);


-- PART 2
SELECT customer_id, name, email, city, valid_from, valid_to FROM dim_customers ORDER BY customer_id;
SELECT product_id, name, category, price, valid_from, valid_to FROM dim_products ORDER BY product_id;
SELECT * FROM fact_orders ORDER BY order_date DESC;

CREATE OR REPLACE VIEW orders_asof AS
WITH cust AS (
  SELECT
    f.order_id,
    f.order_date,
    f.product_id,
    c.name AS customer_name,
    c.city AS customer_city,
    ROW_NUMBER() OVER (
      PARTITION BY f.order_id
      ORDER BY c.valid_from DESC
    ) rn
  FROM fact_orders f
  JOIN dim_customers c
    ON c.customer_id = f.customer_id
   AND c.valid_from <= f.order_date
   AND (c.valid_to IS NULL OR f.order_date < c.valid_to)
),
prod AS (
  SELECT
    f.order_id,
    f.product_id,
    p.name AS product_name,
    p.category,
    p.price,
    ROW_NUMBER() OVER (
      PARTITION BY f.order_id
      ORDER BY p.valid_from DESC
    ) rn
  FROM fact_orders f
  JOIN dim_products p
    ON p.product_id = f.product_id
   AND p.valid_from <= f.order_date
   AND (p.valid_to IS NULL OR f.order_date < p.valid_to)
)
SELECT
  f.order_id,
  f.order_date,
  f.customer_id,
  cust.customer_name,
  cust.customer_city,
  f.product_id,
  prod.product_name,
  prod.category,
  prod.price,
  f.amount
FROM fact_orders f
JOIN cust ON cust.order_id = f.order_id AND cust.rn = 1
JOIN prod ON prod.order_id = f.order_id AND prod.rn = 1
ORDER BY f.order_date;

SELECT *
FROM orders_asof
ORDER BY order_date;

--PART 3
-- 1.Postgre
SELECT 
    customer_id,
    COUNT(DISTINCT city) AS unique_city_count
FROM dim_customers
GROUP BY customer_id
ORDER BY customer_id;

-- MongoDB
--db.Assignment_2_db.aggregate([
--   { $group: {
--       _id: "$customer_id",                      
--       cities: { $addToSet: "$customer_city" }   
--   }},
--   { $project: {
--       _id: 0,
--       customer_id: "$_id",                      
--       num_cities: { $size: "$cities" }         
--   }},
--   { $sort: { customer_id: 1 } }                 
-- ]);



-- 2.Postgre
SELECT customer_city, SUM(amount) AS total_sales
FROM orders_asof
GROUP BY customer_city
ORDER BY total_sales DESC;

-- MongoDB
-- db.orders_summary.aggregate([
--   { $group: {
--       _id: "$customer_city",                    
--       total_paid: { $sum: "$amount" }       
--   }},
--   { $project: {
--       _id: 0,
--       customer_city: "$_id",                   
--       total_paid: 1
--   }},
--   { $sort: { total_paid: -1 } }             
-- ]);

-- 3.Postgre
SELECT 
    SUM(price - amount) AS total_price_difference
FROM orders_asof;

-- MongoDB
-- db.orders_summary.aggregate([
--   { $project: {
--       diff: { $subtract: ["$price", "$amount"] }
--   }},
--   { $group: {
--       _id: null,
--       total_diff: { $sum: "$diff" }                
--   }},
--   { $project: { _id: 0, total_diff: 1 } }               
-- ]);

