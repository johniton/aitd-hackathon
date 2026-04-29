from pydantic import BaseModel, Field


class TripActivity(BaseModel):
    activity: str
    transport: str
    distance: str


class CurrentPlan(BaseModel):
    carbon: str
    cost: str
    impact_summary: str = ""


class OptimizedPlan(BaseModel):
    itinerary: list[TripActivity] = Field(default_factory=list)
    plan: list[str] = Field(default_factory=list)
    carbon: str
    cost: str
    impact_summary: str = ""


class PlanComparison(BaseModel):
    carbon_reduction_percent: str
    money_saved: str
    experience_improvement: str = ""


class Savings(BaseModel):
    carbon_reduction: str = ""
    money_saved: str = ""


class SubsidyRecommendation(BaseModel):
    name: str = ""
    amount: str = ""
    reason: str = ""


class TourismPlannerRequest(BaseModel):
    distance: float
    transport_mode: str
    business_type: str = "tourism"
    location: str = "Goa"
    waste_type: str = ""
    energy_usage: str = ""
    current_plan: list[TripActivity] = Field(default_factory=list)


class TourismPlannerResponse(BaseModel):
    current_plan: CurrentPlan
    optimized_plan: OptimizedPlan
    comparison: PlanComparison
    emotional_message: str = ""


class SustainabilityPlanRequest(BaseModel):
    distance: float
    transport_mode: str
    business_type: str = "tourism"
    location: str = "Goa"
    waste_type: str = ""
    energy_usage: str = ""
    current_plan: list[TripActivity] = Field(default_factory=list)


class SustainabilityPlanResponse(BaseModel):
    insight: str = ""
    current: dict = Field(default_factory=dict)
    optimized: dict = Field(default_factory=dict)
    savings: Savings = Field(default_factory=Savings)
    subsidy: SubsidyRecommendation = Field(default_factory=SubsidyRecommendation)
    analysis: list[str] = Field(default_factory=list)
    current_plan: CurrentPlan | None = None
    optimized_plan: OptimizedPlan | None = None
    comparison: PlanComparison | None = None
    emotional_message: str = ""
    source: str = "unknown"
