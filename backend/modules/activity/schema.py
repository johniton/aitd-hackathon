from pydantic import BaseModel

class ActivityCreate(BaseModel):
    user_id: str
    category: str
    type: str
    value: float

class SuggestionResponse(BaseModel):
    alternative: str
    message: str
    estimated_savings_kg: float

class ActivityResponse(BaseModel):
    carbon: float
    suggestions: list[SuggestionResponse]
    simulation: float

class DashboardCategoryBreakdown(BaseModel):
    category: str
    total_carbon: float

class DashboardResponse(BaseModel):
    total_carbon: float
    breakdown: list[DashboardCategoryBreakdown]
