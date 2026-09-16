#!/usr/bin/env bash

set -e

CONTAINER="semantic_model-postgres-1"
DB_USER="rahul_rajesh"
DB_NAME="semanticdb"
DATA_DIR="brazil_olist_dataset"

echo "Loading Olist customers..."
docker exec -i "$CONTAINER" \
  psql -U "$DB_USER" -d "$DB_NAME" \
  -c "\copy olist.customers FROM STDIN WITH (FORMAT csv, HEADER true)" \
  < "$DATA_DIR/olist_customers_dataset.csv"

echo "Loading Olist orders..."
docker exec -i "$CONTAINER" \
  psql -U "$DB_USER" -d "$DB_NAME" \
  -c "\copy olist.orders FROM STDIN WITH (FORMAT csv, HEADER true)" \
  < "$DATA_DIR/olist_orders_dataset.csv"

echo "Loading Olist products..."
docker exec -i "$CONTAINER" \
  psql -U "$DB_USER" -d "$DB_NAME" \
  -c "\copy olist.products FROM STDIN WITH (FORMAT csv, HEADER true)" \
  < "$DATA_DIR/olist_products_dataset.csv"

echo "Loading Olist sellers..."
docker exec -i "$CONTAINER" \
  psql -U "$DB_USER" -d "$DB_NAME" \
  -c "\copy olist.sellers FROM STDIN WITH (FORMAT csv, HEADER true)" \
  < "$DATA_DIR/olist_sellers_dataset.csv"

echo "Loading Olist order items..."
docker exec -i "$CONTAINER" \
  psql -U "$DB_USER" -d "$DB_NAME" \
  -c "\copy olist.order_items FROM STDIN WITH (FORMAT csv, HEADER true)" \
  < "$DATA_DIR/olist_order_items_dataset.csv"

echo "Loading Olist payments..."
docker exec -i "$CONTAINER" \
  psql -U "$DB_USER" -d "$DB_NAME" \
  -c "\copy olist.payments FROM STDIN WITH (FORMAT csv, HEADER true)" \
  < "$DATA_DIR/olist_order_payments_dataset.csv"

echo "Loading Olist reviews..."
docker exec -i "$CONTAINER" \
  psql -U "$DB_USER" -d "$DB_NAME" \
  -c "\copy olist.reviews (
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
  ) FROM STDIN WITH (FORMAT csv, HEADER true)" \
  < "$DATA_DIR/olist_order_reviews_dataset.csv"

echo "Loading category translations..."
docker exec -i "$CONTAINER" \
  psql -U "$DB_USER" -d "$DB_NAME" \
  -c "\copy olist.category_translation FROM STDIN WITH (FORMAT csv, HEADER true)" \
  < "$DATA_DIR/product_category_name_translation.csv"

echo "Loading geolocation..."
docker exec -i "$CONTAINER" \
  psql -U "$DB_USER" -d "$DB_NAME" \
  -c "\copy olist.geolocation (
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
  ) FROM STDIN WITH (FORMAT csv, HEADER true)" \
  < "$DATA_DIR/olist_geolocation_dataset.csv"

echo "Olist data loaded successfully."
