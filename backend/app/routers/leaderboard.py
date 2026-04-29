from fastapi import APIRouter, Query
from app.models.user import UserResponse
from app import db_ops

router = APIRouter()


@router.get("", response_model=list[UserResponse])
def get_leaderboard(limit: int = Query(20, ge=1, le=100), city: str | None = Query(None)):
    users = db_ops.get_all_users_ranked(limit, city)
    return [
        UserResponse(
            id=u["id"], name=u["name"], avatar_initials=u["avatar_initials"],
            green_coins=u.get("green_coins", 0), total_co2_saved=u.get("total_co2_saved", 0),
            streak_days=u.get("streak_days", 0), rank=i, city=u.get("city", ""),
        ) for i, u in enumerate(users, 1)
    ]
