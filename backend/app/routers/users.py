from fastapi import APIRouter, Depends, HTTPException

from app.auth import get_current_user
from app.models.user import UserResponse, UserUpdate
from app import db_ops

router = APIRouter()


@router.get("/me", response_model=UserResponse)
def get_me(user_id: str = Depends(get_current_user)):
    user = db_ops.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    rank = db_ops.get_user_rank(user_id)
    return UserResponse(
        id=user["id"], name=user["name"], avatar_initials=user["avatar_initials"],
        green_coins=user.get("green_coins", 0), total_co2_saved=user.get("total_co2_saved", 0),
        streak_days=user.get("streak_days", 0), rank=rank, city=user.get("city", ""),
    )


@router.patch("/me", response_model=UserResponse)
def update_me(body: UserUpdate, user_id: str = Depends(get_current_user)):
    updates = {}
    if body.name is not None:
        updates["name"] = body.name
        parts = body.name.strip().split()
        updates["avatar_initials"] = "".join(p[0].upper() for p in parts[:2]) if parts else "?"
    if body.city is not None:
        updates["city"] = body.city
    if not updates:
        raise HTTPException(status_code=400, detail="No fields to update")

    user = db_ops.update_user(user_id, updates)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    rank = db_ops.get_user_rank(user_id)
    return UserResponse(
        id=user["id"], name=user["name"], avatar_initials=user["avatar_initials"],
        green_coins=user.get("green_coins", 0), total_co2_saved=user.get("total_co2_saved", 0),
        streak_days=user.get("streak_days", 0), rank=rank, city=user.get("city", ""),
    )
