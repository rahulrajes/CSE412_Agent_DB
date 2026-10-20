# Phase 2 Demo Runbook (psql console)

Everything runs in the PostgreSQL console inside Docker. Total time is about 10 minutes.

## Before the demo (do this ahead of time)

1. Start Docker Desktop.
2. Make sure `.env` has `POSTGRES_PASSWORD` set (copy `.env.example` if needed).
3. Make sure the 9 Olist CSVs are in `brazil_olist_dataset/`.
4. Rebuild the database. This takes about 15 seconds:

```bash
scripts/setup_db.sh
```

The script runs, in order:

| File | What it does |
|---|---|
| `sql/01_olist_schema.sql` | DDL for the 9 physical tables (schema `olist`) |
| `sql/02_semantic_schema.sql` | DDL for the 5 semantic-layer tables (schema `semantic`) |
| `sql/03_load_olist.sql` | `\copy` + `INSERT` to load about 1.55M rows, then a row-count check |
| `sql/04_semantic_seed.sql` | `INSERT`s that define the business concepts |

## During the demo

Open the console:

```bash
docker compose exec postgres psql -U rahul_rajesh -d semanticdb
```

Inside psql, `\x auto` makes wide rows readable. The SQL files are mounted at `/sql`.

### 1. Show the relational schema (ER → DDL)

```sql
\dn
\dt olist.*
\dt semantic.*
\d olist.order_items
\d semantic.metrics
```

Talking points:
- `order_items` and `payments` are weak entities, so each has a composite PK made of the owning order plus a sequence number.
- `synonyms text[]` is how the multivalued attribute is stored.
- Each metric's FK on `(semantic_model_id, entity_id)` guarantees the entity belongs to the same model.

### 2. Show the data import

Optionally re-run the load live: `\i /sql/03_load_olist.sql`. It finishes with a row-count check. Then show each table:

```sql
SELECT * FROM olist.customers            LIMIT 5;
SELECT * FROM olist.sellers              LIMIT 5;
SELECT * FROM olist.products             LIMIT 5;
SELECT * FROM olist.category_translation LIMIT 5;
SELECT * FROM olist.orders               LIMIT 5;
SELECT * FROM olist.order_items          LIMIT 5;
SELECT * FROM olist.payments             LIMIT 5;
SELECT * FROM olist.reviews              LIMIT 5;
SELECT * FROM olist.geolocation          LIMIT 5;

SELECT * FROM semantic.semantic_models;
SELECT name, physical_table, primary_key, grain FROM semantic.entities;
SELECT name, expression, aggregation, synonyms FROM semantic.metrics;
SELECT name, physical_column, data_type, synonyms FROM semantic.dimensions;
SELECT * FROM semantic.relationships;
```

### 3. Show the data types and constraints

These four inserts each fail on purpose, showing that types and constraints protect the data:

```sql
-- review_score is smallint CHECK (1..5)
INSERT INTO olist.reviews (review_id, order_id, review_score, review_creation_date)
VALUES ('x', 'e481f51cbdc54678b7cc49136f2d6af7', 6, now());

-- payment_type is restricted to the 5 known methods
INSERT INTO olist.payments VALUES ('e481f51cbdc54678b7cc49136f2d6af7', 9, 'pix', 1, 10.00);

-- foreign key: an item must belong to an existing order
INSERT INTO olist.order_items VALUES ('no_such_order', 1,
  '310ae3c140ff94b03219ad0adc3c778f', 'a416b6a846a11724393025641d4edd5e', now(), 10.00, 1.00);

-- semantic layer: aggregation must be one the compiler supports
INSERT INTO semantic.metrics (semantic_model_id, entity_id, name, expression, aggregation, metric_type)
SELECT semantic_model_id, id, 'Bad', 'price', 'median', 'average'
FROM semantic.entities WHERE name = 'Order Item';
```

### 4. Show the queries (SELECT, INSERT, UPDATE, DELETE)

Run the whole file:

```sql
\i /sql/05_queries.sql
```

Or run it section by section. The rubric maps to the file like this:

| Rubric item | Section in `05_queries.sql` |
|---|---|
| Two SELECT queries (1.5) | A. Q1–Q5, the proposal questions. B. Semantic-term lookups. C. Reconciliation. |
| INSERT (1) | D1 adds the metric *Average Item Price*. D2 records a new order with an item and a payment. |
| UPDATE (1) | E1 adds the synonym "gross sales". E2 publishes model v2. E3 marks the order delivered. |
| DELETE (0.5) | F1 retires the *Product Photo Count* dimension. F2 deletes the demo order, and its items and payments cascade. |

Every modifying statement is followed by a SELECT that shows the result.

### Reset after the demo

```sql
\i /sql/04_semantic_seed.sql
```

This restores the semantic layer. Re-running `05_queries.sql` removes its own demo order first, so it can be run repeatedly.

## Expected answers (for checking)

| Question | Top rows |
|---|---|
| Q1 Sales by seller state | SP 8,753,396.21 · PR 1,261,887.21 · MG 1,011,564.74 (23 states) |
| Q2 Payment value by type | credit_card 12,542,084.19 · boleto 2,869,361.27 · voucher 379,436.87 · debit_card 217,989.79 · not_defined 0.00 |
| Q3 Sales by category | health_beauty 1,258,681.34 · watches_gifts 1,205,005.68 · bed_bath_table 1,036,988.68 |
| Q4 Orders by status | delivered 96,478 · shipped 1,107 · canceled 625 · unavailable 609 · invoiced 314 · processing 301 · created 5 · approved 2 |
| Q5 Avg review by status | delivered 4.156 · approved 2.500 · created 2.333 · shipped 2.009 · … · processing 1.277 |
