from decimal import Decimal
from uuid import UUID
from mcp.server.mcpserver import MCPServer

from app.graph.graph import build_graph


mcp = MCPServer("semantic-model")

graph = build_graph()


def make_json_safe(value):
    if isinstance(value, Decimal):
        return float(value)

    if isinstance(value, UUID):
        return str(value)

    if isinstance(value, dict):
        return {
            key: make_json_safe(item)
            for key, item in value.items()
        }

    if isinstance(value, list):
        return [
            make_json_safe(item)
            for item in value
        ]

    return value


@mcp.tool()
def ask_data(question: str) -> dict:
    """Ask a natural-language question about the business data."""

    result = graph.invoke({
        "question": question
    })

    return {
        "question": question,
        "intent": make_json_safe(
            result["intent"].model_dump()
        ),
        "sql": result["sql"],
        "data": make_json_safe(
            result["result"]
        ),
    }


if __name__ == "__main__":
    mcp.run()