from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core.config import settings

# Import all routers
from app.routers import users, activities, leaderboard, house, business, subsidies, exchange, map

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="GoaGreen -- Carbon tracking API for Goa, India. Powered by Supabase.",
    version="1.0.0",
)

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Mount routers ────────────────────────────────────────────────────

PREFIX = settings.API_V1_STR

app.include_router(users.router,        prefix=f"{PREFIX}/users",        tags=["users"])
app.include_router(activities.router,    prefix=f"{PREFIX}/activities",   tags=["activities"])
app.include_router(leaderboard.router,   prefix=f"{PREFIX}/leaderboard",  tags=["leaderboard"])
app.include_router(house.router,         prefix=f"{PREFIX}/house",        tags=["house"])
app.include_router(business.router,      prefix=f"{PREFIX}/business",     tags=["business"])
app.include_router(subsidies.router,     prefix=f"{PREFIX}/subsidies",    tags=["subsidies"])
app.include_router(exchange.router,      prefix=f"{PREFIX}/exchange",     tags=["exchange"])
app.include_router(map.router,           prefix=f"{PREFIX}/map",          tags=["map"])


@app.get("/health")
def health_check():
    return {"status": "ok"}
