import uuid

from fastapi import APIRouter, Depends, HTTPException, Query

from app.auth import get_current_user
from app.models.user import UserResponse, UserUpdate, UserCreate
from app import db_ops

router = APIRouter()


@router.post("", response_model=UserResponse, status_code=201)
def register_user(body: UserCreate):
    parts = body.name.strip().split()
    initials = "".join(p[0].upper() for p in parts[:2]) if parts else "?"
    new_user = {
        "id": str(uuid.uuid4()),
        "name": body.name.strip(),
        "avatar_initials": initials,
        "city": body.city,
        "latitude": body.latitude,
        "longitude": body.longitude,
        "green_coins": 0,
        "total_co2_saved": 0,
        "streak_days": 0,
    }
    created = db_ops.create_user(new_user)
    return UserResponse(
        id=created["id"],
        name=created["name"],
        avatar_initials=created["avatar_initials"],
        green_coins=created.get("green_coins", 0),
        total_co2_saved=created.get("total_co2_saved", 0),
        streak_days=created.get("streak_days", 0),
        rank=0,
        city=created.get("city", ""),
        latitude=created.get("latitude"),
        longitude=created.get("longitude"),
    )


@router.get("/search", response_model=list[UserResponse])
def search_users(name: str = Query(..., min_length=1)):
    users = db_ops.search_users_by_name(name)
    result = []
    for u in users:
        rank = db_ops.get_user_rank(u["id"])
        result.append(UserResponse(
            id=u["id"], name=u["name"], avatar_initials=u["avatar_initials"],
            green_coins=u.get("green_coins", 0), total_co2_saved=u.get("total_co2_saved", 0),
            streak_days=u.get("streak_days", 0), rank=rank, city=u.get("city", ""),
            latitude=u.get("latitude"), longitude=u.get("longitude"),
        ))
    return result


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
        latitude=user.get("latitude"), longitude=user.get("longitude"),
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
    if body.latitude is not None:
        updates["latitude"] = body.latitude
    if body.longitude is not None:
        updates["longitude"] = body.longitude
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
        latitude=user.get("latitude"), longitude=user.get("longitude"),
    )
