import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Carbon Footprint Tracker"
    API_V1_STR: str = "/api/v1"
    
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

settings = Settings()
