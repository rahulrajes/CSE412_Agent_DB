# Part D — The queries

**Presenter:** _____  **Time:** about 3 minutes
**Rubric:** two SELECTs (1.5 pt), INSERT (1 pt), UPDATE (1 pt), DELETE (0.5 pt)

**Goal:** run the five graded queries one at a time: two questions from our
proposal, then an INSERT, UPDATE and DELETE on our dictionary. Each change is
followed by a SELECT that shows it worked.

**Before you start:** the dictionary must be in its clean state, or the INSERT
fails with "duplicate key". If you've practiced since the last reset, run:

```sql
\i /sql/04_semantic_seed.sql
```

**Say first:**
> "These are questions from our proposal, written the way our agent will build
> them from the dictionary. Then we'll show how an analyst can change the
> dictionary itself with INSERT, UPDATE and DELETE."

---

## 1. SELECT #1 — Q1: total product sales by seller state

```sql
SELECT s.seller_state, SUM(oi.price) AS product_sales
FROM olist.order_items oi
JOIN olist.sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_state
ORDER BY product_sales DESC
LIMIT 5;
```

Expected: SP 8,753,396.21 · PR 1,261,887.21 · MG 1,011,564.74 · RJ 843,984.22 · SC 632,426.07

**Say:**
> "Q1 from our proposal. Product Sales comes from our dictionary as the sum of
> item prices. Seller State lives in a different table, so we join order items
> to sellers using the relationship stored in our dictionary. São Paulo sellers
> lead with about 8.75 million reais."

---

## 2. SELECT #2 — Q5: average review score by order status

```sql
SELECT o.order_status, ROUND(AVG(r.review_score), 3) AS average_review_score
FROM olist.reviews r
JOIN olist.orders o ON r.order_id = o.order_id
GROUP BY o.order_status
ORDER BY average_review_score DESC;
```

Expected: delivered 4.156 at the top · processing 1.277 at the bottom (8 rows)

**Say:**
> "Q5. This time the math is an average instead of a sum, across the join from
> reviews to orders. Delivered orders average 4.16 out of 5, and every other
> status is far lower, which makes sense: customers rate badly when they
> don't get their order."

---

## 3. INSERT — add a new metric to the dictionary

```sql
INSERT INTO semantic.metrics
    (semantic_model_id, entity_id, name, description, expression, aggregation, metric_type, synonyms)
SELECT e.semantic_model_id, e.id,
       'Average Item Price', 'Average price of one order item, excluding freight.',
       'price', 'avg', 'average', ARRAY['average item price', 'average price']
FROM semantic.entities e
WHERE e.name = 'Order Item';
```

Expected: `INSERT 0 1`

```sql
SELECT name, aggregation, expression, synonyms FROM semantic.metrics;
```

Expected: 7 metrics, with Average Item Price in the list.

**Say:**
> "An analyst wants a new metric, the average price of an item. We just insert
> one row into the dictionary, saying use the price column and take the
> average. The `SELECT … WHERE name = 'Order Item'` part looks up the entity it
> belongs to, so we don't have to type its ID. Now the system can answer
> 'what's the average price?', with no code changes."

---

## 4. UPDATE — teach an existing metric a new synonym

```sql
UPDATE semantic.metrics
SET synonyms = array_append(synonyms, 'gross sales')
WHERE name = 'Product Sales';
```

Expected: `UPDATE 1`

```sql
SELECT name, synonyms FROM semantic.metrics WHERE synonyms @> ARRAY['gross sales'];
```

Expected: one row, Product Sales, with "gross sales" at the end of its list.

**Say:**
> "Users also say 'gross sales', so we add it to Product Sales's synonym list.
> The check underneath searches the dictionary for 'gross sales', exactly like
> our agent will, and it now finds Product Sales."

---

## 5. DELETE — retire a dimension

```sql
DELETE FROM semantic.dimensions
WHERE name = 'Product Photo Count';
```

Expected: `DELETE 1`

```sql
SELECT count(*) AS dimensions_left FROM semantic.dimensions;
```

Expected: 16 (it was 17).

**Say:**
> "Finally, nobody asks about product photo counts, so we remove that
> dimension. The dictionary goes from 17 dimensions to 16, and the data itself
> is untouched. We only removed the definition."

---

## Closing (last presenter)

> "That covers our tables, our data, our data types and our queries. Our
> report has the rest of the queries, including Q2 to Q4. Thank you."

---

## After the demo or practice

These changes stay in the dictionary. Reset it before the next run:

```sql
\i /sql/04_semantic_seed.sql
```

---

## If the TA asks…

**"Show another proposal question."**
Q4 is the easiest to type:
```sql
SELECT order_status, COUNT(*) FROM olist.orders GROUP BY order_status;
```
Q2 has no join:
```sql
SELECT payment_type, SUM(payment_value) AS payment_value
FROM olist.payments GROUP BY payment_type ORDER BY payment_value DESC;
```

**"Can you show the rest?"**
```sql
\set ECHO queries
\i /sql/05_queries.sql
```
That runs every query in our report, each printed above its result.

**"What's `@>`?"**
> "It means 'contains': find the row whose synonym list contains this phrase."

**"What's `array_append`?"**
> "It adds one item to the end of a list column, here the synonyms list."

**"Why does Q5 average reviews and not orders?"**
> "547 orders have more than one review, so the average is over review rows.
> That's the kind of caveat our agent will mention to the user."

**"What if you ran the INSERT twice?"**
> "The second one fails. Metric names must be unique within a model, so the
> same metric can't be defined twice."
