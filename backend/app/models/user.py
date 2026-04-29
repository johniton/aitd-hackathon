from pydantic import BaseModel


class UserResponse(BaseModel):
    id: str
    name: str
    avatar_initials: str
    green_coins: float
    total_co2_saved: float
    streak_days: int
    rank: int
    city: str


class UserUpdate(BaseModel):
    name: str | None = None
    city: str | None = None
