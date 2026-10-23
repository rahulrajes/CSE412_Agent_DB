# Part B — Loading the data

**Presenter:** _____  **Time:** about 2.5 minutes
**Rubric:** Import data and `SELECT *` from tables (3 pt)

**Goal:** show where the data came from, load it with COPY/INSERT statements,
and prove the tables are full.

---

## 1. Where the data comes from

**Say (before running anything):**
> "Our store data is integrated open data: the public Olist Brazilian
> e-commerce dataset from Kaggle. It's 9 CSV files with about 100,000 real
> orders from 2016 to 2018."

---

## 2. Load it live

```sql
\i /sql/03_load_olist.sql
```

It takes about 10 seconds. **Say while it runs:**
> "This file loads every CSV with a COPY statement. It loads parent tables
> before child tables, customers before orders and orders before order items,
> so every foreign key is checked as rows arrive. It's all one transaction: if
> a single row broke a rule, nothing would be saved."

When the row-count table appears, **say:**
> "That's about 1.55 million rows, and every table matches the source file
> exactly. That's the `ok` column."

**Point at the `INSERT 0 2` line near the top:**
> "Kaggle's translation file was missing English names for 2 categories, so we
> added them with INSERT statements. Without them, 13 products would have
> failed the foreign key to the category table."

---

## 3. Show the tables are full

```sql
SELECT * FROM olist.orders LIMIT 5;
```
> "One row per order, with its status and the timestamps of its lifecycle."

```sql
SELECT * FROM olist.order_items LIMIT 5;
```
> "Each item in an order, with its product, seller, price and shipping charge."

```sql
SELECT * FROM olist.payments LIMIT 5;
```
> "How each order was paid: credit card, boleto, voucher and so on."

---

## 4. Show the dictionary is full

```sql
SELECT name, aggregation, expression, synonyms FROM semantic.metrics;
```

**Say:**
> "This is our dictionary. Nobody gives you this data, so we wrote every row
> ourselves as INSERT statements in `04_semantic_seed.sql`. Each metric says
> which column to use, which math to apply, and which words people use for it.
> So 'product revenue' always means the sum of item prices, and the AI never
> has to guess."

**Hand off:**
> "[Person C] will show how we chose the data types and how the database
> enforces them."

---

## If the TA asks…

**"Show me another table."** Any of these work:
```sql
SELECT * FROM olist.customers LIMIT 5;
SELECT * FROM olist.products LIMIT 5;
SELECT * FROM olist.sellers LIMIT 5;
SELECT * FROM olist.reviews LIMIT 5;
SELECT * FROM semantic.dimensions LIMIT 5;
SELECT * FROM semantic.relationships;
```

**"How many rows in total?"**
> "1,550,924 across the 9 store tables. Geolocation alone is about a million of
> those. The semantic layer has 39 rows across its 5 tables."

**"Why COPY and not INSERT for the store data?"**
> "COPY is PostgreSQL's bulk-load statement. It loads a whole file at once,
> which is how you'd load 1.5 million rows. We used INSERT where we were
> writing rows by hand: the dictionary and the 2 missing categories."

**"What's `\copy` vs `COPY`?"**
> "`\copy` is psql's version. It reads the file through the console, so the
> file doesn't have to be on the database server."
