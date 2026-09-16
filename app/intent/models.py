from typing import Literal

from pydantic import BaseModel, Field


class UserIntent(BaseModel):
    intent: Literal[
        "metric_query",
        "breakdown",
        "comparison",
        "trend",
        "definition",
        "unknown",
    ]

    metrics: list[str] = Field(default_factory=list)

    dimensions: list[str] = Field(default_factory=list)