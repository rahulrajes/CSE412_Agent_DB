# Olist Physical Data Model

## Purpose

This document describes the physical structure, grain, keys,
relationships, and known modeling considerations of the Olist
e-commerce dataset.

The physical data model is distinct from the semantic model.

The physical model describes how the source data is stored.

The semantic model will later describe the business meaning of
entities, dimensions, metrics, and relationships.

---

## Orders

**Source:** `olist_orders_dataset.csv`

**Grain:** One row per order.

**Row count:** 99,441

**Primary key:** `order_id`

**Foreign keys:**
- `customer_id` -> `customers.customer_id`

**Important attributes:**
- `order_status`
- `order_purchase_timestamp`
- `order_approved_at`
- `order_delivered_carrier_date`
- `order_delivered_customer_date`
- `order_estimated_delivery_date`

**Observed properties:**
- 99,441 distinct order IDs
- 0 missing order IDs

---

## Customers

**Source:** `olist_customers_dataset.csv`

**Grain:** One order-associated customer record.

**Row count:** 99,441

**Primary key:** `customer_id`

**Business customer identifier:** `customer_unique_id`

**Important attributes:**
- `customer_unique_id`
- `customer_zip_code_prefix`
- `customer_city`
- `customer_state`

**Observed properties:**
- 99,441 distinct `customer_id` values
- 96,096 distinct `customer_unique_id` values
- Every `orders.customer_id` matched a customer record

**Important modeling note:**

`customer_id` identifies the customer record associated with an order.
`customer_unique_id` should be used when reasoning about distinct
underlying customers.

---

## Order Items

**Source:** `olist_order_items_dataset.csv`

**Grain:** One item within an order.

**Row count:** 112,650

**Primary key:** (`order_id`, `order_item_id`)

**Foreign keys:**
- `order_id` -> `orders.order_id`
- `product_id` -> `products.product_id`
- `seller_id` -> `sellers.seller_id`

**Important attributes:**
- `shipping_limit_date`
- `price`
- `freight_value`

**Observed properties:**
- 98,666 distinct orders represented
- Maximum 21 item rows for one order
- 775 orders have no order-item rows
- Most orders without items are unavailable or canceled

**Important modeling note:**

Joining Orders to Order Items changes grain from order-level to
item-level and can cause order-level measures to fan out.

---

## Products

**Source:** `olist_products_dataset.csv`

**Grain:** One row per product.

**Row count:** 32,951

**Primary key:** `product_id`

**Important attributes:**
- `product_category_name`
- `product_name_lenght`
- `product_description_lenght`
- `product_photos_qty`
- `product_weight_g`
- `product_length_cm`
- `product_height_cm`
- `product_width_cm`

**Observed properties:**
- 32,951 distinct product IDs
- Every order-item product ID matched a product

---

## Sellers

**Source:** `olist_sellers_dataset.csv`

**Grain:** One row per seller.

**Row count:** 3,095

**Primary key:** `seller_id`

**Important attributes:**
- `seller_zip_code_prefix`
- `seller_city`
- `seller_state`

**Observed properties:**
- 3,095 distinct seller IDs
- Every order-item seller ID matched a seller
- Maximum observed 2,033 order-item rows for one seller

---

## Payments

**Source:** `olist_order_payments_dataset.csv`

**Grain:** One payment sequence within an order.

**Row count:** 103,886

**Primary key:** (`order_id`, `payment_sequential`)

**Foreign key:**
- `order_id` -> `orders.order_id`

**Important attributes:**
- `payment_type`
- `payment_installments`
- `payment_value`

**Observed properties:**
- 99,440 distinct orders represented
- Maximum 29 payment rows for one order

**Important modeling note:**

Order Items and Payments are independent one-to-many relationships
from Orders. Joining both directly can create multiplicative fanout.

---

## Reviews

**Source:** `olist_order_reviews_dataset.csv`

**Grain:** One source review record associated with an order.

**Row count:** 99,224

**Primary key:** Surrogate key required.

**Source identifiers:**
- `review_id`
- `order_id`

**Important attributes:**
- `review_score`
- `review_comment_title`
- `review_comment_message`
- `review_creation_date`
- `review_answer_timestamp`

**Observed properties:**
- 98,410 distinct review IDs
- 98,673 distinct order IDs
- 789 review IDs occur multiple times
- 547 orders have multiple review rows
- Maximum 3 review rows for one order

**Important modeling note:**

`review_id` is not unique and therefore should not be used as the
database primary key without additional processing.

---

## Product Category Translation

**Source:** `product_category_name_translation.csv`

**Purpose:** Maps Portuguese product-category values to English
category values.

Example:

`esporte_lazer` -> `sports_leisure`

This is business data rather than semantic metadata.

---

## Geolocation

**Source:** `olist_geolocation_dataset.csv`

**Grain:** One geolocation observation associated with a ZIP prefix.

**Row count:** 1,000,163

**Observed properties:**
- 19,015 distinct ZIP prefixes
- 8,011 distinct city strings
- 27 states
- 17,972 ZIP prefixes have multiple rows
- Maximum 1,146 rows for one ZIP prefix

**Important modeling note:**

The raw geolocation table should not be joined directly into analytics
queries by ZIP prefix because doing so can cause extreme fanout.

A derived location dimension with one row per ZIP prefix should be
considered later.

---

## Monetary Fields

The dataset currently exposes several different monetary concepts:

- `order_items.price`
- `order_items.freight_value`
- `order_payments.payment_value`

Observed totals:

- Product price: 13,591,643.70
- Freight: 2,251,909.54
- Product + freight: 15,843,553.24
- Payment value: 16,008,872.12

For orders represented in both Items and Payments, most orders
reconcile closely between product + freight and payment value, but
the concepts should remain semantically distinct.

A generic Revenue metric should not be defined until its business
meaning is explicitly chosen.

---

## Relationship Summary

Customer Record -> Order:
- observed effectively one-to-one through `customer_id`

Underlying Customer -> Customer Record:
- one-to-many through `customer_unique_id`

Order -> Order Item:
- one-to-zero-or-many

Order Item -> Product:
- many-to-one

Order Item -> Seller:
- many-to-one

Order -> Payment:
- one-to-many

Order -> Review:
- one-to-zero-or-many

Product -> Category Translation:
- many-to-one by category name

---

## Known Modeling Risks

### Fanout

Joining multiple one-to-many tables can multiply rows.

Example:

An order with 2 items and 3 payment records can produce:

2 x 3 = 6 joined rows

if Order Items and Payments are joined directly through Orders.

### Business identifiers vs physical identifiers

`customer_id` is a physical customer-record identifier.

`customer_unique_id` represents the underlying customer identity and
is more appropriate for metrics such as distinct customer count.

### Semantic ambiguity

Several concepts have similar physical representations:

- Customer State
- Seller State

Likewise, monetary concepts such as Product Sales and Payment Value
must not be treated as interchangeable without explicit business
definitions.
