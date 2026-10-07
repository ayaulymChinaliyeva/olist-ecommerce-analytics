# Olist E-Commerce Analytics

End-to-end e-commerce analytics project built with **PostgreSQL, SQL, DBeaver, Git/GitHub**, using the public Olist Brazilian E-Commerce dataset.

The project demonstrates relational database design, data cleaning and validation, analytical SQL, data modelling, and business analysis.

## Project Objective

The objective is to transform raw transactional e-commerce data into a structured PostgreSQL database and analyze:

- commercial performance and growth;
- customers, products, and sellers;
- payments and order economics;
- fulfillment performance and customer satisfaction.

## Tech Stack

- PostgreSQL
- DBeaver
- SQL
- Git & GitHub
- Power BI — planned dashboard layer

## Data Model

The database contains:

- `customers`
- `orders`
- `order_items`
- `products`
- `sellers`
- `order_payments`
- `order_reviews`
- `geolocation`
- `product_category_name_translation`

Primary and foreign keys were implemented where supported by the source data.

The tables operate at different grains. For example, `orders` contains one row per order, while `order_items` and `order_payments` can contain multiple rows per order.

Customer-level analysis uses `customer_unique_id` rather than `customer_id` to identify customers across multiple purchases.

## Data Preparation

The raw data was imported into PostgreSQL and validated before analysis.

Preparation included:

- defining primary and foreign keys;
- implementing composite keys where required;
- validating table relationships;
- normalizing empty product categories;
- staging and deduplicating review data;
- investigating unmatched records between related tables;
- validating customer and order identifiers;
- retaining incomplete product-category translations without removing valid product records.

The raw review dataset contained duplicate records. A staging and deduplication process reduced it to a clean analytical table.

## Analytical Window

The source contains orders from September 2016 through October 2018.

The beginning and end of the dataset contain sparse coverage, so the primary time-series reporting window is:

**January 2017 through August 2018**

```sql
order_purchase_timestamp >= DATE '2017-01-01'
AND order_purchase_timestamp < DATE '2018-09-01'
```

This provides a continuous full-month analytical period.

## KPI Definitions

### Merchandise GMV

```sql
SUM(order_items.price)
```

This represents gross merchandise value recorded in order items.

It is not treated as Olist accounting revenue because the dataset does not provide the full commission, seller payout, refund, and accounting structure required to calculate company revenue.

### Freight Value

```sql
SUM(order_items.freight_value)
```

### Total Order Value

```sql
SUM(order_items.price + order_items.freight_value)
```

### Average Order Value

```text
Merchandise GMV / distinct orders represented in order_items
```

### Customer Payment Value

```sql
SUM(order_payments.payment_value)
```

Payment value is analyzed separately from merchandise GMV because the two measures represent different business concepts.

## Analysis

The SQL analysis covers:

- monthly order volume and GMV;
- average order value;
- month-over-month growth;
- order status and cancellation analysis;
- product-category performance;
- category GMV concentration;
- unique and repeat customers;
- customer purchase frequency and value;
- customer geography;
- seller performance and concentration;
- payment-method mix;
- installment behavior;
- merchandise value vs. payment reconciliation;
- delivery performance;
- on-time delivery rate;
- review-score distribution;
- relationship between delivery performance and customer reviews.

## Preventing Join-Induced Metric Errors

Both `order_items` and `order_payments` can contain multiple records for the same order.

Joining them directly by `order_id` can create a many-to-many multiplication within an order and artificially inflate monetary values.

The analysis therefore pre-aggregates one-to-many tables to the required grain before combining their measures.

## Selected Findings

Order activity expanded substantially during 2017.

Monthly orders increased from approximately **800 in January 2017 to more than 7,500 in November 2017**, while merchandise GMV increased from approximately **R$120K to more than R$1.0M**.

Average order value remained considerably more stable than total GMV, indicating that much of the GMV increase was associated with higher transaction volume rather than a comparable increase in merchandise value per order.

November 2017 represents a particularly large increase in both order volume and merchandise GMV relative to adjacent months. The analysis identifies this pattern without assigning a cause that cannot be established from the dataset alone.

Relationship validation also identified **739 orders without corresponding item records** during the analytical window:

- 602 unavailable
- 132 canceled
- 5 created

No delivered orders were present in this unmatched group, indicating that the missing item relationships are associated with order lifecycle status rather than unexplained missing completed transactions.

## Repository Structure

```text
olist-ecommerce-analytics/
│
├── database/
│   ├── 01_create_tables.sql
│   ├── 02_data_cleaning.sql
│   └── 03_data_quality_check.sql
│
├── sql/
│   └── 04_relationship_check.sql
│
├── analysis/
│   └── 01_business_analysis.sql
│
├── powerbi/
├── docs/
├── data/
│   └── raw/
│
├── .gitignore
└── README.md
```

Raw source data is excluded from version control.

## SQL Techniques Demonstrated

- relational joins
- CTEs
- conditional aggregation
- `COUNT(DISTINCT ...)`
- `CASE`
- `FILTER`
- `DATE_TRUNC`
- date arithmetic
- window functions
- `LAG`
- `DENSE_RANK`
- cumulative calculations
- `PERCENTILE_CONT`
- `COALESCE`
- `NULLIF`
- grain-aware aggregation
- data-quality validation
- relationship validation

## Data Source

Olist Brazilian E-Commerce Public Dataset.

The dataset contains anonymized Brazilian marketplace transactions and is used for educational and portfolio purposes.

## Project Status

- [x] PostgreSQL database setup
- [x] Data import
- [x] Data cleaning
- [x] Data-quality validation
- [x] Relationship validation
- [x] Business analysis
- [x] Analytical SQL
- [ ] Power BI data model
- [ ] Power BI dashboard
- [ ] Final dashboard screenshots
