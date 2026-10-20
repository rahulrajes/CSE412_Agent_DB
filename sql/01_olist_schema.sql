-- ============================================================
-- 01  Physical layer: Olist e-commerce schema
--
-- Nine tables at their native source grain, in schema "olist".
-- Re-runnable: drops and recreates the schema.
-- ============================================================

DROP SCHEMA IF EXISTS olist CASCADE;
CREATE SCHEMA olist;


-- ------------------------------------------------------------
-- Category translation (ER: Category)
-- Portuguese category name -> English category name.
-- ------------------------------------------------------------
CREATE TABLE olist.category_translation (
    product_category_name         text PRIMARY KEY,
    product_category_name_english text NOT NULL
);


-- ------------------------------------------------------------
-- Customers (ER: Customer)
-- One row per order-associated customer record.
-- customer_unique_id identifies the underlying person.
-- ------------------------------------------------------------
CREATE TABLE olist.customers (
    customer_id              text PRIMARY KEY,
    customer_unique_id       text NOT NULL,
    customer_zip_code_prefix char(5) NOT NULL,
    customer_city            text NOT NULL,
    customer_state           char(2) NOT NULL
);


-- ------------------------------------------------------------
-- Sellers (ER: Seller)
-- ------------------------------------------------------------
CREATE TABLE olist.sellers (
    seller_id              text PRIMARY KEY,
    seller_zip_code_prefix char(5) NOT NULL,
    seller_city            text NOT NULL,
    seller_state           char(2) NOT NULL
);


-- ------------------------------------------------------------
-- Products (ER: Product, BelongsTo Category)
-- Column names keep the source spelling ("lenght").
-- ------------------------------------------------------------
CREATE TABLE olist.products (
    product_id                 text PRIMARY KEY,
    product_category_name      text,
    product_name_lenght        integer CHECK (product_name_lenght >= 0),
    product_description_lenght integer CHECK (product_description_lenght >= 0),
    product_photos_qty         smallint CHECK (product_photos_qty >= 0),
    product_weight_g           integer CHECK (product_weight_g >= 0),
    product_length_cm          integer CHECK (product_length_cm >= 0),
    product_height_cm          integer CHECK (product_height_cm >= 0),
    product_width_cm           integer CHECK (product_width_cm >= 0),

    CONSTRAINT products_category_fk
        FOREIGN KEY (product_category_name)
        REFERENCES olist.category_translation(product_category_name)
);


-- ------------------------------------------------------------
-- Orders (ER: Order, Customer Places Order)
-- ------------------------------------------------------------
CREATE TABLE olist.orders (
    order_id                      text PRIMARY KEY,
    customer_id                   text NOT NULL,
    order_status                  text NOT NULL,
    order_purchase_timestamp      timestamp NOT NULL,
    order_approved_at             timestamp,
    order_delivered_carrier_date  timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date date NOT NULL,

    CONSTRAINT orders_customer_fk
        FOREIGN KEY (customer_id)
        REFERENCES olist.customers(customer_id),

    CONSTRAINT orders_status_chk
        CHECK (order_status IN (
            'created', 'approved', 'invoiced', 'processing',
            'shipped', 'delivered', 'canceled', 'unavailable'
        ))
);


-- ------------------------------------------------------------
-- Order items (ER: weak entity Order Item, Order Contains Item,
-- Item RefersTo Product, Item SoldBy Seller)
-- Identified by its owning order + sequence number.
-- ------------------------------------------------------------
CREATE TABLE olist.order_items (
    order_id            text NOT NULL,
    order_item_id       smallint NOT NULL CHECK (order_item_id >= 1),
    product_id          text NOT NULL,
    seller_id           text NOT NULL,
    shipping_limit_date timestamp NOT NULL,
    price               numeric(10,2) NOT NULL CHECK (price >= 0),
    freight_value       numeric(10,2) NOT NULL CHECK (freight_value >= 0),

    CONSTRAINT order_items_pkey
        PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT order_items_order_fk
        FOREIGN KEY (order_id)
        REFERENCES olist.orders(order_id)
        ON DELETE CASCADE,

    CONSTRAINT order_items_product_fk
        FOREIGN KEY (product_id)
        REFERENCES olist.products(product_id),

    CONSTRAINT order_items_seller_fk
        FOREIGN KEY (seller_id)
        REFERENCES olist.sellers(seller_id)
);


-- ------------------------------------------------------------
-- Payments (ER: weak entity Payment, Order HasPayment)
-- ------------------------------------------------------------
CREATE TABLE olist.payments (
    order_id             text NOT NULL,
    payment_sequential   smallint NOT NULL CHECK (payment_sequential >= 1),
    payment_type         text NOT NULL,
    payment_installments smallint NOT NULL CHECK (payment_installments >= 0),
    payment_value        numeric(10,2) NOT NULL CHECK (payment_value >= 0),

    CONSTRAINT payments_pkey
        PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT payments_order_fk
        FOREIGN KEY (order_id)
        REFERENCES olist.orders(order_id)
        ON DELETE CASCADE,

    CONSTRAINT payments_type_chk
        CHECK (payment_type IN (
            'credit_card', 'boleto', 'voucher', 'debit_card', 'not_defined'
        ))
);


-- ------------------------------------------------------------
-- Reviews (ER: Review, Order ReviewedBy Review)
-- review_id is not unique in the source, so a surrogate key is used.
-- ------------------------------------------------------------
CREATE TABLE olist.reviews (
    review_row_id           bigserial PRIMARY KEY,
    review_id               text NOT NULL,
    order_id                text NOT NULL,
    review_score            smallint NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title    text,
    review_comment_message  text,
    review_creation_date    timestamp NOT NULL,
    review_answer_timestamp timestamp,

    CONSTRAINT reviews_order_fk
        FOREIGN KEY (order_id)
        REFERENCES olist.orders(order_id)
        ON DELETE CASCADE
);


-- ------------------------------------------------------------
-- Geolocation (ER: Geolocation)
-- Many observations per ZIP prefix, so it is intentionally not
-- linked by foreign key: a ZIP-prefix join would fan out rows.
-- ------------------------------------------------------------
CREATE TABLE olist.geolocation (
    geolocation_row_id          bigserial PRIMARY KEY,
    geolocation_zip_code_prefix char(5) NOT NULL,
    geolocation_lat             double precision NOT NULL
        CHECK (geolocation_lat BETWEEN -90 AND 90),
    geolocation_lng             double precision NOT NULL
        CHECK (geolocation_lng BETWEEN -180 AND 180),
    geolocation_city            text NOT NULL,
    geolocation_state           char(2) NOT NULL
);


-- ------------------------------------------------------------
-- Indexes on foreign-key and lookup columns
-- ------------------------------------------------------------
CREATE INDEX orders_customer_idx         ON olist.orders (customer_id);
CREATE INDEX order_items_product_idx     ON olist.order_items (product_id);
CREATE INDEX order_items_seller_idx      ON olist.order_items (seller_id);
CREATE INDEX reviews_order_idx           ON olist.reviews (order_id);
CREATE INDEX products_category_idx       ON olist.products (product_category_name);
CREATE INDEX customers_unique_idx        ON olist.customers (customer_unique_id);
CREATE INDEX geolocation_zip_prefix_idx  ON olist.geolocation (geolocation_zip_code_prefix);
