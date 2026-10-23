# Part A — The tables (ER diagram → DDL)

**Presenter:** _____  **Time:** about 2.5 minutes
**Rubric:** Table transformation for entities and relationships (3 pt) + % completion (1 pt)

**Goal:** show that both ER diagrams became real tables, and that entities, weak
entities and relationships each became the right thing (table, composite key,
foreign key).

---

## 0. Opening (first presenter only)

> "Our project is an AI analytics assistant for a junior finance analyst, using
> the Olist e-commerce dataset. The database has two layers: the real store data,
> and a dictionary we built that tells the AI what business terms mean. We'll
> show the tables, the data, the data types, and our queries."

---

## 1. The two schemas

```sql
\dn
```

**Say:**
> "We have two schemas, which are folders of tables. `olist` holds the store
> data. `semantic` holds our dictionary, which we call the semantic layer."

Ignore the `public` schema. It's an empty default every PostgreSQL database has.

---

## 2. The 14 tables

```sql
\dt olist.*
```

**Say:**
> "These 9 tables come from our first ER diagram, the physical layer: customers,
> orders, order items, payments, reviews, products, sellers, category
> translation and geolocation."

```sql
\dt semantic.*
```

**Say:**
> "These 5 tables come from our second ER diagram, the semantic layer: semantic
> models, entities, metrics, dimensions and relationships. That's 14 tables in
> total, all created with DDL in `01_olist_schema.sql` and `02_semantic_schema.sql`."

---

## 3. A weak entity and its relationships

```sql
\d olist.order_items
```

**Point at, top to bottom:**

| Point at | Say |
|---|---|
| The `Column / Type` list | "Each attribute in the ER diagram became a column with a type. Price is `numeric(10,2)`, exact money to the cent." |
| `PRIMARY KEY, btree (order_id, order_item_id)` | "Order items is a **weak entity**: it can't exist without its order. So its primary key is the order ID **plus** an item number: item 1, item 2 of that order." |
| The 3 lines under `Foreign-key constraints` | "These are our ER relationships. Each item points to its **order**, its **product** and its **seller**. The database rejects an item whose order doesn't exist." |
| `ON DELETE CASCADE` | "If an order is deleted, its items are deleted with it, because they can't exist on their own." |

Skip the two `btree` indexes unless asked. They only make joins faster.

---

## 4. The dictionary side

```sql
\d semantic.metrics
```

**Say:**
> "Our dictionary tables follow the second ER diagram. `synonyms` is a list
> column, `text[]`, which is how we stored the multivalued attribute. Each metric
> has a foreign key to the entity it describes and to its semantic model."

**Hand off:**
> "Now that the tables exist, [Person B] will show how we filled them with data."

---

## If the TA asks…

**"Why isn't geolocation linked to anything?"**
> "Geolocation has many rows per ZIP prefix, up to 1,146, so the prefix isn't
> unique and can't be a key. Joining on it would multiply rows. We load it but
> deliberately don't link it."

**"Why does reviews have a `review_row_id`?"**
> "The source `review_id` repeats, 789 duplicates, so it can't be a primary key.
> We added a generated surrogate key instead."

**"How many foreign keys are there?"**
> "Seven in the store data: orders→customers, order_items→orders, products and
> sellers, payments→orders, reviews→orders, and products→category_translation."

**"Why do the semantic tables point to `olist` by name instead of with foreign keys?"**
> "The dictionary describes the data, it isn't part of it. Storing table and
> column names as text lets us edit the dictionary without touching the data."
