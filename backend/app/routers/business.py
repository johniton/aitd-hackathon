from fastapi import APIRouter, Depends, HTTPException
from app.auth import get_current_user
from app.models.business import (BusinessCreate, BusinessResponse, EmissionsUpdate, BenchmarkResponse, PeerRankingEntry)
from app.logic.map_zones import SECTOR_ICONS
from app import db_ops

router = APIRouter()


def _biz_response(biz: dict) -> BusinessResponse:
    return BusinessResponse(
        id=biz["id"], name=biz["name"], sector=biz["sector"],
        sector_icon=SECTOR_ICONS.get(biz["sector"], ""),
        emissions_kg=biz.get("emissions_kg", 0), peer_avg_kg=biz.get("peer_avg_kg", 0),
        suggestions=db_ops.get_business_suggestions(biz["id"]),
        badges=db_ops.get_business_badges(biz["id"]),
    )


@router.get("/my", response_model=BusinessResponse)
def get_my_business(user_id: str = Depends(get_current_user)):
    biz = db_ops.get_business_by_owner(user_id)
    if not biz:
        raise HTTPException(status_code=404, detail="No business registered")
    return _biz_response(biz)


@router.post("", response_model=BusinessResponse)
def create_business(body: BusinessCreate, user_id: str = Depends(get_current_user)):
    if db_ops.get_business_by_owner(user_id):
        raise HTTPException(status_code=400, detail="Business already registered")
    if body.sector not in {"tourism", "cashew", "farmer", "bakery"}:
        raise HTTPException(status_code=400, detail="Invalid sector")
    biz = db_ops.insert_business({"name": body.name, "sector": body.sector, "owner_id": user_id})
    return _biz_response(biz)


@router.patch("/my/emissions", response_model=BusinessResponse)
def update_emissions(body: EmissionsUpdate, user_id: str = Depends(get_current_user)):
    biz = db_ops.get_business_by_owner(user_id)
    if not biz:
        raise HTTPException(status_code=404, detail="No business registered")
    db_ops.update_business_emissions(biz["id"], biz["sector"], body.emissions_kg)
    biz = db_ops.get_business_by_owner(user_id)
    return _biz_response(biz)


@router.get("/benchmark", response_model=BenchmarkResponse)
def get_benchmark(user_id: str = Depends(get_current_user)):
    biz = db_ops.get_business_by_owner(user_id)
    if not biz:
        raise HTTPException(status_code=404, detail="No business registered")
    peers = db_ops.get_sector_peers(biz["sector"])
    avg = sum(p["emissions_kg"] for p in peers) / len(peers) if peers else 0
    best = peers[0]["emissions_kg"] if peers else 0
    ranking = [PeerRankingEntry(name=p["name"], emissions_kg=p["emissions_kg"], is_me=(p["id"] == biz["id"])) for p in peers]
    return BenchmarkResponse(my_emissions_kg=biz.get("emissions_kg", 0), sector_avg_kg=round(avg, 1),
                             best_in_class_kg=best, sector=biz["sector"], peer_ranking=ranking)
