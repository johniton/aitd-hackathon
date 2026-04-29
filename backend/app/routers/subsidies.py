from fastapi import APIRouter, Query
from app.models.subsidy import SubsidyResponse
from app import db_ops

router = APIRouter()


@router.get("", response_model=list[SubsidyResponse])
def list_subsidies(sector: str | None = Query(None)):
    subsidies = db_ops.get_all_subsidies()
    result = []
    for s in subsidies:
        eligible = s.get("eligible_sectors", []) or []
        if isinstance(eligible, str):
            eligible = [x.strip() for x in eligible.split(",") if x.strip()]
        is_eligible = sector in eligible if sector else False
        result.append(SubsidyResponse(
            id=s["id"], title=s["title"], description=s.get("description", ""),
            amount=s.get("amount", ""), deadline=s.get("deadline", ""), is_eligible=is_eligible,
        ))
    return result
