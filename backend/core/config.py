import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Carbon Footprint Tracker"
    API_V1_STR: str = "/api/v1"
    SUPABASE_DB_URL: str = "sqlite:///./carbon_tracker.db"
    GEMINI_API_KEY: str = ""
    OPENROUTER_API_KEY: str = ""
    GROQ_API_KEY: str = ""
    OPENWEATHERMAP_API_KEY: str = ""
    
    # Feature Registry
    FEATURES: dict[str, bool] = {
        "carbon": True,
        "suggestions": True,
        "simulation": True,
        "gamification": False,
        "community": False,
        "ml": False
    }

    class Config:
        case_sensitive = True
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
