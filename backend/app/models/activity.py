from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class CategoryEnum(str, Enum):
    transport = "transport"
    food = "food"
    energy = "energy"
    waste = "waste"


class ActivityCreate(BaseModel):
    title: str
    category: CategoryEnum
    co2_kg: float = Field(ge=0)
    is_saving: bool


class ActivityResponse(BaseModel):
    id: str
    title: str
    category: str
    co2_kg: float
    is_saving: bool
    analogy: str
    logged_at: datetime


class WeeklyResponse(BaseModel):
    days: list[float]  # 7 floats, Mon–Sun


class WrappedResponse(BaseModel):
    co2_saved: float
    trees_equivalent: int
    top_category: str
    best_week: str
    percentile: int
    activities_logged: int
    green_coins_earned: float
