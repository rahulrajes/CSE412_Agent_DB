
-- ============================================================
-- Olist Semantic Model V2
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE entities
ADD COLUMN IF NOT EXISTS grain text;

ALTER TABLE metrics
ADD COLUMN IF NOT EXISTS metric_type text;

INSERT INTO semantic_models (
    id,
    workspace_id,
    name,
    description,
    version,
    status
)
SELECT
    gen_random_uuid(),
    workspace_id,
    'Olist Commerce Model',
    'Semantic model for Olist e-commerce analytics',
    1,
    'draft'
FROM semantic_models
WHERE name = 'Sales Model'
  AND NOT EXISTS (
      SELECT 1
      FROM semantic_models
      WHERE name = 'Olist Commerce Model'
  )
LIMIT 1;

INSERT INTO entities (
    id,
    semantic_model_id,
    name,
    description,
    physical_table,
    primary_key,
    grain
)
SELECT
    gen_random_uuid(),
    sm.id,
    v.name,
    v.description,
    v.physical_table,
    v.primary_key,
    v.grain
FROM semantic_models sm
CROSS JOIN (
    VALUES
    (
        'Customer',
        'Customer record associated with an order. customer_unique_id identifies the underlying customer across multiple purchases.',
        'olist.customers',
        'customer_id',
        'One row per order-associated customer record'
    ),
    (
        'Order',
        'Customer order and its lifecycle from purchase through fulfillment and delivery.',
        'olist.orders',
        'order_id',
        'One row per order'
    ),
    (
        'Order Item',
        'Individual product item sold within an order, including seller, product price, and freight value.',
        'olist.order_items',
        'order_id, order_item_id',
        'One row per item within an order'
    ),
    (
        'Product',
        'Product available in the marketplace, including category and physical product attributes.',
        'olist.products',
        'product_id',
        'One row per product'
    ),
    (
        'Seller',
        'Marketplace seller responsible for selling an order item.',
        'olist.sellers',
        'seller_id',
        'One row per seller'
    ),
    (
        'Payment',
        'Payment record associated with an order, including payment method, installments, and payment value.',
        'olist.payments',
        'order_id, payment_sequential',
        'One row per payment sequence within an order'
    ),
    (
        'Review',
        'Customer review record associated with an order, including rating and optional written feedback.',
        'olist.reviews',
        'review_row_id',
        'One row per source review record associated with an order'
    )
) AS v(name, description, physical_table, primary_key, grain)
WHERE sm.name = 'Olist Commerce Model'
  AND NOT EXISTS (
      SELECT 1
      FROM entities e
      WHERE e.semantic_model_id = sm.id
        AND e.name = v.name
  );

-- ============================================================
-- Relationships
-- ============================================================

INSERT INTO relationships (
    id,
    semantic_model_id,
    from_entity_id,
    to_entity_id,
    relationship_type,
    join_sql
)
SELECT
    gen_random_uuid(),
    sm.id,
    from_e.id,
    to_e.id,
    v.relationship_type,
    v.join_sql
FROM semantic_models sm
JOIN (
    VALUES
        (
            'Order',
            'Customer',
            'many_to_one',
            'olist.orders.customer_id = olist.customers.customer_id'
        ),
        (
            'Order Item',
            'Order',
            'many_to_one',
            'olist.order_items.order_id = olist.orders.order_id'
        ),
        (
            'Order Item',
            'Product',
            'many_to_one',
            'olist.order_items.product_id = olist.products.product_id'
        ),
        (
            'Order Item',
            'Seller',
            'many_to_one',
            'olist.order_items.seller_id = olist.sellers.seller_id'
        ),
        (
            'Payment',
            'Order',
            'many_to_one',
            'olist.payments.order_id = olist.orders.order_id'
        ),
        (
            'Review',
            'Order',
            'many_to_one',
            'olist.reviews.order_id = olist.orders.order_id'
        )
) AS v(
    from_entity_name,
    to_entity_name,
    relationship_type,
    join_sql
)
    ON TRUE
JOIN entities from_e
    ON from_e.semantic_model_id = sm.id
   AND from_e.name = v.from_entity_name
JOIN entities to_e
    ON to_e.semantic_model_id = sm.id
   AND to_e.name = v.to_entity_name
WHERE sm.name = 'Olist Commerce Model'
  AND NOT EXISTS (
      SELECT 1
      FROM relationships r
      WHERE r.semantic_model_id = sm.id
        AND r.from_entity_id = from_e.id
        AND r.to_entity_id = to_e.id
  );

-- ============================================================
-- Dimensions
-- ============================================================

INSERT INTO dimensions (
    id,
    semantic_model_id,
    entity_id,
    name,
    description,
    physical_column,
    data_type,
    synonyms
)
SELECT
    gen_random_uuid(),
    sm.id,
    e.id,
    v.dimension_name,
    v.description,
    v.physical_column,
    v.data_type,
    v.synonyms
FROM semantic_models sm
JOIN (
    VALUES
        (
            'Customer',
            'Customer State',
            'Brazilian state associated with the customer who placed the order.',
            'customer_state',
            'text',
            ARRAY['customer state', 'buyer state', 'customer region', 'buyer region']::text[]
        ),
        (
            'Customer',
            'Customer City',
            'City associated with the customer who placed the order.',
            'customer_city',
            'text',
            ARRAY['customer city', 'buyer city', 'customer location', 'buyer location']::text[]
        ),
        (
            'Customer',
            'Customer ZIP Prefix',
            'ZIP code prefix associated with the customer who placed the order.',
            'customer_zip_code_prefix',
            'text',
            ARRAY['customer zip', 'customer postal code', 'buyer zip', 'buyer postal code']::text[]
        ),
        (
            'Order',
            'Order Status',
            'Current lifecycle status of the order.',
            'order_status',
            'text',
            ARRAY['order status', 'status', 'order state', 'fulfillment status']::text[]
        ),
        (
            'Order',
            'Order Purchase Time',
            'Timestamp when the customer placed the order.',
            'order_purchase_timestamp',
            'timestamp',
            ARRAY['purchase date', 'purchase time', 'order date', 'order time', 'order purchase date']::text[]
        ),
        (
            'Order',
            'Order Delivery Time',
            'Timestamp when the order was delivered to the customer.',
            'order_delivered_customer_date',
            'timestamp',
            ARRAY['delivery date', 'delivery time', 'delivered date', 'customer delivery date']::text[]
        ),
        (
            'Order',
            'Estimated Delivery Time',
            'Timestamp when the order was expected to be delivered to the customer.',
            'order_estimated_delivery_date',
            'timestamp',
            ARRAY['estimated delivery', 'expected delivery', 'estimated delivery date', 'expected delivery date']::text[]
        ),
        (
            'Product',
            'Product Category',
            'Category assigned to the product in the Olist product catalog.',
            'product_category_name',
            'text',
            ARRAY['product category', 'category', 'product type', 'item category', 'merchandise category']::text[]
        ),
        (
            'Product',
            'Product Weight',
            'Weight of the product in grams.',
            'product_weight_g',
            'integer',
            ARRAY['product weight', 'item weight', 'weight']::text[]
        ),
        (
            'Product',
            'Product Photo Count',
            'Number of product photos associated with the product listing.',
            'product_photos_qty',
            'integer',
            ARRAY['product photos', 'photo count', 'number of photos', 'listing photos']::text[]
        ),
        (
            'Seller',
            'Seller State',
            'Brazilian state where the marketplace seller is located.',
            'seller_state',
            'text',
            ARRAY['seller state', 'merchant state', 'seller region', 'merchant region']::text[]
        ),
        (
            'Seller',
            'Seller City',
            'City where the marketplace seller is located.',
            'seller_city',
            'text',
            ARRAY['seller city', 'merchant city', 'seller location', 'merchant location']::text[]
        ),
        (
            'Seller',
            'Seller ZIP Prefix',
            'ZIP code prefix associated with the marketplace seller.',
            'seller_zip_code_prefix',
            'text',
            ARRAY['seller zip', 'merchant zip', 'seller postal code', 'merchant postal code']::text[]
        ),
        (
            'Payment',
            'Payment Type',
            'Method used to pay for an order.',
            'payment_type',
            'text',
            ARRAY['payment type', 'payment method', 'method of payment', 'how customers paid']::text[]
        ),
        (
            'Payment',
            'Payment Installments',
            'Number of installments associated with a payment.',
            'payment_installments',
            'integer',
            ARRAY['installments', 'payment installments', 'installment count', 'number of installments']::text[]
        ),
        (
            'Review',
            'Review Score',
            'Customer review rating associated with an order.',
            'review_score',
            'integer',
            ARRAY['review score', 'rating', 'customer rating', 'review rating', 'satisfaction score']::text[]
        )
) AS v(
    entity_name,
    dimension_name,
    description,
    physical_column,
    data_type,
    synonyms
)
    ON TRUE
JOIN entities e
    ON e.semantic_model_id = sm.id
   AND e.name = v.entity_name
WHERE sm.name = 'Olist Commerce Model'
  AND NOT EXISTS (
      SELECT 1
      FROM dimensions d
      WHERE d.semantic_model_id = sm.id
        AND d.name = v.dimension_name
  );
-- ============================================================
-- Metrics
-- ============================================================

INSERT INTO metrics (
    id,
    semantic_model_id,
    entity_id,
    name,
    description,
    expression,
    aggregation,
    synonyms,
    metric_type
)
SELECT
    gen_random_uuid(),
    sm.id,
    e.id,
    v.metric_name,
    v.description,
    v.expression,
    v.aggregation,
    v.synonyms,
    v.metric_type
FROM semantic_models sm
JOIN (
    VALUES
        (
            'Order Item',
            'Product Sales',
            'Total value of products sold based on order item prices, excluding freight charges.',
            'price',
            'sum',
            ARRAY[
                'product sales',
                'sales',
                'merchandise sales',
                'item sales',
                'product revenue'
            ]::text[],
            'additive'
        ),
        (
            'Order Item',
            'Freight Charges',
            'Total freight value associated with order items.',
            'freight_value',
            'sum',
            ARRAY[
                'freight',
                'freight charges',
                'shipping charges',
                'shipping cost',
                'freight value'
            ]::text[],
            'additive'
        ),
        (
            'Payment',
            'Payment Value',
            'Total monetary value recorded across payment records.',
            'payment_value',
            'sum',
            ARRAY[
                'payment value',
                'payments',
                'amount paid',
                'paid amount',
                'payment amount'
            ]::text[],
            'additive'
        ),
        (
            'Order',
            'Order Count',
            'Number of distinct customer orders.',
            'order_id',
            'count_distinct',
            ARRAY[
                'order count',
                'orders',
                'number of orders',
                'total orders',
                'purchase count'
            ]::text[],
            'distinct_count'
        ),
        (
            'Customer',
            'Unique Customer Count',
            'Number of distinct underlying customers identified by customer_unique_id.',
            'customer_unique_id',
            'count_distinct',
            ARRAY[
                'customer count',
                'unique customers',
                'number of customers',
                'distinct customers',
                'buyers'
            ]::text[],
            'distinct_count'
        ),
        (
            'Review',
            'Average Review Score',
            'Average customer review rating across review records.',
            'review_score',
            'avg',
            ARRAY[
                'average review score',
                'average rating',
                'customer satisfaction',
                'mean review score',
                'avg rating'
            ]::text[],
            'average'
        )
) AS v(
    entity_name,
    metric_name,
    description,
    expression,
    aggregation,
    synonyms,
    metric_type
)
    ON TRUE
JOIN entities e
    ON e.semantic_model_id = sm.id
   AND e.name = v.entity_name
WHERE sm.name = 'Olist Commerce Model'
  AND NOT EXISTS (
      SELECT 1
      FROM metrics m
      WHERE m.semantic_model_id = sm.id
        AND m.name = v.metric_name
  );
