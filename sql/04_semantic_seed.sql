-- ============================================================
-- 04  Semantic layer seed: Olist Commerce Model
--
-- Populates the five semantic tables with the business concepts the
-- agent can answer questions about. Run after 02_semantic_schema.sql.
--
-- Monetary ambiguity in Olist is handled by defining three distinct
-- metrics (Product Sales, Freight Charges, Payment Value) instead of
-- one generic "revenue" metric.
-- ============================================================

\set ON_ERROR_STOP on

BEGIN;

SET client_min_messages = warning;  -- hide TRUNCATE ... CASCADE notices
TRUNCATE semantic.semantic_models CASCADE;
RESET client_min_messages;

-- ------------------------------------------------------------
-- Semantic model
-- ------------------------------------------------------------
INSERT INTO semantic.semantic_models (name, description, version, status)
VALUES (
    'Olist Commerce Model',
    'Semantic model for Olist e-commerce revenue, payment, and order analytics.',
    1,
    'draft'
);


-- ------------------------------------------------------------
-- Entities
-- ------------------------------------------------------------
INSERT INTO semantic.entities (semantic_model_id, name, description, physical_table, primary_key, grain)
SELECT sm.id, v.name, v.description, v.physical_table, v.primary_key, v.grain
FROM semantic.semantic_models sm
CROSS JOIN (VALUES
    ('Customer',
     'Customer record associated with an order. customer_unique_id identifies the underlying customer across multiple purchases.',
     'olist.customers', 'customer_id',
     'One row per order-associated customer record'),
    ('Order',
     'Customer order and its lifecycle from purchase through fulfillment and delivery.',
     'olist.orders', 'order_id',
     'One row per order'),
    ('Order Item',
     'Individual product item sold within an order, including seller, product price, and freight value.',
     'olist.order_items', 'order_id, order_item_id',
     'One row per item within an order'),
    ('Product',
     'Product available in the marketplace, including category and physical product attributes.',
     'olist.products', 'product_id',
     'One row per product'),
    ('Category Translation',
     'English translation of a Portuguese product category name.',
     'olist.category_translation', 'product_category_name',
     'One row per product category'),
    ('Seller',
     'Marketplace seller responsible for selling an order item.',
     'olist.sellers', 'seller_id',
     'One row per seller'),
    ('Payment',
     'Payment record associated with an order, including payment method, installments, and payment value.',
     'olist.payments', 'order_id, payment_sequential',
     'One row per payment sequence within an order'),
    ('Review',
     'Customer review record associated with an order, including rating and optional written feedback.',
     'olist.reviews', 'review_row_id',
     'One row per source review record associated with an order')
) AS v(name, description, physical_table, primary_key, grain)
WHERE sm.name = 'Olist Commerce Model';


-- ------------------------------------------------------------
-- Relationships (business-level joins, all many-to-one)
-- ------------------------------------------------------------
INSERT INTO semantic.relationships (semantic_model_id, from_entity_id, to_entity_id, relationship_type, join_sql)
SELECT sm.id, from_e.id, to_e.id, v.relationship_type, v.join_sql
FROM semantic.semantic_models sm
JOIN (VALUES
    ('Order',      'Customer',             'many_to_one', 'olist.orders.customer_id = olist.customers.customer_id'),
    ('Order Item', 'Order',                'many_to_one', 'olist.order_items.order_id = olist.orders.order_id'),
    ('Order Item', 'Product',              'many_to_one', 'olist.order_items.product_id = olist.products.product_id'),
    ('Order Item', 'Seller',               'many_to_one', 'olist.order_items.seller_id = olist.sellers.seller_id'),
    ('Product',    'Category Translation', 'many_to_one', 'olist.products.product_category_name = olist.category_translation.product_category_name'),
    ('Payment',    'Order',                'many_to_one', 'olist.payments.order_id = olist.orders.order_id'),
    ('Review',     'Order',                'many_to_one', 'olist.reviews.order_id = olist.orders.order_id')
) AS v(from_entity, to_entity, relationship_type, join_sql) ON TRUE
JOIN semantic.entities from_e ON from_e.semantic_model_id = sm.id AND from_e.name = v.from_entity
JOIN semantic.entities to_e   ON to_e.semantic_model_id   = sm.id AND to_e.name   = v.to_entity
WHERE sm.name = 'Olist Commerce Model';


-- ------------------------------------------------------------
-- Dimensions
-- ------------------------------------------------------------
INSERT INTO semantic.dimensions (semantic_model_id, entity_id, name, description, physical_column, data_type, synonyms)
SELECT sm.id, e.id, v.name, v.description, v.physical_column, v.data_type, v.synonyms
FROM semantic.semantic_models sm
JOIN (VALUES
    ('Customer', 'Customer State',
     'Brazilian state associated with the customer who placed the order.',
     'customer_state', 'text',
     ARRAY['customer state', 'buyer state', 'customer region', 'buyer region']),
    ('Customer', 'Customer City',
     'City associated with the customer who placed the order.',
     'customer_city', 'text',
     ARRAY['customer city', 'buyer city', 'customer location', 'buyer location']),
    ('Customer', 'Customer ZIP Prefix',
     'ZIP code prefix associated with the customer who placed the order.',
     'customer_zip_code_prefix', 'text',
     ARRAY['customer zip', 'customer postal code', 'buyer zip', 'buyer postal code']),
    ('Order', 'Order Status',
     'Current lifecycle status of the order.',
     'order_status', 'text',
     ARRAY['order status', 'status', 'order state', 'fulfillment status']),
    ('Order', 'Order Purchase Time',
     'Timestamp when the customer placed the order.',
     'order_purchase_timestamp', 'timestamp',
     ARRAY['purchase date', 'purchase time', 'order date', 'order time', 'order purchase date']),
    ('Order', 'Order Delivery Time',
     'Timestamp when the order was delivered to the customer.',
     'order_delivered_customer_date', 'timestamp',
     ARRAY['delivery date', 'delivery time', 'delivered date', 'customer delivery date']),
    ('Order', 'Estimated Delivery Date',
     'Date the order was expected to be delivered to the customer.',
     'order_estimated_delivery_date', 'date',
     ARRAY['estimated delivery', 'expected delivery', 'estimated delivery date', 'expected delivery date']),
    ('Product', 'Product Category',
     'Category assigned to the product in the Olist product catalog (Portuguese source name).',
     'product_category_name', 'text',
     ARRAY['product category', 'category', 'product type', 'item category', 'merchandise category']),
    ('Product', 'Product Weight',
     'Weight of the product in grams.',
     'product_weight_g', 'integer',
     ARRAY['product weight', 'item weight', 'weight']),
    ('Product', 'Product Photo Count',
     'Number of product photos associated with the product listing.',
     'product_photos_qty', 'integer',
     ARRAY['product photos', 'photo count', 'number of photos', 'listing photos']),
    ('Category Translation', 'Product Category (English)',
     'English name of the product category.',
     'product_category_name_english', 'text',
     ARRAY['english category', 'category english', 'product category english', 'category name']),
    ('Seller', 'Seller State',
     'Brazilian state where the marketplace seller is located.',
     'seller_state', 'text',
     ARRAY['seller state', 'merchant state', 'seller region', 'merchant region']),
    ('Seller', 'Seller City',
     'City where the marketplace seller is located.',
     'seller_city', 'text',
     ARRAY['seller city', 'merchant city', 'seller location', 'merchant location']),
    ('Seller', 'Seller ZIP Prefix',
     'ZIP code prefix associated with the marketplace seller.',
     'seller_zip_code_prefix', 'text',
     ARRAY['seller zip', 'merchant zip', 'seller postal code', 'merchant postal code']),
    ('Payment', 'Payment Type',
     'Method used to pay for an order.',
     'payment_type', 'text',
     ARRAY['payment type', 'payment method', 'method of payment', 'how customers paid']),
    ('Payment', 'Payment Installments',
     'Number of installments associated with a payment.',
     'payment_installments', 'integer',
     ARRAY['installments', 'payment installments', 'installment count', 'number of installments']),
    ('Review', 'Review Score',
     'Customer review rating associated with an order.',
     'review_score', 'integer',
     ARRAY['review score', 'rating', 'customer rating', 'review rating', 'satisfaction score'])
) AS v(entity_name, name, description, physical_column, data_type, synonyms) ON TRUE
JOIN semantic.entities e ON e.semantic_model_id = sm.id AND e.name = v.entity_name
WHERE sm.name = 'Olist Commerce Model';


-- ------------------------------------------------------------
-- Metrics
-- ------------------------------------------------------------
INSERT INTO semantic.metrics (semantic_model_id, entity_id, name, description, expression, aggregation, metric_type, synonyms)
SELECT sm.id, e.id, v.name, v.description, v.expression, v.aggregation, v.metric_type, v.synonyms
FROM semantic.semantic_models sm
JOIN (VALUES
    ('Order Item', 'Product Sales',
     'Total value of products sold based on order item prices, excluding freight charges.',
     'price', 'sum', 'additive',
     ARRAY['product sales', 'sales', 'merchandise sales', 'item sales', 'product revenue']),
    ('Order Item', 'Freight Charges',
     'Total freight value associated with order items.',
     'freight_value', 'sum', 'additive',
     ARRAY['freight', 'freight charges', 'shipping charges', 'shipping cost', 'freight value']),
    ('Payment', 'Payment Value',
     'Total monetary value recorded across payment records.',
     'payment_value', 'sum', 'additive',
     ARRAY['payment value', 'payments', 'amount paid', 'paid amount', 'payment amount']),
    ('Order', 'Order Count',
     'Number of distinct customer orders.',
     'order_id', 'count_distinct', 'distinct_count',
     ARRAY['order count', 'orders', 'number of orders', 'total orders', 'purchase count']),
    ('Customer', 'Unique Customer Count',
     'Number of distinct underlying customers identified by customer_unique_id.',
     'customer_unique_id', 'count_distinct', 'distinct_count',
     ARRAY['customer count', 'unique customers', 'number of customers', 'distinct customers', 'buyers']),
    ('Review', 'Average Review Score',
     'Average customer review rating across review records.',
     'review_score', 'avg', 'average',
     ARRAY['average review score', 'average rating', 'customer satisfaction', 'mean review score', 'avg rating'])
) AS v(entity_name, name, description, expression, aggregation, metric_type, synonyms) ON TRUE
JOIN semantic.entities e ON e.semantic_model_id = sm.id AND e.name = v.entity_name
WHERE sm.name = 'Olist Commerce Model';

COMMIT;

-- Summary of what was seeded
SELECT 'entities' AS table_name, count(*) AS row_count FROM semantic.entities
UNION ALL SELECT 'relationships', count(*) FROM semantic.relationships
UNION ALL SELECT 'dimensions',    count(*) FROM semantic.dimensions
UNION ALL SELECT 'metrics',       count(*) FROM semantic.metrics;
