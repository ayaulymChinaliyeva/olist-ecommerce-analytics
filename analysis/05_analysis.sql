SELECT    
    DATE_TRUNC('month', order_purchase_timestamp) AS months_one_format,    
    COUNT(order_id)    
FROM orders    
GROUP BY months_one_format    
ORDER BY months_one_format DESC;

SELECT 
    MIN(order_purchase_timestamp), 
    MAX(order_purchase_timestamp) 
FROM orders;

SELECT    
    DATE_TRUNC('month', order_purchase_timestamp) AS months_one_format,    
    COUNT(order_id)    
FROM orders    
GROUP BY months_one_format    
ORDER BY months_one_format ASC;

SELECT     
    DATE_TRUNC('month', order_purchase_timestamp) AS months_one_format,     
    COUNT(order_id)     
FROM orders     
WHERE order_purchase_timestamp >= DATE '2017-01-01' 
  AND order_purchase_timestamp < DATE '2018-10-01'
GROUP BY months_one_format     
ORDER BY months_one_format ASC;

SELECT
    MIN(order_purchase_timestamp),
    MAX(order_purchase_timestamp)
FROM orders
WHERE order_purchase_timestamp >= DATE '2018-09-01'
  AND order_purchase_timestamp <  DATE '2018-10-01';

-- ------------------------------------------------------------
-- Primary analytical window: January 2017 – August 2018 because order volume 
-- collapses from 6,512 in August to 16 in September despite September records spanning most of the month, 
-- indicating anomalous/incomplete coverage.
-- ------------------------------------------------------------

SELECT     
    DATE_TRUNC('month', order_purchase_timestamp) AS months_one_format,     
    COUNT(order_id)     
FROM orders     
WHERE order_purchase_timestamp >= DATE '2017-01-01' 
  AND order_purchase_timestamp < DATE '2018-09-01'
GROUP BY months_one_format     
ORDER BY months_one_format ASC;

SELECT          
    COUNT(orders.order_id)     
FROM orders
LEFT JOIN order_items AS i
    ON orders.order_id = i.order_id     
WHERE order_purchase_timestamp >= DATE '2017-01-01' 
  AND order_purchase_timestamp < DATE '2018-09-01'
  AND i.order_id IS NULL;


SELECT         
    o.order_status,
    COUNT(o.order_id)    
FROM orders AS o
LEFT JOIN order_items AS i
    ON o.order_id = i.order_id    
WHERE o.order_purchase_timestamp >= DATE '2017-01-01' 
  AND o.order_purchase_timestamp < DATE '2018-09-01'
  AND i.order_id IS NULL
GROUP BY o.order_status
ORDER BY COUNT(o.order_id) DESC;


SELECT  
    DATE_TRUNC('month', o.order_purchase_timestamp) AS months_one_format,  
    SUM(i.price), 
    SUM(i.freight_value), 
    SUM(i.price + i.freight_value) 
FROM orders AS o 
INNER JOIN order_items AS i 
    ON o.order_id = i.order_id 
WHERE o.order_purchase_timestamp >= DATE '2017-01-01' 
  AND o.order_purchase_timestamp < DATE '2018-09-01' 
GROUP BY months_one_format     
ORDER BY months_one_format ASC;

SELECT  
    DATE_TRUNC('month', o.order_purchase_timestamp) AS months_one_format,  
    SUM(i.price), 
    SUM(i.freight_value), 
    SUM(i.price + i.freight_value),
    COUNT (DISTINCT i.order_id) 
FROM orders AS o 
INNER JOIN order_items AS i 
    ON o.order_id = i.order_id 
WHERE o.order_purchase_timestamp >= DATE '2017-01-01' 
  AND o.order_purchase_timestamp < DATE '2018-09-01' 
GROUP BY months_one_format     
ORDER BY months_one_format ASC;


SELECT  
    DATE_TRUNC('month', o.order_purchase_timestamp) AS months_one_format,  
    SUM(i.price), 
    SUM(i.freight_value), 
    SUM(i.price + i.freight_value),
    COUNT (DISTINCT i.order_id),
    SUM(i.price)/COUNT (DISTINCT i.order_id) 
FROM orders AS o 
INNER JOIN order_items AS i 
    ON o.order_id = i.order_id 
WHERE o.order_purchase_timestamp >= DATE '2017-01-01' 
  AND o.order_purchase_timestamp < DATE '2018-09-01' 
GROUP BY months_one_format     
ORDER BY months_one_format ASC;


SELECT COUNT(DISTINCT o.order_id)
FROM orders AS o
INNER JOIN order_items AS i
    ON o.order_id = i.order_id
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp < DATE '2018-09-01'
  AND o.order_status = 'canceled';


SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id)
FROM orders AS o
INNER JOIN order_items AS i
    ON o.order_id = i.order_id
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp < DATE '2018-09-01'
GROUP BY o.order_status;

/*
===============================================================================
OLIST E-COMMERCE ANALYTICS
File: 01_business_analysis.sql
Database: PostgreSQL

Purpose
-------
Analyze commercial performance, customers, products, sellers, payments,
delivery performance, and customer satisfaction using the Olist e-commerce
dataset.

Primary analytical window
-------------------------
2017-01-01 <= order_purchase_timestamp < 2018-09-01

The source contains records outside this period, but early 2016 observations
are sparse and September-October 2018 coverage is anomalous/incomplete.
January 2017 through August 2018 is therefore used for time-series analysis.

Metric notes
------------
- merchandise_gmv = SUM(order_items.price)
- freight_value   = SUM(order_items.freight_value)
- total_order_value = merchandise_gmv + freight_value
- payment_value is analyzed separately from item value.
- Monetary item metrics should not be described as Olist accounting revenue.
- customer_unique_id is used for customer-level analysis.
- order_id is used for order-level analysis.
===============================================================================
*/


-- ============================================================================
-- 1. MONTHLY ORDER VOLUME
-- Business question:
-- How did order demand change over the analytical period?
-- ============================================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
    COUNT(DISTINCT o.order_id) AS orders
FROM orders AS o
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
GROUP BY 1
ORDER BY 1;


/*
Expected interpretation:
Order volume measures orders created in the platform regardless of final status.
It therefore represents demand/order activity rather than completed sales.
*/


-- ============================================================================
-- 2. MONTHLY MERCHANDISE PERFORMANCE
-- Business question:
-- How did merchandise value and average order value change over time?
--
-- INNER JOIN intentionally restricts the population to orders represented
-- in order_items.
-- ============================================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
    COUNT(DISTINCT o.order_id) AS orders_with_items,
    ROUND(SUM(i.price), 2) AS merchandise_gmv,
    ROUND(SUM(i.freight_value), 2) AS freight_value,
    ROUND(SUM(i.price + i.freight_value), 2) AS total_order_value,
    ROUND(
        SUM(i.price) / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS merchandise_aov
FROM orders AS o
INNER JOIN order_items AS i
    ON o.order_id = i.order_id
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
GROUP BY 1
ORDER BY 1;


/*
NULLIF protects against division by zero.

This GMV represents the gross merchandise value recorded in order_items.
It does not represent Olist's accounting revenue.
*/


-- ============================================================================
-- 3. ORDER STATUS DISTRIBUTION
-- Business question:
-- What proportion of orders reached each recorded lifecycle status?
-- ============================================================================

SELECT
    o.order_status,
    COUNT(*) AS orders,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_orders
FROM orders AS o
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
GROUP BY o.order_status
ORDER BY orders DESC;


/*
This uses a window function over grouped results:
SUM(COUNT(*)) OVER ()

It calculates the total number of orders without collapsing the individual
status rows.
*/


-- ============================================================================
-- 4. MONTHLY FULFILLMENT / CANCELLATION TREND
-- Business question:
-- Did fulfillment quality change over time?
-- ============================================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE o.order_status = 'delivered'
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE o.order_status = 'canceled'
    ) AS canceled_orders,

    COUNT(*) FILTER (
        WHERE o.order_status = 'unavailable'
    ) AS unavailable_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE o.order_status = 'delivered'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS delivered_rate_pct,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE o.order_status = 'canceled'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct

FROM orders AS o
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
GROUP BY 1
ORDER BY 1;


/*
FILTER is PostgreSQL conditional aggregation.

This keeps multiple related KPIs at the same monthly grain without requiring
separate queries.
*/


-- ============================================================================
-- 5. VALUE OF CANCELED ORDERS WITH ITEM RECORDS
-- Business question:
-- How financially material are canceled orders in item-based GMV?
-- ============================================================================

SELECT
    COUNT(DISTINCT o.order_id) AS canceled_orders_with_items,
    ROUND(SUM(i.price), 2) AS canceled_merchandise_value,
    ROUND(SUM(i.freight_value), 2) AS canceled_freight_value,
    ROUND(SUM(i.price + i.freight_value), 2) AS canceled_total_order_value
FROM orders AS o
INNER JOIN order_items AS i
    ON o.order_id = i.order_id
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
  AND o.order_status = 'canceled';


-- ============================================================================
-- 6. DELIVERED MERCHANDISE PERFORMANCE
-- Business question:
-- What merchandise value is associated specifically with delivered orders?
-- ============================================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(i.price), 2) AS delivered_merchandise_gmv,
    ROUND(SUM(i.freight_value), 2) AS delivered_freight_value,
    ROUND(SUM(i.price + i.freight_value), 2) AS delivered_total_value,
    ROUND(
        SUM(i.price) / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS delivered_merchandise_aov
FROM orders AS o
INNER JOIN order_items AS i
    ON o.order_id = i.order_id
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
  AND o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1;


/*
This metric is intentionally separated from gross ordered merchandise value.
It provides a stricter fulfilled-sales perspective.
*/


-- ============================================================================
-- 7. MONTHLY CUSTOMER PAYMENT VALUE
-- Business question:
-- How much did customers pay for orders created each month?
--
-- Payment value is kept separate from merchandise GMV because they represent
-- different business concepts.
-- ============================================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
    COUNT(DISTINCT o.order_id) AS orders_with_payments,
    ROUND(SUM(p.payment_value), 2) AS customer_payment_value,
    ROUND(
        SUM(p.payment_value) / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS avg_payment_value_per_order
FROM orders AS o
INNER JOIN order_payments AS p
    ON o.order_id = p.order_id
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
GROUP BY 1
ORDER BY 1;


/*
IMPORTANT:
Do not directly join order_items and order_payments and then SUM both monetary
fields. Both tables can contain multiple rows per order, producing a
many-to-many multiplication within each order.
*/


-- ============================================================================
-- 8. RECONCILIATION: ITEM VALUE VS PAYMENT VALUE
-- Business question:
-- How closely do recorded order values reconcile with customer payments?
--
-- Items and payments are first aggregated independently to one row per order.
-- This prevents multiplication of item and payment records.
-- ============================================================================

WITH item_totals AS (
    SELECT
        i.order_id,
        SUM(i.price) AS merchandise_value,
        SUM(i.freight_value) AS freight_value,
        SUM(i.price + i.freight_value) AS item_total_value
    FROM order_items AS i
    GROUP BY i.order_id
),

payment_totals AS (
    SELECT
        p.order_id,
        SUM(p.payment_value) AS payment_value
    FROM order_payments AS p
    GROUP BY p.order_id
)

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(it.item_total_value), 2) AS item_total_value,
    ROUND(SUM(pt.payment_value), 2) AS payment_value,
    ROUND(SUM(pt.payment_value - it.item_total_value), 2) AS value_difference
FROM orders AS o
INNER JOIN item_totals AS it
    ON o.order_id = it.order_id
INNER JOIN payment_totals AS pt
    ON o.order_id = pt.order_id
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
GROUP BY 1
ORDER BY 1;


/*
This is an important modelling pattern:
aggregate each one-to-many table to order grain BEFORE combining them.
*/


-- ============================================================================
-- 9. PAYMENT METHOD MIX
-- Business question:
-- Which payment methods are most frequently used and which account for the
-- greatest payment value?
-- ============================================================================

SELECT
    p.payment_type,
    COUNT(DISTINCT p.order_id) AS orders,
    COUNT(*) AS payment_records,
    ROUND(SUM(p.payment_value), 2) AS payment_value,
    ROUND(
        100.0 * SUM(p.payment_value)
        / NULLIF(SUM(SUM(p.payment_value)) OVER (), 0),
        2
    ) AS payment_value_share_pct
FROM order_payments AS p
INNER JOIN orders AS o
    ON p.order_id = o.order_id
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
GROUP BY p.payment_type
ORDER BY payment_value DESC;


-- ============================================================================
-- 10. INSTALLMENT BEHAVIOR
-- Business question:
-- How common are installment payments?
-- ============================================================================

SELECT
    p.payment_installments,
    COUNT(*) AS payment_records,
    ROUND(SUM(p.payment_value), 2) AS payment_value,
    ROUND(AVG(p.payment_value), 2) AS avg_payment_value
FROM order_payments AS p
INNER JOIN orders AS o
    ON p.order_id = o.order_id
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
  AND p.payment_type = 'credit_card'
GROUP BY p.payment_installments
ORDER BY p.payment_installments;


/*
payment_installments describes the number of installments but the dataset does
not contain individual installment payment dates. It therefore cannot support
monthly cash-receipt timing analysis.
*/


-- ============================================================================
-- 11. TOP PRODUCT CATEGORIES BY MERCHANDISE GMV
-- Business question:
-- Which categories generate the highest merchandise value?
-- ============================================================================

SELECT
    COALESCE(
        t.product_category_name_english,
        pr.product_category_name,
        'Unknown'
    ) AS product_category,

    COUNT(DISTINCT i.order_id) AS orders,
    COUNT(*) AS item_records,
    ROUND(SUM(i.price), 2) AS merchandise_gmv,
    ROUND(AVG(i.price), 2) AS avg_item_price

FROM order_items AS i
INNER JOIN orders AS o
    ON i.order_id = o.order_id
INNER JOIN products AS pr
    ON i.product_id = pr.product_id
LEFT JOIN product_category_name_translation AS t
    ON pr.product_category_name = t.product_category_name

WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'

GROUP BY 1
ORDER BY merchandise_gmv DESC;


/*
The translation table is LEFT JOINed because the source translation lookup is
not complete for every populated Portuguese category.
*/


-- ============================================================================
-- 12. TOP 10 CATEGORIES BY GMV
-- Business question:
-- Which categories contribute most to gross merchandise value?
-- ============================================================================

WITH category_performance AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            pr.product_category_name,
            'Unknown'
        ) AS product_category,
        COUNT(DISTINCT i.order_id) AS orders,
        COUNT(*) AS items,
        SUM(i.price) AS merchandise_gmv
    FROM order_items AS i
    INNER JOIN orders AS o
        ON i.order_id = o.order_id
    INNER JOIN products AS pr
        ON i.product_id = pr.product_id
    LEFT JOIN product_category_name_translation AS t
        ON pr.product_category_name = t.product_category_name
    WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
      AND o.order_purchase_timestamp <  DATE '2018-09-01'
    GROUP BY 1
)

SELECT
    product_category,
    orders,
    items,
    ROUND(merchandise_gmv, 2) AS merchandise_gmv,
    DENSE_RANK() OVER (
        ORDER BY merchandise_gmv DESC
    ) AS gmv_rank
FROM category_performance
ORDER BY gmv_rank, product_category
LIMIT 10;


/*
Demonstrates:
- CTE
- aggregation
- window ranking
- explicit business ranking
*/


-- ============================================================================
-- 13. CATEGORY CONTRIBUTION TO TOTAL GMV
-- Business question:
-- Is merchandise value concentrated in a small number of categories?
-- ============================================================================

WITH category_gmv AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            pr.product_category_name,
            'Unknown'
        ) AS product_category,
        SUM(i.price) AS merchandise_gmv
    FROM order_items AS i
    INNER JOIN orders AS o
        ON i.order_id = o.order_id
    INNER JOIN products AS pr
        ON i.product_id = pr.product_id
    LEFT JOIN product_category_name_translation AS t
        ON pr.product_category_name = t.product_category_name
    WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
      AND o.order_purchase_timestamp <  DATE '2018-09-01'
    GROUP BY 1
)

SELECT
    product_category,
    ROUND(merchandise_gmv, 2) AS merchandise_gmv,

    ROUND(
        100.0 * merchandise_gmv
        / NULLIF(SUM(merchandise_gmv) OVER (), 0),
        2
    ) AS gmv_share_pct,

    ROUND(
        100.0 * SUM(merchandise_gmv) OVER (
            ORDER BY merchandise_gmv DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / NULLIF(SUM(merchandise_gmv) OVER (), 0),
        2
    ) AS cumulative_gmv_share_pct

FROM category_gmv
ORDER BY merchandise_gmv DESC;


/*
The cumulative share can reveal category concentration and supports a
Pareto-style analysis.
*/


-- ============================================================================
-- 14. UNIQUE CUSTOMERS AND REPEAT CUSTOMERS
-- Business question:
-- How much of the customer base purchased more than once?
--
-- customer_unique_id is used because customer_id is order-specific in this
-- dataset.
-- ============================================================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers AS c
    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id
    WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
      AND o.order_purchase_timestamp <  DATE '2018-09-01'
    GROUP BY c.customer_unique_id
)

SELECT
    COUNT(*) AS unique_customers,

    COUNT(*) FILTER (
        WHERE order_count = 1
    ) AS one_time_customers,

    COUNT(*) FILTER (
        WHERE order_count > 1
    ) AS repeat_customers,

    ROUND(
        100.0 * COUNT(*) FILTER (WHERE order_count > 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_rate_pct,

    ROUND(AVG(order_count), 2) AS avg_orders_per_customer,
    MAX(order_count) AS max_orders_per_customer

FROM customer_orders;


-- ============================================================================
-- 15. CUSTOMER ORDER FREQUENCY DISTRIBUTION
-- Business question:
-- How many customers place 1, 2, 3, ... orders?
-- ============================================================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers AS c
    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id
    WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
      AND o.order_purchase_timestamp <  DATE '2018-09-01'
    GROUP BY c.customer_unique_id
)

SELECT
    order_count,
    COUNT(*) AS customers
FROM customer_orders
GROUP BY order_count
ORDER BY order_count;


/*
This is more informative than only reporting the average because e-commerce
purchase frequency is typically highly skewed.
*/


-- ============================================================================
-- 16. CUSTOMER VALUE
-- Business question:
-- Which customers generated the highest merchandise value?
--
-- First aggregate order_items to order level, then connect orders to the
-- persistent customer identifier.
-- ============================================================================

WITH order_values AS (
    SELECT
        i.order_id,
        SUM(i.price) AS merchandise_value
    FROM order_items AS i
    GROUP BY i.order_id
),

customer_value AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(ov.merchandise_value) AS merchandise_value
    FROM customers AS c
    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id
    INNER JOIN order_values AS ov
        ON o.order_id = ov.order_id
    WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
      AND o.order_purchase_timestamp <  DATE '2018-09-01'
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    orders,
    ROUND(merchandise_value, 2) AS merchandise_value,
    DENSE_RANK() OVER (
        ORDER BY merchandise_value DESC
    ) AS customer_value_rank
FROM customer_value
ORDER BY customer_value_rank
LIMIT 20;


-- ============================================================================
-- 17. CUSTOMER GEOGRAPHY
-- Business question:
-- Which customer states generate the most orders and merchandise value?
-- ============================================================================

WITH order_values AS (
    SELECT
        i.order_id,
        SUM(i.price) AS merchandise_value
    FROM order_items AS i
    GROUP BY i.order_id
)

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT c.customer_unique_id) AS customers,
    ROUND(SUM(ov.merchandise_value), 2) AS merchandise_gmv,
    ROUND(
        SUM(ov.merchandise_value)
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS merchandise_aov
FROM customers AS c
INNER JOIN orders AS o
    ON c.customer_id = o.customer_id
INNER JOIN order_values AS ov
    ON o.order_id = ov.order_id
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
GROUP BY c.customer_state
ORDER BY merchandise_gmv DESC;


-- ============================================================================
-- 18. SELLER PERFORMANCE
-- Business question:
-- Which sellers generate the highest merchandise value?
-- ============================================================================

SELECT
    i.seller_id,
    s.seller_state,
    COUNT(DISTINCT i.order_id) AS orders,
    COUNT(*) AS items,
    ROUND(SUM(i.price), 2) AS merchandise_gmv,
    ROUND(AVG(i.price), 2) AS avg_item_price,
    DENSE_RANK() OVER (
        ORDER BY SUM(i.price) DESC
    ) AS seller_gmv_rank
FROM order_items AS i
INNER JOIN orders AS o
    ON i.order_id = o.order_id
INNER JOIN sellers AS s
    ON i.seller_id = s.seller_id
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
GROUP BY i.seller_id, s.seller_state
ORDER BY seller_gmv_rank
LIMIT 20;


-- ============================================================================
-- 19. SELLER MARKET CONCENTRATION
-- Business question:
-- How concentrated is GMV across sellers?
-- ============================================================================

WITH seller_gmv AS (
    SELECT
        i.seller_id,
        SUM(i.price) AS merchandise_gmv
    FROM order_items AS i
    INNER JOIN orders AS o
        ON i.order_id = o.order_id
    WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
      AND o.order_purchase_timestamp <  DATE '2018-09-01'
    GROUP BY i.seller_id
),

ranked_sellers AS (
    SELECT
        seller_id,
        merchandise_gmv,
        ROW_NUMBER() OVER (
            ORDER BY merchandise_gmv DESC
        ) AS seller_rank
    FROM seller_gmv
)

SELECT
    COUNT(*) AS sellers,
    ROUND(SUM(merchandise_gmv), 2) AS total_merchandise_gmv,

    ROUND(
        100.0 * SUM(merchandise_gmv) FILTER (WHERE seller_rank <= 10)
        / NULLIF(SUM(merchandise_gmv), 0),
        2
    ) AS top_10_seller_gmv_share_pct,

    ROUND(
        100.0 * SUM(merchandise_gmv) FILTER (WHERE seller_rank <= 100)
        / NULLIF(SUM(merchandise_gmv), 0),
        2
    ) AS top_100_seller_gmv_share_pct

FROM ranked_sellers;


-- ============================================================================
-- 20. DELIVERY PERFORMANCE
-- Business question:
-- How long does successful delivery take?
-- ============================================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    o.order_delivered_customer_date
                    - o.order_purchase_timestamp
                )
            ) / 86400.0
        ),
        2
    ) AS avg_delivery_days,

    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY EXTRACT(
                EPOCH FROM (
                    o.order_delivered_customer_date
                    - o.order_purchase_timestamp
                )
            ) / 86400.0
        )::numeric,
        2
    ) AS median_delivery_days

FROM orders AS o

WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
  AND o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL

GROUP BY 1
ORDER BY 1;


/*
Median is included because delivery-time distributions can be skewed and the
average alone can be sensitive to unusually slow deliveries.
*/


-- ============================================================================
-- 21. ON-TIME DELIVERY RATE
-- Business question:
-- How often were delivered orders received by the estimated delivery date?
-- ============================================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,

    COUNT(*) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE o.order_delivered_customer_date
              <= o.order_estimated_delivery_date
    ) AS on_time_orders,

    COUNT(*) FILTER (
        WHERE o.order_delivered_customer_date
              > o.order_estimated_delivery_date
    ) AS late_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE o.order_delivered_customer_date
                  <= o.order_estimated_delivery_date
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_delivery_rate_pct

FROM orders AS o

WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
  AND o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY 1
ORDER BY 1;


-- ============================================================================
-- 22. REVIEW SCORE DISTRIBUTION
-- Business question:
-- How satisfied are customers based on review scores?
--
-- Reviews can contain multiple rows per order in the source structure, so an
-- order-level review score is created before joining to orders.
-- ============================================================================

WITH order_reviews_agg AS (
    SELECT
        r.order_id,
        AVG(r.review_score) AS review_score
    FROM order_reviews AS r
    GROUP BY r.order_id
)

SELECT
    ROUND(r.review_score, 1) AS review_score,
    COUNT(*) AS orders
FROM order_reviews_agg AS r
INNER JOIN orders AS o
    ON r.order_id = o.order_id
WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01'
GROUP BY ROUND(r.review_score, 1)
ORDER BY review_score;


/*
A review_id is not assumed to be a unique order identifier. Reviews are
therefore normalized to one row per order for this analysis.
*/


-- ============================================================================
-- 23. DELIVERY DELAY VS REVIEW SCORE
-- Business question:
-- Is customer satisfaction associated with delivery performance?
-- ============================================================================

WITH order_reviews_agg AS (
    SELECT
        r.order_id,
        AVG(r.review_score) AS review_score
    FROM order_reviews AS r
    GROUP BY r.order_id
),

delivery_review AS (
    SELECT
        o.order_id,
        r.review_score,

        CASE
            WHEN o.order_delivered_customer_date
                 <= o.order_estimated_delivery_date
                THEN 'On time'
            ELSE 'Late'
        END AS delivery_status

    FROM orders AS o
    INNER JOIN order_reviews_agg AS r
        ON o.order_id = r.order_id

    WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
      AND o.order_purchase_timestamp <  DATE '2018-09-01'
      AND o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)

SELECT
    delivery_status,
    COUNT(*) AS reviewed_orders,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM delivery_review
GROUP BY delivery_status
ORDER BY avg_review_score DESC;


/*
This identifies association, not causation.
A lower review score among late deliveries would not by itself prove that the
delay caused the lower score.
*/


-- ============================================================================
-- 24. REVIEW SCORE BY DELIVERY DELAY
-- Business question:
-- How does satisfaction vary with the magnitude of delivery delay?
-- ============================================================================

WITH order_reviews_agg AS (
    SELECT
        r.order_id,
        AVG(r.review_score) AS review_score
    FROM order_reviews AS r
    GROUP BY r.order_id
),

review_delivery AS (
    SELECT
        o.order_id,
        r.review_score,

        EXTRACT(
            EPOCH FROM (
                o.order_delivered_customer_date
                - o.order_estimated_delivery_date
            )
        ) / 86400.0 AS days_vs_estimate

    FROM orders AS o
    INNER JOIN order_reviews_agg AS r
        ON o.order_id = r.order_id

    WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
      AND o.order_purchase_timestamp <  DATE '2018-09-01'
      AND o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)

SELECT
    CASE
        WHEN days_vs_estimate <= -7 THEN '7+ days early'
        WHEN days_vs_estimate < 0   THEN '1-6 days early'
        WHEN days_vs_estimate = 0   THEN 'On estimated date'
        WHEN days_vs_estimate <= 3  THEN '1-3 days late'
        WHEN days_vs_estimate <= 7  THEN '4-7 days late'
        ELSE '8+ days late'
    END AS delivery_timing,

    COUNT(*) AS reviewed_orders,
    ROUND(AVG(review_score), 2) AS avg_review_score

FROM review_delivery

GROUP BY
    CASE
        WHEN days_vs_estimate <= -7 THEN '7+ days early'
        WHEN days_vs_estimate < 0   THEN '1-6 days early'
        WHEN days_vs_estimate = 0   THEN 'On estimated date'
        WHEN days_vs_estimate <= 3  THEN '1-3 days late'
        WHEN days_vs_estimate <= 7  THEN '4-7 days late'
        ELSE '8+ days late'
    END

ORDER BY avg_review_score DESC;


-- ============================================================================
-- 25. MONTH-OVER-MONTH ORDER GROWTH
-- Business question:
-- How quickly did monthly order demand grow or contract?
-- ============================================================================

WITH monthly_orders AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
        COUNT(*) AS orders
    FROM orders AS o
    WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
      AND o.order_purchase_timestamp <  DATE '2018-09-01'
    GROUP BY 1
),

monthly_with_previous AS (
    SELECT
        order_month,
        orders,
        LAG(orders) OVER (
            ORDER BY order_month
        ) AS previous_month_orders
    FROM monthly_orders
)

SELECT
    order_month,
    orders,
    previous_month_orders,

    ROUND(
        100.0 * (orders - previous_month_orders)
        / NULLIF(previous_month_orders, 0),
        2
    ) AS mom_order_growth_pct

FROM monthly_with_previous
ORDER BY order_month;


/*
LAG allows each month's performance to be compared with the previous month
without a self-join.
*/


-- ============================================================================
-- 26. MONTH-OVER-MONTH GMV GROWTH
-- Business question:
-- How quickly did merchandise value grow or contract month over month?
-- ============================================================================

WITH monthly_gmv AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
        SUM(i.price) AS merchandise_gmv
    FROM orders AS o
    INNER JOIN order_items AS i
        ON o.order_id = i.order_id
    WHERE o.order_purchase_timestamp >= DATE '2017-01-01'
      AND o.order_purchase_timestamp <  DATE '2018-09-01'
    GROUP BY 1
),

monthly_with_previous AS (
    SELECT
        order_month,
        merchandise_gmv,

        LAG(merchandise_gmv) OVER (
            ORDER BY order_month
        ) AS previous_month_gmv

    FROM monthly_gmv
)

SELECT
    order_month,
    ROUND(merchandise_gmv, 2) AS merchandise_gmv,
    ROUND(previous_month_gmv, 2) AS previous_month_gmv,

    ROUND(
        100.0 * (merchandise_gmv - previous_month_gmv)
        / NULLIF(previous_month_gmv, 0),
        2
    ) AS mom_gmv_growth_pct

FROM monthly_with_previous
ORDER BY order_month;



