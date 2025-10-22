--PART 3
-- 1.Postgre
SELECT 
    customer_id,
    COUNT(DISTINCT city) AS unique_city_count
FROM dim_customers
GROUP BY customer_id
ORDER BY customer_id;

-- MongoDB
-- db.orders_summary.aggregate([
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

