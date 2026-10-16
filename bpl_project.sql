--  BUSINESS PERFORMANCE DIAGNOSIS PROJECT: PostgreSQL FILE
--  Project question: why is margin falling while revenue grows?
--
--  HOW TO USE
--  1. Create a database, for example:  CREATE DATABASE bpd_project;
--  2. Open this file in psql or pgAdmin Query Tool (connected to that database).
--  3. Run PART 0 first. It builds the tables and loads the CSV files.
--  4. For every question: read it, WRITE YOUR OWN QUERY FIRST, then compare
--     with the ANSWER and the expected result written under it.
 
 
-- =====================================================================
-- PART 1: SETUP (schema, tables, loading)
-- =====================================================================
DROP TABLE IF EXISTS sales, opex, customers, products CASCADE;

DROP TABLE IF EXISTS products;
CREATE TABLE products (
    product_id    VARCHAR(5)  PRIMARY KEY,
    product_name  TEXT        NOT NULL,
    category      TEXT        NOT NULL,
    unit_cost     NUMERIC(10,2),
    list_price    NUMERIC(10,2)
);
SELECT * FROM products;

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id       VARCHAR(6) PRIMARY KEY,
    segment           TEXT,
    region            TEXT,
    acquisition_year  INT
);
SELECT * FROM customers;

DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
    order_id      VARCHAR(8)  PRIMARY KEY,
    order_date    DATE        NOT NULL,
    customer_id   VARCHAR(6)  REFERENCES customers (customer_id),
    product_id    VARCHAR(5)  REFERENCES products (product_id),
    region        TEXT,
    channel       TEXT,
    quantity      INT,
    list_price    NUMERIC(10,2),
    discount_pct  NUMERIC(6,4),
    net_revenue   NUMERIC(12,2),
    cogs          NUMERIC(12,2),
    freight_cost  NUMERIC(12,2)
);
SELECT * FROM sales;

DROP TABLE IF EXISTS opex;
CREATE TABLE opex (
    month        DATE PRIMARY KEY,         -- first day of each month
    marketing    NUMERIC(12,2),
    salaries     NUMERIC(12,2),
    admin_other  NUMERIC(12,2)
);
SELECT * FROM opex;

\copy products     FROM 'data/products.csv'           WITH (FORMAT csv, HEADER true)
\copy customers    FROM 'data/customers.csv'          WITH (FORMAT csv, HEADER true)
\copy sales        FROM 'data/sales_transactions.csv' WITH (FORMAT csv, HEADER true)
\copy opex         FROM 'data/monthly_opex.csv'       WITH (FORMAT csv, HEADER true)


-- Q. Check the load: how many rows are in each table?
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM products
UNION ALL SELECT 'customers',   COUNT(*) FROM customers
UNION ALL SELECT 'sales',       COUNT(*) FROM sales
UNION ALL SELECT 'opex',        COUNT(*) FROM opex;


-- =====================================================================
-- PART 2:(SELECT, WHERE, GROUP BY, ORDER BY, LIMIT, HAVING)
-- =====================================================================
 
-- Q1. How many orders are there, and how many different customers and products?
SELECT COUNT(*) AS orders,
       COUNT(DISTINCT customer_id) AS customers, 
	   COUNT(DISTINCT product_id) AS products
FROM sales;	   

-- Q2. What is the date range of the orders?
SELECT MIN(order_date) AS first_order,
       MAX(order_date) AS last_order
FROM sales;

-- Q3. What are the orders and net revenue for each year?
SELECT EXTRACT(YEAR FROM order_date)::INT AS year,
       COUNT(*) AS orders,
	   ROUND(SUM(net_revenue),0) AS net_revenue
FROM sales
GROUP BY 1
ORDER BY 1;

-- Q4. For FY24 only, show orders and net revenue per sales channel, biggest first.
SELECT channel,
       COUNT(*) AS orders,
	   ROUND(SUM(net_revenue),0) AS net_revenue
FROM sales
WHERE order_date >= DATE '2024-01-01' AND order_date < DATE '2025-01-01'
GROUP BY channel
ORDER BY net_revenue DESC;

-- Q5. Which 5 products earned the most net revenue in FY24?
SELECT p.product_name, p.category,
       ROUND(SUM(s.net_revenue),0) AS net_revenue
FROM sales s
JOIN products p
ON p.product_id = s.product_id
WHERE order_date >= DATE '2024-01-01' AND order_date < DATE '2025-01-01'
GROUP BY p.product_name, p.category
ORDER BY net_revenue DESC
LIMIT 5;

-- Q6. Which regions had FY24 net revenue above $1800000?
SELECT region,
       ROUND(SUM(net_revenue), 0) AS net_revenue
FROM sales
WHERE order_date >= DATE '2024-01-01' AND order_date < DATE '2025-01-01'
GROUP BY region
HAVING SUM(net_revenue) > 1800000
ORDER BY net_revenue DESC;


-- =====================================================================
-- PART 3:(JOIN, CASE, FILTER, CTE, window SUM OVER)
-- ===================================================================

-- Q7. Show the order ID, product name and category for the first 5 orders.
SELECT s.order_id, p.product_name, p.category
FROM sales s
JOIN products p ON p.product_id = s.product_id
ORDER BY s.order_date, s.order_id
LIMIT 5;

-- Q8. What is the total net revenue for each customer segment?
SELECT c.segment, ROUND(SUM(s.net_revenue), 0) AS net_revenue
FROM sales s
JOIN customers c ON c.customer_id = s.customer_id
GROUP BY c.segment
ORDER BY net_revenue DESC;

-- Q.9 Which 3 products have the fewest orders? Use LEFT JOIN, so a product with no orders would still appear.
SELECT p.product_name, COUNT(s.order_id) AS orders
FROM products p
LEFT JOIN sales s ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY orders
LIMIT 3;

-- Q.10 Label each order Small (under $200), Medium ($200 to $999) or Large ($1,000 and over), and count the orders in each label.
SELECT CASE WHEN net_revenue < 200  THEN 'Small'
            WHEN net_revenue < 1000 THEN 'Medium'
            ELSE 'Large' END AS order_size,
       COUNT(*) AS orders
FROM sales
GROUP BY 1
ORDER BY orders DESC;

-- Q.11 Label each product Budget (under $100), Mid-range ($100 to $500) or Premium (over $500).
SELECT product_name, list_price,
       CASE WHEN list_price < 100 THEN 'Budget'
            WHEN list_price <= 500 THEN 'Mid-range'
            ELSE 'Premium' END AS price_band
FROM products
ORDER BY list_price;

-- Q.12 Show the number of orders in 2023 and in 2024 side by side.
SELECT COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM order_date) = 2023) AS orders_2023,
       COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM order_date) = 2024) AS orders_2024
FROM sales;

-- Q.13 For each region, how many Online orders and how many Retail orders are there?
SELECT region,
       COUNT(*) FILTER (WHERE channel = 'Online') AS online_orders,
       COUNT(*) FILTER (WHERE channel = 'Retail') AS retail_orders
FROM sales
GROUP BY region
ORDER BY region;

-- Q.14 How many customers spent more than the average customer?
WITH customer_totals AS (
    SELECT customer_id, SUM(net_revenue) AS total
    FROM sales
    GROUP BY customer_id
)
SELECT COUNT(*) AS customers_above_average
FROM customer_totals
WHERE total > (SELECT AVG(total) FROM customer_totals);

-- Q.15 Which month had the highest revenue?
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::DATE AS month,
           SUM(net_revenue) AS revenue
    FROM sales
    GROUP BY 1
)
SELECT month, ROUND(revenue, 0) AS revenue
FROM monthly
ORDER BY revenue DESC
LIMIT 1;

-- Q.16 For FY24, show each category's revenue next to the grand total.
SELECT p.category,
       ROUND(SUM(s.net_revenue), 0)              AS category_revenue,
       ROUND(SUM(SUM(s.net_revenue)) OVER (), 0) AS total_revenue
FROM sales s
JOIN products p ON p.product_id = s.product_id
WHERE s.order_date >= DATE '2024-01-01' AND s.order_date < DATE '2025-01-01'
GROUP BY p.category
ORDER BY category_revenue DESC;

-- Q.17 Show monthly revenue for January to June 2023, with a running total.
SELECT month,
       ROUND(revenue, 0)                            AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month), 0) AS running_total
FROM (
    SELECT DATE_TRUNC('month', order_date)::DATE AS month, SUM(net_revenue) AS revenue
    FROM sales
    WHERE order_date >= DATE '2023-01-01' AND order_date < DATE '2023-07-01'
    GROUP BY 1
) t
ORDER BY month;

-- Q.18 For FY24, what percentage of revenue does each channel earn?
SELECT channel,
       ROUND(SUM(net_revenue), 0) AS net_revenue,
       ROUND(100.0 * SUM(net_revenue) / SUM(SUM(net_revenue)) OVER (), 1) AS pct_of_total
FROM sales
WHERE order_date >= DATE '2024-01-01' AND order_date < DATE '2025-01-01'
GROUP BY channel
ORDER BY net_revenue DESC;


-- =====================================================================
-- PART 4:(window functions, ranking, percentiles, Pareto)
-- =====================================================================

-- Q.19 Number the products from the most expensive to the cheapest, and show the top 5.
SELECT product_name, list_price,
       ROW_NUMBER() OVER (ORDER BY list_price DESC) AS row_num
FROM products
ORDER BY row_num
LIMIT 5;

-- Q.20 Rank the products by list price with RANK and DENSE_RANK, and compare them.
SELECT product_name, list_price,
       RANK()       OVER (ORDER BY list_price DESC) AS rank_no,
       DENSE_RANK() OVER (ORDER BY list_price DESC) AS dense_rank_no
FROM products
ORDER BY list_price DESC
LIMIT 8;

-- Q.21 What is the most expensive product in each category?
SELECT category, product_name, list_price
FROM (
    SELECT category, product_name, list_price,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY list_price DESC) AS rn
    FROM products
) t
WHERE rn = 1
ORDER BY category;

-- Q.22 Show monthly revenue for January to April 2023, with the previous month and the change.
SELECT month,
       ROUND(revenue, 0) AS revenue,
       ROUND(LAG(revenue) OVER (ORDER BY month), 0) AS previous_month,
       ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 0) AS change
FROM (
    SELECT DATE_TRUNC('month', order_date)::DATE AS month, SUM(net_revenue) AS revenue
    FROM sales
    WHERE order_date >= DATE '2023-01-01' AND order_date < DATE '2023-05-01'
    GROUP BY 1
) t
ORDER BY month;

-- Q.23 What are the average, median and 90th-percentile order values?
SELECT ROUND(AVG(net_revenue), 0) AS average_order,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY net_revenue)::NUMERIC, 0) AS median_order,
       ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY net_revenue)::NUMERIC, 0) AS p90_order
FROM sales;

-- Q.24 What is the median order value for each channel?
SELECT channel,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY net_revenue)::NUMERIC, 0) AS median_order
FROM sales
GROUP BY channel
ORDER BY channel;

-- Q.25 Split the customers into 4 equal groups by total spend, and show each group's share of revenue.
WITH customer_totals AS (
    SELECT customer_id, SUM(net_revenue) AS total
    FROM sales
    GROUP BY customer_id
)
SELECT quartile,
       COUNT(*)                                               AS customers,
       ROUND(SUM(total), 0)                                   AS revenue,
       ROUND(100.0 * SUM(total) / SUM(SUM(total)) OVER (), 1) AS pct_of_revenue
FROM (
    SELECT total, NTILE(4) OVER (ORDER BY total DESC) AS quartile
    FROM customer_totals
) t
GROUP BY quartile
ORDER BY quartile;

-- Q.26 PARETO: show the top 5 products by FY24 revenue with the cumulative % of revenue.
SELECT product_name,
       ROUND(rev, 0) AS net_revenue,
       ROUND(100.0 * SUM(rev) OVER (ORDER BY rev DESC) / SUM(rev) OVER (), 1) AS cumulative_pct
FROM (
    SELECT p.product_name, SUM(s.net_revenue) AS rev
    FROM sales s
    JOIN products p ON p.product_id = s.product_id
    WHERE s.order_date >= DATE '2024-01-01' AND s.order_date < DATE '2025-01-01'
    GROUP BY p.product_name
) t
ORDER BY rev DESC
LIMIT 5;
 

-- =====================================================================
-- PART 5: DATA QUALITY, VIEWS AND INDEXES
-- =====================================================================

-- Q.27 Find duplicate order IDs.
SELECT order_id, COUNT(*) AS times_found
FROM sales
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Q.28 Count the missing values in net revenue, COGS and region.
SELECT COUNT(*) - COUNT(net_revenue) AS missing_revenue,
       COUNT(*) - COUNT(cogs)        AS missing_cogs,
       COUNT(*) - COUNT(region)      AS missing_region
FROM sales;

-- Q.29 Check that every discount is valid (between 0% and 100%).
SELECT MIN(discount_pct) AS lowest_discount,
       MAX(discount_pct) AS highest_discount,
       COUNT(*) FILTER (WHERE discount_pct < 0 OR discount_pct > 1) AS invalid_discounts
FROM sales;

-- Q.30 Are there orders whose product does not exist in the products table? (This is an anti-join: LEFT JOIN, then keep the rows with no match.)
SELECT COUNT(*) AS orders_with_unknown_product
FROM sales s
LEFT JOIN products p ON p.product_id = s.product_id
WHERE p.product_id IS NULL;

-- Q.31 Create a view that joins sales and products, then use it to get revenue by category.
CREATE OR REPLACE VIEW v_sales_detail AS
SELECT s.order_id, s.order_date, s.channel, s.net_revenue,
       p.product_name, p.category
FROM sales s
JOIN products p ON p.product_id = s.product_id;

SELECT category, ROUND(SUM(net_revenue), 0) AS net_revenue
FROM v_sales_detail
GROUP BY category
ORDER BY net_revenue DESC;

-- Q.32 Create a materialized view of yearly revenue, read it, then refresh it.
CREATE MATERIALIZED VIEW mv_yearly_revenue AS
SELECT EXTRACT(YEAR FROM order_date)::INT AS year,
       ROUND(SUM(net_revenue), 0)         AS net_revenue
FROM sales
GROUP BY 1;

SELECT * FROM mv_yearly_revenue ORDER BY year;

REFRESH MATERIALIZED VIEW mv_yearly_revenue;

-- Q.33 Create an index on the customer ID, then list the indexes on the sales table.
CREATE INDEX IF NOT EXISTS idx_sales_customer_id ON sales (customer_id);

SELECT indexname
FROM pg_indexes
WHERE schemaname = 'bpd' AND tablename = 'sales'
ORDER BY indexname;

-- Q.34 Check that PostgreSQL uses the index when you look up one customer.
ANALYZE sales;
EXPLAIN SELECT * FROM sales WHERE customer_id = 'C0001';































