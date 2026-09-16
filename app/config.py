from pydantic_settings import BaseSettings, SettingsConfigDict
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
ENV_FILE = BASE_DIR / ".env"

class Settings(BaseSettings):
    database_url: str
    openai_api_key: str = ""
    gemini_api_key: str = ""

    embedding_model: str = "text-embedding-3-small"
    embedding_dimensions: int = 1536
    model_name: str = "gpt-4.1-mini"

    model_config = SettingsConfigDict(
        env_file=ENV_FILE,
        env_file_encoding="utf-8",
    )


settings = Settings()