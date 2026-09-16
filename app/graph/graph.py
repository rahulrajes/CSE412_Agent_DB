from langgraph.graph import StateGraph, START, END

from app.graph.state import GraphState
from app.graph.nodes import (
    classify_intent_node,
    retrieve_semantic_context_node,
    compile_sql_node,
    execute_sql_node,
)


def build_graph():
    builder = StateGraph(GraphState)

    builder.add_node(
        "classify_intent",
        classify_intent_node,
    )

    builder.add_node(
        "retrieve_semantic_context",
        retrieve_semantic_context_node,
    )

    builder.add_node(
        "compile_sql",
        compile_sql_node,
    )

    builder.add_node(
        "execute_sql",
        execute_sql_node,
    )

    builder.add_edge(
        START,
        "classify_intent",
    )

    builder.add_edge(
        "classify_intent",
        "retrieve_semantic_context",
    )

    builder.add_edge(
        "retrieve_semantic_context",
        "compile_sql",
    )

    builder.add_edge(
        "compile_sql",
        "execute_sql",
    )

    builder.add_edge(
        "execute_sql",
        END,
    )

    return builder.compile()