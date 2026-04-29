from pydantic import BaseModel


class ZoneResponse(BaseModel):
    name: str
    label: str
    co2_per_cap: float
    position_x: float
    position_y: float
    color_hex: str
