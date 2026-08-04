from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    GEMINI_API_KEY: str = "mock_gemini_key"
    FIREBASE_CREDENTIALS_PATH: str = "firebase-service-account.json"
    FIREBASE_STORAGE_BUCKET: str = "resqai-fc260.firebasestorage.app"
    ENV: str = "development"
    LOG_LEVEL: str = "INFO"

    class Config:
        env_file = ".env"
        extra = "ignore"


@lru_cache
def get_settings() -> Settings:
    return Settings()
