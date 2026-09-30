-- ============================================================
-- OLIST E-COMMERCE ANALYTICS
-- 02_data_cleaning.sql
-- Documents cleaning applied to source data.
-- ============================================================


-- ------------------------------------------------------------
-- PRODUCT CATEGORIES
-- ------------------------------------------------------------

-- The source products data contains empty strings for missing
-- product categories.
-- Convert empty strings to proper SQL NULL values.

UPDATE products
SET product_category_name = NULL
WHERE product_category_name = '';


-- ------------------------------------------------------------
-- ORDER REVIEWS
-- ------------------------------------------------------------

-- Raw review data contains exact duplicate rows.
--
-- Raw reviews should first be loaded into a staging table
-- without PK/FK constraints.

CREATE TABLE order_reviews_staging (
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);


-- Insert only unique rows into the clean order_reviews table.

INSERT INTO order_reviews
SELECT DISTINCT *
FROM order_reviews_staging;