# Part C — Data types and rules

**Presenter:** _____  **Time:** about 2 minutes
**Rubric:** Information representation type checks (1 pt)

**Goal:** show each type was chosen from what the value means, and that the
database rejects bad data.

---

## 1. The types we chose

```sql
\d olist.payments
```

**Point at and say:**

| Point at | Say |
|---|---|
| `payment_value numeric(10,2)` | "Money is `numeric`, not float or real. Float is approximate, so adding 100,000 payments would drift by cents. Numeric is exact." |
| `payment_installments smallint` | "Installments is a small whole number, so `smallint`." |
| `payments_type_chk CHECK (payment_type = ANY ...)` | "Payment type can only be one of the 5 real values in the data." |
| `PRIMARY KEY (order_id, payment_sequential)` | "Payments is another weak entity: order ID plus payment number." |

**Then say the other choices out loud** (no command needed):
> "A few more choices:
> - ZIP codes are text, not numbers, because about 24,000 of them start with a
>   zero, which a number type would drop.
> - State codes are `char(2)`, always 2 letters like SP.
> - Review score is a `smallint` limited to 1 through 5.
> - Estimated delivery is a `date`, because it's always midnight in the source.
>   The other timestamps keep the time.
> - Latitude and longitude are `double precision`, since they're measurements."

---

## 2. The rules reject bad data

**Say first:**
> "These next two inserts are supposed to fail. That's the point."

```sql
INSERT INTO olist.reviews (review_id, order_id, review_score, review_creation_date)
VALUES ('x', 'e481f51cbdc54678b7cc49136f2d6af7', 6, now());
```
Expected: `ERROR: new row for relation "reviews" violates check constraint "reviews_review_score_check"`
> "A review score of 6 is rejected, because scores must be 1 to 5."

```sql
INSERT INTO olist.payments VALUES ('e481f51cbdc54678b7cc49136f2d6af7', 9, 'pix', 1, 10.00);
```
Expected: `ERROR: ... violates check constraint "payments_type_chk"`
> "And `pix` isn't one of the allowed payment types, so it's rejected too."

**Optional third, to show a foreign key at work:**
```sql
INSERT INTO olist.order_items VALUES ('no_such_order', 1,
  '310ae3c140ff94b03219ad0adc3c778f', 'a416b6a846a11724393025641d4edd5e', now(), 10.00, 1.00);
```
Expected: `ERROR: ... violates foreign key constraint "order_items_order_fk"`
> "An item for an order that doesn't exist is rejected by the foreign key."

**Hand off:**
> "Every one of the 1.55 million rows passed these rules when we loaded it.
> [Person D] will now show the queries our application runs."

---

## If the TA asks…

**"Why not `float` for money?"**
> "Float stores numbers in binary, so 0.1 can't be represented exactly and sums
> drift. `numeric` stores exact decimals, which is what you want for currency."

**"Why `text` for IDs?"**
> "The source IDs are 32-character codes like `e481f51c…`. They're labels, not
> numbers, and we kept them as-is so every row traces back to the CSV."

**"Why is `review_score` a smallint and not an integer?"**
> "It only holds 1 to 5, so the smallest integer type is enough. The CHECK
> constraint enforces the range."
