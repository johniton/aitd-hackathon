from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from core.config import settings
from db.database import engine, Base
from modules.activity.routes import router as activity_router

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Scalable backend for a carbon footprint tracking application.",
    version="1.0.0"
)

# Enable CORS for all origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(
    activity_router,
    prefix=f"{settings.API_V1_STR}/activity",
    tags=["activity"]
)

@app.get("/health")
def health_check():
    return {"status": "ok"}
