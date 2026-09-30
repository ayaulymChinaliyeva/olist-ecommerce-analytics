-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- 03_data_quality_checks.sql
-- Data validation and integrity checks.
-- ============================================================


-- ------------------------------------------------------------
-- CUSTOMERS
-- ------------------------------------------------------------

-- Total customer records

SELECT COUNT(*) AS customer_records
FROM customers;


-- Distinct real customers

SELECT COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;


-- Customers associated with multiple customer records

SELECT customer_unique_id,
       COUNT(*) AS customer_record_count
FROM customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1
ORDER BY customer_record_count DESC;


-- ------------------------------------------------------------
-- ORDERS
-- ------------------------------------------------------------

SELECT COUNT(*) AS order_count
FROM orders;


-- Check whether customer_id appears on multiple orders

SELECT customer_id,
       COUNT(*) AS order_count
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY order_count DESC;


-- ------------------------------------------------------------
-- ORDER ITEMS
-- ------------------------------------------------------------

SELECT COUNT(*) AS order_item_count
FROM order_items;


-- Orders containing multiple item rows

SELECT order_id,
       COUNT(*) AS order_items_count
FROM order_items
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY order_items_count DESC;


-- ------------------------------------------------------------
-- PAYMENTS
-- ------------------------------------------------------------

SELECT COUNT(*) AS payment_record_count
FROM order_payments;


-- Orders containing multiple payment records

SELECT order_id,
       COUNT(*) AS order_payments_count
FROM order_payments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY order_payments_count DESC;


-- ------------------------------------------------------------
-- REVIEWS
-- ------------------------------------------------------------

-- Verify that the cleaned composite key is unique.
-- Expected result: zero rows.

SELECT review_id,
       order_id,
       COUNT(*) AS row_count
FROM order_reviews
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------
-- GEOLOCATION
-- ------------------------------------------------------------

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT geolocation_zip_code_prefix) AS unique_zip_prefixes
FROM geolocation;


-- Number of observations per ZIP prefix

SELECT geolocation_zip_code_prefix,
       COUNT(*) AS geo_count
FROM geolocation
GROUP BY geolocation_zip_code_prefix
ORDER BY geo_count DESC;


-- ------------------------------------------------------------
-- PRODUCT CATEGORIES
-- ------------------------------------------------------------

-- Products with missing categories

SELECT COUNT(*) AS missing_category_count
FROM products
WHERE product_category_name IS NULL;


-- Find populated product categories with no English translation.

SELECT DISTINCT p.product_category_name
FROM products AS p
LEFT JOIN product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL
  AND p.product_category_name IS NOT NULL;