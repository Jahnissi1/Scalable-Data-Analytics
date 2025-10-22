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
