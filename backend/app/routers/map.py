from fastapi import APIRouter

from app.models.map import ZoneResponse
from app.logic.map_zones import MAP_ZONES

router = APIRouter()


@router.get("/zones", response_model=list[ZoneResponse])
def get_zones():
    return [ZoneResponse(**z) for z in MAP_ZONES]
