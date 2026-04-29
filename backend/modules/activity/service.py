from sqlalchemy.orm import Session
from sqlalchemy import func
from db.models import Activity
from core.config import settings
from .schema import ActivityCreate, ActivityResponse, DashboardResponse, DashboardCategoryBreakdown

from modules.carbon.engine import calculate
from modules.suggestions.engine import get_suggestions
from modules.simulation.engine import run as run_simulation

def process_activity(db: Session, activity_data: ActivityCreate) -> ActivityResponse:
    # 1. Calculate carbon
    carbon_emissions = 0.0
    if settings.FEATURES.get("carbon", False):
        carbon_emissions = calculate(
            category=activity_data.category,
            type=activity_data.type,
            value=activity_data.value
        )
    
    # Save to db
    db_activity = Activity(
        user_id=activity_data.user_id,
        category=activity_data.category,
        type=activity_data.type,
        value=activity_data.value,
        carbon=carbon_emissions
    )
    db.add(db_activity)
    db.commit()
    db.refresh(db_activity)
    
    # 2. Get suggestions
    suggestions = []
    if settings.FEATURES.get("suggestions", False):
        suggestions = get_suggestions(
            category=activity_data.category,
            type=activity_data.type,
            value=activity_data.value,
            current_carbon=carbon_emissions
        )
        
    # 3. Get simulation
    simulation_savings = 0.0
    if settings.FEATURES.get("simulation", False):
        simulation_savings = run_simulation(carbon=carbon_emissions)
        
    return ActivityResponse(
        carbon=carbon_emissions,
        suggestions=suggestions,
        simulation=simulation_savings
    )

def get_dashboard(db: Session, user_id: str) -> DashboardResponse:
    # Calculate total carbon
    total = db.query(func.sum(Activity.carbon)).filter(Activity.user_id == user_id).scalar() or 0.0
    
    # Calculate breakdown
    breakdown_query = (
        db.query(Activity.category, func.sum(Activity.carbon).label("total_carbon"))
        .filter(Activity.user_id == user_id)
        .group_by(Activity.category)
        .all()
    )
    
    breakdown = [
        DashboardCategoryBreakdown(category=row.category, total_carbon=row.total_carbon)
        for row in breakdown_query
    ]
    
    return DashboardResponse(
        total_carbon=total,
        breakdown=breakdown
    )
