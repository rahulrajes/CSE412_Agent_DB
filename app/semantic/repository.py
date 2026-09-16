from sqlalchemy import text


class SemanticRepository:

    def __init__(self, db):
        self.db = db

    def get_entities(self):
        query = text("""
            SELECT
                id,
                name,
                description,
                physical_table,
                primary_key
            FROM entities
            ORDER BY name
        """)

        return self.db.execute(query).mappings().all()

    def get_metrics(self):
        query = text("""
            SELECT
                metrics.id,
                metrics.name,
                metrics.description,
                metrics.expression,
                metrics.aggregation,
                metrics.synonyms,
                entities.name AS entity_name,
                entities.physical_table
            FROM metrics
            JOIN entities
                ON metrics.entity_id = entities.id
            ORDER BY metrics.name
        """)

        return self.db.execute(query).mappings().all()

    def get_dimensions(self):
        query = text("""
            SELECT
                dimensions.id,
                dimensions.name,
                dimensions.description,
                dimensions.physical_column,
                dimensions.data_type,
                dimensions.synonyms,
                entities.name AS entity_name,
                entities.physical_table
            FROM dimensions
            JOIN entities
                ON dimensions.entity_id = entities.id
            ORDER BY dimensions.name
        """)

        return self.db.execute(query).mappings().all()

    def get_relationships(self):
        query = text("""
            SELECT
                relationships.id,
                from_entity.name AS from_entity,
                to_entity.name AS to_entity,
                relationships.relationship_type,
                relationships.join_sql
            FROM relationships
            JOIN entities AS from_entity
                ON relationships.from_entity_id = from_entity.id
            JOIN entities AS to_entity
                ON relationships.to_entity_id = to_entity.id
            ORDER BY from_entity.name, to_entity.name
        """)

        return self.db.execute(query).mappings().all()

    def find_metric(self, term: str):
        query = text("""
            SELECT
                metrics.id,
                metrics.name,
                metrics.description,
                metrics.expression,
                metrics.aggregation,
                metrics.synonyms,
                entities.name AS entity_name,
                entities.physical_table
            FROM metrics
            JOIN entities
                ON metrics.entity_id = entities.id
            WHERE
                LOWER(metrics.name) = LOWER(:term)
                OR LOWER(:term) = ANY(
                    SELECT LOWER(unnest(metrics.synonyms))
                )
            LIMIT 1
        """)

        return self.db.execute(
            query,
            {"term": term}
        ).mappings().first()

    def find_dimension(self, term: str):
        query = text("""
            SELECT
                dimensions.id,
                dimensions.name,
                dimensions.description,
                dimensions.physical_column,
                dimensions.data_type,
                dimensions.synonyms,
                entities.name AS entity_name,
                entities.physical_table
            FROM dimensions
            JOIN entities
                ON dimensions.entity_id = entities.id
            WHERE
                LOWER(dimensions.name) = LOWER(:term)
                OR LOWER(:term) = ANY(
                    SELECT LOWER(unnest(dimensions.synonyms))
                )
            LIMIT 1
        """)

        return self.db.execute(
            query,
            {"term": term}
        ).mappings().first()

    def find_relationship(
        self,
        from_entity: str,
        to_entity: str
    ):
        query = text("""
            SELECT
                relationships.id,
                from_entity.name AS from_entity,
                to_entity.name AS to_entity,
                relationships.relationship_type,
                relationships.join_sql
            FROM relationships
            JOIN entities AS from_entity
                ON relationships.from_entity_id = from_entity.id
            JOIN entities AS to_entity
                ON relationships.to_entity_id = to_entity.id
            WHERE
                LOWER(from_entity.name) = LOWER(:from_entity)
                AND LOWER(to_entity.name) = LOWER(:to_entity)
            LIMIT 1
        """)

        return self.db.execute(
            query,
            {
                "from_entity": from_entity,
                "to_entity": to_entity,
            }
        ).mappings().first()