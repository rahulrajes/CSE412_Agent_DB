class SemanticCompiler:

    def compile(self, context: dict) -> str:
        metrics = context["metrics"]
        dimensions = context["dimensions"]
        relationships = context["relationships"]

        if not metrics:
            raise ValueError("No metric found")

        if not dimensions:
            raise ValueError("No dimension found")

        metric = metrics[0]
        dimension = dimensions[0]

        metric_table = metric["physical_table"]
        metric_column = metric["expression"]
        aggregation = metric["aggregation"]

        dimension_table = dimension["physical_table"]
        dimension_column = dimension["physical_column"]

        metric_name = metric["name"].lower().replace(" ", "_")

        sql = f"""
SELECT
    {dimension_table}.{dimension_column},
    {aggregation.upper()}({metric_table}.{metric_column}) AS {metric_name}
FROM {metric_table}
"""

        if relationships:
            relationship = relationships[0]

            sql += f"""JOIN {dimension_table}
    ON {relationship["join_sql"]}
"""

        sql += f"""GROUP BY {dimension_table}.{dimension_column}
"""

        return sql.strip()