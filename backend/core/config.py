import os
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    PROJECT_NAME: str = "GoaGreen API"
    API_V1_STR: str = "/api/v1"

    # Supabase (required)
    SUPABASE_URL: str = ""
    SUPABASE_SERVICE_KEY: str = ""
    SUPABASE_JWT_SECRET: str = ""

    # Dev mode: when True, allows X-Dev-User-Id header to bypass JWT auth
    DEV_MODE: bool = True

    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"


settings = Settings()
