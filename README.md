# CSE 412 — Olist Analytics Assistant

An LLM analytics assistant for a junior finance analyst, built on the public
[Olist Brazilian e-commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).
Questions are answered through a **semantic layer**: a dictionary of metrics,
dimensions and relationships stored in PostgreSQL, so the AI never guesses
which column a business term means.

Team: Rahul Rajesh, Mrinal Chopde, Mrida Igoor, Neha Kanjamala.

The database has two schemas:

| Schema | What it holds |
|---|---|
| `olist` | The 9 store tables from Kaggle (about 1.55M rows) |
| `semantic` | Our dictionary: `semantic_models`, `entities`, `metrics`, `dimensions`, `relationships` |

## Setup (Mac)

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and open it.
2. Clone the repo:
   ```bash
   git clone https://github.com/rahulrajes/CSE412_Agent_DB.git
   cd CSE412_Agent_DB
   ```
3. Download the dataset from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce),
   unzip it, and put the 9 `.csv` files in a folder named `brazil_olist_dataset/`
   inside the project. (CSVs are not stored in git.)
4. Create your settings file and set any password in place of `CHANGEME`:
   ```bash
   cp .env.example .env
   ```
5. Build the database (about 15 seconds after the first image download):
   ```bash
   scripts/setup_db.sh
   ```
6. Open the PostgreSQL console:
   ```bash
   docker compose exec postgres psql -U rahul_rajesh -d semanticdb
   ```

Next time, start the database with `docker compose up -d` and go straight to step 6.

## Files

| Path | What it does |
|---|---|
| `sql/01_olist_schema.sql` | Creates the `olist` schema: 9 tables with types, keys and constraints |
| `sql/02_semantic_schema.sql` | Creates the `semantic` schema: the 5 dictionary tables |
| `sql/03_load_olist.sql` | Loads the CSVs with `\copy` and checks row counts |
| `sql/04_semantic_seed.sql` | Fills the dictionary (rerun to reset it) |
| `sql/05_queries.sql` | Demo queries: the 5 proposal questions plus INSERT / UPDATE / DELETE |
| `scripts/setup_db.sh` | Rebuilds everything: runs `01` → `04` inside the container |
| `docker-compose.yml` | PostgreSQL 17 container; mounts the data at `/data` and SQL at `/sql` |
| `docs/phase2_demo.md` | Step-by-step psql demo runbook with expected answers |
| `docs/olist_data_model.md` | Notes on the raw data: grain, keys, fan-out risks |
| `Proposal - Phase 1.pdf` | Phase 1 proposal |
| `app/` | Early Python code for the AI agent (later phase, not used yet) |
