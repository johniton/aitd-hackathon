from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from db.database import get_db
from .schema import ActivityCreate, ActivityResponse, DashboardResponse
from .service import process_activity, get_dashboard

router = APIRouter()

@router.post("/", response_model=ActivityResponse)
def create_activity(activity: ActivityCreate, db: Session = Depends(get_db)):
    try:
        return process_activity(db, activity)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/dashboard/{user_id}", response_model=DashboardResponse)
def read_dashboard(user_id: str, db: Session = Depends(get_db)):
    return get_dashboard(db, user_id)
