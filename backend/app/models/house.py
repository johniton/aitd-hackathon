from pydantic import BaseModel


class HouseItemResponse(BaseModel):
    item_key: str
    item_name: str
    cost: int
    purchased_at: str  # ISO 8601


class HouseResponse(BaseModel):
    coins: float
    items: list[HouseItemResponse]


class BuyRequest(BaseModel):
    item_key: str


class BuyResponse(BaseModel):
    success: bool
    coins_remaining: float
    item_key: str
