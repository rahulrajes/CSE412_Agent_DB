-- ============================================================
-- 03  Load the Olist dataset into the physical layer
--
-- Run from psql:   \i sql/03_load_olist.sql
-- CSVs are read from :datadir (default: brazil_olist_dataset,
-- relative to where psql was started). Inside the Docker container
-- the folder is mounted at /data:  psql -v datadir=/data ...
--
-- Tables are loaded parents-first so every foreign key is checked
-- as rows arrive. The whole load is one transaction.
-- ============================================================

\if :{?datadir}
\else
    \set datadir brazil_olist_dataset
\endif

\set ON_ERROR_STOP on
-- \copy does not expand psql variables, so change into the data folder
-- and come back afterwards.
\set startdir `pwd`
\cd :datadir

BEGIN;

TRUNCATE olist.geolocation, olist.reviews, olist.payments, olist.order_items,
         olist.orders, olist.products, olist.sellers, olist.customers,
         olist.category_translation
    RESTART IDENTITY;

\echo 'Loading category translations...'
\copy olist.category_translation FROM 'product_category_name_translation.csv' WITH (FORMAT csv, HEADER true)

-- Two categories used by products are missing from the source
-- translation file. Add them so products -> category_translation
-- (BelongsTo) can be enforced.
INSERT INTO olist.category_translation (product_category_name, product_category_name_english)
VALUES
    ('pc_gamer', 'pc_gamer'),
    ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_preparers');

\echo 'Loading customers...'
\copy olist.customers FROM 'olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true)

\echo 'Loading sellers...'
\copy olist.sellers FROM 'olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true)

\echo 'Loading products...'
\copy olist.products FROM 'olist_products_dataset.csv' WITH (FORMAT csv, HEADER true)

\echo 'Loading orders...'
\copy olist.orders FROM 'olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true)

\echo 'Loading order items...'
\copy olist.order_items FROM 'olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true)

\echo 'Loading payments...'
\copy olist.payments FROM 'olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true)

\echo 'Loading reviews...'
\copy olist.reviews (review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp) FROM 'olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true)

\echo 'Loading geolocation (1M rows, takes a few seconds)...'
\copy olist.geolocation (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state) FROM 'olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true)

COMMIT;

ANALYZE olist.category_translation, olist.customers, olist.sellers, olist.products,
        olist.orders, olist.order_items, olist.payments, olist.reviews, olist.geolocation;

\cd :startdir

-- Row-count check (expected values from the source CSVs)
SELECT t.table_name, t.row_count, t.expected,
       CASE WHEN t.row_count = t.expected THEN 'ok' ELSE 'MISMATCH' END AS status
FROM (
    SELECT 'category_translation' AS table_name, (SELECT count(*) FROM olist.category_translation) AS row_count, 73      AS expected
    UNION ALL SELECT 'customers',   (SELECT count(*) FROM olist.customers),   99441
    UNION ALL SELECT 'sellers',     (SELECT count(*) FROM olist.sellers),     3095
    UNION ALL SELECT 'products',    (SELECT count(*) FROM olist.products),    32951
    UNION ALL SELECT 'orders',      (SELECT count(*) FROM olist.orders),      99441
    UNION ALL SELECT 'order_items', (SELECT count(*) FROM olist.order_items), 112650
    UNION ALL SELECT 'payments',    (SELECT count(*) FROM olist.payments),    103886
    UNION ALL SELECT 'reviews',     (SELECT count(*) FROM olist.reviews),     99224
    UNION ALL SELECT 'geolocation', (SELECT count(*) FROM olist.geolocation), 1000163
) AS t;
