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