-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- 04_relationship_checks.sql
-- Queries validating and exploring table relationships.
-- ============================================================


-- ------------------------------------------------------------
-- ORDERS → CUSTOMERS
-- ------------------------------------------------------------

-- Attach real customer identity to orders.

SELECT o.order_id,
       c.customer_unique_id
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id;


-- Number of orders per real customer.

SELECT c.customer_unique_id,
       COUNT(o.order_id) AS order_count
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id
ORDER BY order_count DESC;


-- Repeat customers only.

SELECT c.customer_unique_id,
       COUNT(o.order_id) AS order_count
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(o.order_id) > 1
ORDER BY order_count DESC;


-- ------------------------------------------------------------
-- ORDER ITEMS → PRODUCTS
-- ------------------------------------------------------------

-- Product categories ranked by number of order-item rows.

SELECT p.product_category_name,
       COUNT(oi.order_item_id) AS product_items_count
FROM order_items AS oi
INNER JOIN products AS p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY product_items_count DESC;


-- ------------------------------------------------------------
-- PRODUCTS → CATEGORY TRANSLATION
-- ------------------------------------------------------------

-- Identify product categories lacking a translation.

SELECT DISTINCT p.product_category_name
FROM products AS p
LEFT JOIN product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL
  AND p.product_category_name IS NOT NULL;