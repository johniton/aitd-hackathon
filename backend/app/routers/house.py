from fastapi import APIRouter, Depends, HTTPException
from app.auth import get_current_user
from app.models.house import HouseResponse, HouseItemResponse, BuyRequest, BuyResponse
from app.logic.house_catalogue import HOUSE_ITEMS
from app import db_ops

router = APIRouter()


@router.get("", response_model=HouseResponse)
def get_house(user_id: str = Depends(get_current_user)):
    user = db_ops.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    items = db_ops.get_house_items(user_id)
    return HouseResponse(
        coins=user.get("green_coins", 0),
        items=[HouseItemResponse(item_key=p["item_key"], item_name=p["item_name"],
                                 cost=p["cost"], purchased_at=p.get("purchased_at", "")) for p in items],
    )


@router.post("/buy", response_model=BuyResponse)
def buy_item(body: BuyRequest, user_id: str = Depends(get_current_user)):
    item = HOUSE_ITEMS.get(body.item_key)
    if not item:
        raise HTTPException(status_code=400, detail=f"Unknown item: {body.item_key}")
    user = db_ops.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if db_ops.has_house_item(user_id, body.item_key):
        raise HTTPException(status_code=400, detail="Item already purchased")
    coins = user.get("green_coins", 0)
    if coins < item["cost"]:
        raise HTTPException(status_code=400, detail="Not enough GreenCoins")

    new_coins = coins - item["cost"]
    db_ops.update_user(user_id, {"green_coins": new_coins})
    db_ops.insert_house_item({"user_id": user_id, "item_key": body.item_key, "item_name": item["name"], "cost": item["cost"]})
    return BuyResponse(success=True, coins_remaining=new_coins, item_key=body.item_key)
