from langchain_google_genai import ChatGoogleGenerativeAI

from app.config import settings
from app.intent.models import UserIntent


class IntentClassifier:

    def __init__(self):
        self.llm = ChatGoogleGenerativeAI(
            model="gemini-3.6-flash",
            google_api_key=settings.gemini_api_key,
)

        self.structured_llm = self.llm.with_structured_output(
            UserIntent
        )

    def classify(self, question: str) -> UserIntent:

        prompt = f"""
You are an analytics user-intent classifier.

Analyze the user's question and return structured intent.

Allowed intents:

- metric_query:
  User wants a single metric or value.

- breakdown:
  User wants a metric grouped by a dimension.

- comparison:
  User wants to compare values.

- trend:
  User wants a metric over time.

- definition:
  User is asking what a metric or dimension means.

- unknown:
  The request does not fit the above categories.

Extract the exact business terms used by the user.

Do not translate synonyms into canonical names.
Do not invent metrics or dimensions.

Example:

User question:
Show me sales by geography

Result:
intent = breakdown
metrics = ["sales"]
dimensions = ["geography"]

User question:

{question}
"""

        return self.structured_llm.invoke(prompt)