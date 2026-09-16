from app.semantic.repository import SemanticRepository
from app.intent.models import UserIntent


class SemanticRetrieval:

    def __init__(self, repository: SemanticRepository):
        self.repository = repository

    def retrieve(self, intent: UserIntent):
        context = {
            "metrics": [],
            "dimensions": [],
            "relationships": [],
        }

        for metric_term in intent.metrics:
            metric = self.repository.find_metric(metric_term)

            if metric:
                context["metrics"].append(dict(metric))

        for dimension_term in intent.dimensions:
            dimension = self.repository.find_dimension(dimension_term)

            if dimension:
                context["dimensions"].append(dict(dimension))

        if context["metrics"] and context["dimensions"]:
            metric_entity = context["metrics"][0]["entity_name"]
            dimension_entity = context["dimensions"][0]["entity_name"]

            if metric_entity != dimension_entity:
                relationship = self.repository.find_relationship(
                    metric_entity,
                    dimension_entity,
                )
                if relationship:
                    context["relationships"].append(
                        dict(relationship)
                    )

        return context