from fastapi import APIRouter, Depends, HTTPException
from app.auth import get_current_user
from app.models.exchange import ExchangeResponse, ExchangeCreate
from app import db_ops

router = APIRouter()


@router.get("", response_model=list[ExchangeResponse])
def list_exchange():
    listings = db_ops.get_active_exchange_listings()
    return [
        ExchangeResponse(
            id=l["id"], title=l["title"],
            offered_by=(l.get("businesses") or {}).get("name", "Unknown"),
            sector=l.get("sector", ""), description=l.get("description", ""),
            active=l.get("active", True),
        ) for l in listings
    ]


@router.post("", response_model=ExchangeResponse)
def create_exchange(body: ExchangeCreate, user_id: str = Depends(get_current_user)):
    biz = db_ops.get_business_by_owner(user_id)
    if not biz:
        raise HTTPException(status_code=400, detail="You must register a business first")
    listing = db_ops.insert_exchange_listing({
        "business_id": biz["id"], "title": body.title,
        "description": body.description, "sector": body.sector,
    })
    return ExchangeResponse(
        id=listing["id"], title=listing["title"], offered_by=biz["name"],
        sector=listing.get("sector", ""), description=listing.get("description", ""),
        active=listing.get("active", True),
    )


@router.post("/{listing_id}/interest")
def express_interest(listing_id: str, user_id: str = Depends(get_current_user)):
    if not db_ops.exchange_listing_exists(listing_id):
        raise HTTPException(status_code=404, detail="Listing not found")
    return {"detail": "Interest registered", "listing_id": listing_id, "user_id": user_id}
