CREATE SCHEMA IF NOT EXISTS olist;


CREATE TABLE IF NOT EXISTS olist.customers (
    customer_id text PRIMARY KEY,
    customer_unique_id text NOT NULL,
    customer_zip_code_prefix text,
    customer_city text,
    customer_state text
);


CREATE TABLE IF NOT EXISTS olist.orders (
    order_id text PRIMARY KEY,
    customer_id text NOT NULL,
    order_status text NOT NULL,
    order_purchase_timestamp timestamp,
    order_approved_at timestamp,
    order_delivered_carrier_date timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp,

    CONSTRAINT orders_customer_fk
        FOREIGN KEY (customer_id)
        REFERENCES olist.customers(customer_id)
);


CREATE TABLE IF NOT EXISTS olist.products (
    product_id text PRIMARY KEY,
    product_category_name text,
    product_name_lenght integer,
    product_description_lenght integer,
    product_photos_qty integer,
    product_weight_g integer,
    product_length_cm integer,
    product_height_cm integer,
    product_width_cm integer
);


CREATE TABLE IF NOT EXISTS olist.sellers (
    seller_id text PRIMARY KEY,
    seller_zip_code_prefix text,
    seller_city text,
    seller_state text
);


CREATE TABLE IF NOT EXISTS olist.order_items (
    order_id text NOT NULL,
    order_item_id integer NOT NULL,
    product_id text NOT NULL,
    seller_id text NOT NULL,
    shipping_limit_date timestamp,
    price numeric(12,2) NOT NULL,
    freight_value numeric(12,2) NOT NULL,

    CONSTRAINT order_items_pkey
        PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT order_items_order_fk
        FOREIGN KEY (order_id)
        REFERENCES olist.orders(order_id),

    CONSTRAINT order_items_product_fk
        FOREIGN KEY (product_id)
        REFERENCES olist.products(product_id),

    CONSTRAINT order_items_seller_fk
        FOREIGN KEY (seller_id)
        REFERENCES olist.sellers(seller_id)
);


CREATE TABLE IF NOT EXISTS olist.payments (
    order_id text NOT NULL,
    payment_sequential integer NOT NULL,
    payment_type text NOT NULL,
    payment_installments integer NOT NULL,
    payment_value numeric(12,2) NOT NULL,

    CONSTRAINT payments_pkey
        PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT payments_order_fk
        FOREIGN KEY (order_id)
        REFERENCES olist.orders(order_id)
);


CREATE TABLE IF NOT EXISTS olist.reviews (
    review_row_id bigserial PRIMARY KEY,
    review_id text NOT NULL,
    order_id text NOT NULL,
    review_score integer NOT NULL,
    review_comment_title text,
    review_comment_message text,
    review_creation_date timestamp,
    review_answer_timestamp timestamp,

    CONSTRAINT reviews_order_fk
        FOREIGN KEY (order_id)
        REFERENCES olist.orders(order_id)
);


CREATE TABLE IF NOT EXISTS olist.category_translation (
    product_category_name text PRIMARY KEY,
    product_category_name_english text NOT NULL
);


CREATE TABLE IF NOT EXISTS olist.geolocation (
    geolocation_row_id bigserial PRIMARY KEY,
    geolocation_zip_code_prefix text NOT NULL,
    geolocation_lat double precision NOT NULL,
    geolocation_lng double precision NOT NULL,
    geolocation_city text,
    geolocation_state text
);
