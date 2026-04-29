from fastapi import APIRouter, HTTPException

from .schema import (
    TourismPlannerRequest,
    TourismPlannerResponse,
    SustainabilityPlanRequest,
    SustainabilityPlanResponse,
)
from .service import optimize_tourism_plan, get_sustainability_plan

router = APIRouter()


@router.post("/optimize-plan", response_model=TourismPlannerResponse)
async def optimize_plan(payload: TourismPlannerRequest):
    try:
        return await optimize_tourism_plan(payload)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to optimize tourism plan: {str(exc)}",
        )


@router.post("/sustainability-plan", response_model=SustainabilityPlanResponse)
async def sustainability_plan(payload: SustainabilityPlanRequest):
    """
    Full sustainability plan with AI-powered analysis.
    Chain: Groq → OpenRouter → Gemini → Local fallback.
    Returns insight, current vs optimized plan, savings, and subsidy recommendation.
    """
    try:
        return await get_sustainability_plan(payload)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate sustainability plan: {str(exc)}",
        )
