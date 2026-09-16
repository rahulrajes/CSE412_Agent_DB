from app.graph.state import GraphState
from app.intent.classifier import IntentClassifier
from app.db.database import SessionLocal
from app.semantic.repository import SemanticRepository
from app.semantic.retrieval import SemanticRetrieval
from app.semantic.compiler import SemanticCompiler
from sqlalchemy import text

intent_classifier = IntentClassifier()
semantic_compiler = SemanticCompiler()


def classify_intent_node(state: GraphState) -> dict:
    question = state["question"]

    intent = intent_classifier.classify(question)

    return {
        "intent": intent
    }

def retrieve_semantic_context_node(state: GraphState) -> dict:
    intent = state["intent"]

    db = SessionLocal()

    try:
        repository = SemanticRepository(db)
        retrieval = SemanticRetrieval(repository)

        context = retrieval.retrieve(intent)

        return {
            "semantic_context": context
        }
    
    finally:
            db.close()

def compile_sql_node(state: GraphState) -> dict:
    context = state["semantic_context"]

    sql = semantic_compiler.compile(context)

    return {
        "sql": sql
    }

def execute_sql_node(state: GraphState) -> dict:
    sql = state["sql"]

    db = SessionLocal()

    try:
        rows = db.execute(
            text(sql)
        ).mappings().all()

        result = [
            dict(row)
            for row in rows
        ]

        return {
            "result": result
        }

    finally:
        db.close()

