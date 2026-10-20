-- ============================================================
-- 05  Example queries for the analytics assistant
--
-- Run from psql:   \i sql/05_queries.sql
-- Sections:
--   A. The five proposal questions, written the way the agent's
--      compiler produces them from the semantic layer (SELECT)
--   B. Semantic-layer lookups the agent performs (SELECT)
--   C. Monetary reconciliation, the motivation for the semantic layer
--   D. INSERT  - add a metric to the semantic layer; record a new order
--   E. UPDATE  - add a synonym, publish the model, advance the order
--   F. DELETE  - retire a dimension, remove the demo order
--
-- Sections D-F modify data. To restore the original semantic layer
-- afterwards, re-run \i sql/04_semantic_seed.sql.
-- ============================================================

\set ON_ERROR_STOP on
\pset null '(null)'

-- Clear leftovers from a previous run so this file can be re-run.
DELETE FROM semantic.metrics WHERE name = 'Average Item Price';
DELETE FROM olist.orders     WHERE order_id    = 'demo_order_000000000000000000001';
DELETE FROM olist.customers  WHERE customer_id = 'demo_customer_000000000000000001';


-- ============================================================
-- A. The five proposal questions
-- ============================================================

\echo '--- Q1. What were total product sales by seller state?'
-- Metric Product Sales = SUM(order_items.price); dimension Seller State.
-- One-hop join Order Item -> Seller.
SELECT s.seller_state,
       SUM(oi.price) AS product_sales
FROM olist.order_items oi
JOIN olist.sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_state
ORDER BY product_sales DESC;

\echo '--- Q2. How does payment value break down across payment types?'
-- Metric Payment Value = SUM(payments.payment_value); same-entity breakdown.
SELECT p.payment_type,
       SUM(p.payment_value) AS payment_value,
       COUNT(*)             AS payment_records
FROM olist.payments p
GROUP BY p.payment_type
ORDER BY payment_value DESC;

\echo '--- Q3. What are total product sales by product category?'
-- One-hop join Order Item -> Product, plus Product -> Category Translation
-- for the English name. 610 products have no category.
SELECT COALESCE(ct.product_category_name_english, '(uncategorized)') AS product_category,
       SUM(oi.price) AS product_sales
FROM olist.order_items oi
JOIN olist.products p                  ON oi.product_id = p.product_id
LEFT JOIN olist.category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY 1
ORDER BY product_sales DESC
LIMIT 15;

\echo '--- Q4. How many orders were placed in each order status?'
-- Metric Order Count = COUNT(DISTINCT orders.order_id).
SELECT o.order_status,
       COUNT(DISTINCT o.order_id) AS order_count
FROM olist.orders o
GROUP BY o.order_status
ORDER BY order_count DESC;

\echo '--- Q5. What is the average review score by order status?'
-- Metric Average Review Score = AVG(reviews.review_score).
-- One-hop join Review -> Order.
SELECT o.order_status,
       ROUND(AVG(r.review_score), 3) AS average_review_score,
       COUNT(*)                      AS review_count
FROM olist.reviews r
JOIN olist.orders o ON r.order_id = o.order_id
GROUP BY o.order_status
ORDER BY average_review_score DESC;


-- ============================================================
-- B. Semantic-layer lookups (what lookup_semantic_term does)
-- ============================================================

\echo '--- B1. Resolve the user term "payment method" to a dimension'
-- Matches the canonical name or any synonym (uses the GIN index).
SELECT d.name AS dimension, e.name AS entity,
       e.physical_table, d.physical_column, d.data_type
FROM semantic.dimensions d
JOIN semantic.entities e ON d.entity_id = e.id
WHERE lower(d.name) = 'payment method'
   OR d.synonyms @> ARRAY['payment method'];

\echo '--- B2. Resolve the user term "product revenue" to a metric'
SELECT m.name AS metric, e.name AS entity, e.physical_table,
       m.aggregation, m.expression, m.description
FROM semantic.metrics m
JOIN semantic.entities e ON m.entity_id = e.id
WHERE lower(m.name) = 'product revenue'
   OR m.synonyms @> ARRAY['product revenue'];

\echo '--- B3. Find the join between the metric entity and the dimension entity'
SELECT f.name AS from_entity, t.name AS to_entity,
       r.relationship_type, r.join_sql
FROM semantic.relationships r
JOIN semantic.entities f ON r.from_entity_id = f.id
JOIN semantic.entities t ON r.to_entity_id = t.id
WHERE f.name = 'Order Item' AND t.name = 'Seller';

\echo '--- B4. Full catalog: every metric with its physical mapping'
SELECT m.name AS metric,
       CASE m.aggregation
           WHEN 'count_distinct' THEN 'COUNT(DISTINCT '
           ELSE upper(m.aggregation) || '('
       END || e.physical_table || '.' || m.expression || ')' AS computed_as,
       array_to_string(m.synonyms, ', ') AS synonyms
FROM semantic.metrics m
JOIN semantic.entities e ON m.entity_id = e.id
ORDER BY m.name;


-- ============================================================
-- C. Why three monetary metrics instead of one "revenue"
-- ============================================================

\echo '--- C1. Totals of the three monetary fields'
SELECT (SELECT SUM(price)          FROM olist.order_items) AS product_sales,
       (SELECT SUM(freight_value)  FROM olist.order_items) AS freight_charges,
       (SELECT SUM(price + freight_value) FROM olist.order_items) AS sales_plus_freight,
       (SELECT SUM(payment_value)  FROM olist.payments)    AS payment_value;

\echo '--- C2. Orders where items + freight do not match payments (top 10 gaps)'
-- Aggregate each side per order first to avoid item x payment fan-out.
WITH items AS (
    SELECT order_id, SUM(price + freight_value) AS item_total
    FROM olist.order_items GROUP BY order_id
), pays AS (
    SELECT order_id, SUM(payment_value) AS paid_total
    FROM olist.payments GROUP BY order_id
)
SELECT i.order_id, i.item_total, p.paid_total,
       p.paid_total - i.item_total AS difference
FROM items i
JOIN pays p ON i.order_id = p.order_id
WHERE abs(p.paid_total - i.item_total) > 0.01
ORDER BY abs(p.paid_total - i.item_total) DESC
LIMIT 10;


-- ============================================================
-- D. INSERT
-- ============================================================

\echo '--- D1. Analyst adds a new metric to the semantic layer'
INSERT INTO semantic.metrics (semantic_model_id, entity_id, name, description,
                              expression, aggregation, metric_type, synonyms)
SELECT e.semantic_model_id, e.id,
       'Average Item Price',
       'Average price of a single order item, excluding freight.',
       'price', 'avg', 'average',
       ARRAY['average item price', 'average price', 'avg price', 'mean item price']
FROM semantic.entities e
WHERE e.name = 'Order Item';

SELECT name, aggregation, expression, synonyms
FROM semantic.metrics
WHERE name = 'Average Item Price';

\echo '--- D2. Record a new order: customer, order, one item, one payment'
INSERT INTO olist.customers (customer_id, customer_unique_id, customer_zip_code_prefix,
                             customer_city, customer_state)
VALUES ('demo_customer_000000000000000001', 'demo_unique_customer_00000000001',
        '01310', 'sao paulo', 'SP');

INSERT INTO olist.orders (order_id, customer_id, order_status, order_purchase_timestamp,
                          order_approved_at, order_estimated_delivery_date)
VALUES ('demo_order_000000000000000000001', 'demo_customer_000000000000000001',
        'shipped', '2018-10-01 10:30:00', '2018-10-01 11:00:00', '2018-10-15');

INSERT INTO olist.order_items (order_id, order_item_id, product_id, seller_id,
                               shipping_limit_date, price, freight_value)
VALUES ('demo_order_000000000000000000001', 1,
        '310ae3c140ff94b03219ad0adc3c778f', 'a416b6a846a11724393025641d4edd5e',
        '2018-10-05 10:30:00', 145.95, 18.20);

INSERT INTO olist.payments (order_id, payment_sequential, payment_type,
                            payment_installments, payment_value)
VALUES ('demo_order_000000000000000000001', 1, 'credit_card', 3, 164.15);

SELECT o.order_id, o.order_status, oi.price, oi.freight_value,
       p.payment_type, p.payment_value
FROM olist.orders o
JOIN olist.order_items oi ON oi.order_id = o.order_id
JOIN olist.payments p     ON p.order_id  = o.order_id
WHERE o.order_id = 'demo_order_000000000000000000001';


-- ============================================================
-- E. UPDATE
-- ============================================================

\echo '--- E1. Add a new synonym so "gross sales" resolves to Product Sales'
UPDATE semantic.metrics
SET synonyms = array_append(synonyms, 'gross sales')
WHERE name = 'Product Sales'
  AND NOT synonyms @> ARRAY['gross sales'];

SELECT name, synonyms FROM semantic.metrics WHERE name = 'Product Sales';

\echo '--- E2. Publish the semantic model as a new version'
UPDATE semantic.semantic_models
SET status = 'published',
    version = version + 1
WHERE name = 'Olist Commerce Model';

SELECT name, version, status FROM semantic.semantic_models;

\echo '--- E3. The demo order is delivered'
UPDATE olist.orders
SET order_status = 'delivered',
    order_delivered_carrier_date  = '2018-10-03 09:00:00',
    order_delivered_customer_date = '2018-10-09 16:45:00'
WHERE order_id = 'demo_order_000000000000000000001';

SELECT order_id, order_status, order_delivered_customer_date, order_estimated_delivery_date
FROM olist.orders
WHERE order_id = 'demo_order_000000000000000000001';


-- ============================================================
-- F. DELETE
-- ============================================================

\echo '--- F1. Retire a dimension the analysts do not use'
DELETE FROM semantic.dimensions
WHERE name = 'Product Photo Count';

SELECT count(*) AS remaining_dimensions FROM semantic.dimensions;

\echo '--- F2. Remove the demo order (items and payments cascade), then its customer'
DELETE FROM olist.orders
WHERE order_id = 'demo_order_000000000000000000001';

DELETE FROM olist.customers
WHERE customer_id = 'demo_customer_000000000000000001';

SELECT (SELECT count(*) FROM olist.orders      WHERE order_id = 'demo_order_000000000000000000001') AS orders_left,
       (SELECT count(*) FROM olist.order_items WHERE order_id = 'demo_order_000000000000000000001') AS items_left,
       (SELECT count(*) FROM olist.payments    WHERE order_id = 'demo_order_000000000000000000001') AS payments_left;
