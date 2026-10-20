-- ============================================================
-- 02  Semantic layer: metadata tables, in schema "semantic"
--
-- Describes the business meaning of the physical layer. The agent
-- resolves user terms (names / synonyms) against these tables and
-- compiles SQL from the mappings they hold.
--
-- References into the physical layer (physical_table,
-- physical_column, expression, join_sql) are soft text references,
-- so metadata can be authored and versioned without touching data.
-- Re-runnable: drops and recreates the schema.
-- ============================================================

DROP SCHEMA IF EXISTS semantic CASCADE;
CREATE SCHEMA semantic;


-- ------------------------------------------------------------
-- Semantic model: a versioned collection of business definitions.
-- ------------------------------------------------------------
CREATE TABLE semantic.semantic_models (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id uuid NOT NULL DEFAULT gen_random_uuid(),
    name         text NOT NULL UNIQUE,
    description  text,
    version      integer NOT NULL DEFAULT 1 CHECK (version >= 1),
    status       text NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'published', 'archived'))
);


-- ------------------------------------------------------------
-- Entity: a business object backed by one physical table.
-- (ER: Semantic Model HAS ENTITY)
-- ------------------------------------------------------------
CREATE TABLE semantic.entities (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    semantic_model_id uuid NOT NULL
        REFERENCES semantic.semantic_models(id) ON DELETE CASCADE,
    name              text NOT NULL,
    description       text,
    physical_table    text NOT NULL,
    primary_key       text NOT NULL,
    grain             text NOT NULL,

    CONSTRAINT entities_name_uq UNIQUE (semantic_model_id, name),
    -- Lets metrics/dimensions/relationships check that the entity
    -- they point to belongs to the same semantic model.
    CONSTRAINT entities_model_id_uq UNIQUE (semantic_model_id, id)
);


-- ------------------------------------------------------------
-- Metric: an aggregated measure over an entity's column.
-- synonyms is the multivalued attribute from the ER diagram.
-- (ER: Semantic Model HAS METRIC, Entity DESCRIBES METRIC)
-- ------------------------------------------------------------
CREATE TABLE semantic.metrics (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    semantic_model_id uuid NOT NULL
        REFERENCES semantic.semantic_models(id) ON DELETE CASCADE,
    entity_id         uuid NOT NULL,
    name              text NOT NULL,
    description       text,
    expression        text NOT NULL,
    aggregation       text NOT NULL
        CHECK (aggregation IN ('sum', 'avg', 'count', 'count_distinct', 'min', 'max')),
    metric_type       text NOT NULL
        CHECK (metric_type IN ('additive', 'distinct_count', 'average', 'non_additive')),
    synonyms          text[] NOT NULL DEFAULT '{}',

    CONSTRAINT metrics_name_uq UNIQUE (semantic_model_id, name),
    CONSTRAINT metrics_entity_fk
        FOREIGN KEY (semantic_model_id, entity_id)
        REFERENCES semantic.entities(semantic_model_id, id)
        ON DELETE CASCADE
);


-- ------------------------------------------------------------
-- Dimension: an attribute of an entity used to group or filter.
-- (ER: Semantic Model HAS DIMENSION, Entity DESCRIBES DIMENSION)
-- ------------------------------------------------------------
CREATE TABLE semantic.dimensions (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    semantic_model_id uuid NOT NULL
        REFERENCES semantic.semantic_models(id) ON DELETE CASCADE,
    entity_id         uuid NOT NULL,
    name              text NOT NULL,
    description       text,
    physical_column   text NOT NULL,
    data_type         text NOT NULL
        CHECK (data_type IN ('text', 'integer', 'numeric', 'date', 'timestamp', 'boolean')),
    synonyms          text[] NOT NULL DEFAULT '{}',

    CONSTRAINT dimensions_name_uq UNIQUE (semantic_model_id, name),
    CONSTRAINT dimensions_entity_fk
        FOREIGN KEY (semantic_model_id, entity_id)
        REFERENCES semantic.entities(semantic_model_id, id)
        ON DELETE CASCADE
);


-- ------------------------------------------------------------
-- Relationship: a business-level join between two entities.
-- (ER: Semantic Model HAS RELATIONSHIP, FROM ENTITY, TO ENTITY)
-- ------------------------------------------------------------
CREATE TABLE semantic.relationships (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    semantic_model_id uuid NOT NULL
        REFERENCES semantic.semantic_models(id) ON DELETE CASCADE,
    from_entity_id    uuid NOT NULL,
    to_entity_id      uuid NOT NULL,
    relationship_type text NOT NULL
        CHECK (relationship_type IN ('one_to_one', 'one_to_many', 'many_to_one')),
    join_sql          text NOT NULL,

    CONSTRAINT relationships_pair_uq UNIQUE (semantic_model_id, from_entity_id, to_entity_id),
    CONSTRAINT relationships_distinct_chk CHECK (from_entity_id <> to_entity_id),
    CONSTRAINT relationships_from_fk
        FOREIGN KEY (semantic_model_id, from_entity_id)
        REFERENCES semantic.entities(semantic_model_id, id)
        ON DELETE CASCADE,
    CONSTRAINT relationships_to_fk
        FOREIGN KEY (semantic_model_id, to_entity_id)
        REFERENCES semantic.entities(semantic_model_id, id)
        ON DELETE CASCADE
);


-- ------------------------------------------------------------
-- Indexes for the agent's term lookups (name and synonym match)
-- ------------------------------------------------------------
CREATE INDEX metrics_name_lower_idx    ON semantic.metrics (lower(name));
CREATE INDEX dimensions_name_lower_idx ON semantic.dimensions (lower(name));
CREATE INDEX metrics_synonyms_gin      ON semantic.metrics USING gin (synonyms);
CREATE INDEX dimensions_synonyms_gin   ON semantic.dimensions USING gin (synonyms);
CREATE INDEX relationships_to_idx      ON semantic.relationships (to_entity_id);
