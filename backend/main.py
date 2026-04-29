from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from core.config import settings
from database import engine, Base
from modules.activity.routes import router as activity_router
from modules.tourism.routes import router as tourism_router

# Create database tables
try:
    Base.metadata.create_all(bind=engine)
except Exception:
    # Keep API alive even if external DB is temporarily unreachable.
    pass

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
app.include_router(
    tourism_router,
    prefix=f"{settings.API_V1_STR}/tourism",
    tags=["tourism"]
)

@app.get("/health")
def health_check():
    return {"status": "ok"}
