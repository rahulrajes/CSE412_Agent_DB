from typing import Any, TypedDict

from app.intent.models import UserIntent


class GraphState(TypedDict, total=False):
    question: str

    intent: UserIntent

    semantic_context: dict[str, Any]

    sql: str

    result: list[dict[str, Any]]

    error: str