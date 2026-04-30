from fastapi import APIRouter

from app.models.map import ZoneResponse, UserDensityPointResponse
from app import db_ops
from app.logic.map_zones import MAP_ZONES

router = APIRouter()


@router.get("/zones", response_model=list[ZoneResponse])
def get_zones():
    return [ZoneResponse(**z) for z in MAP_ZONES]


_CITY_FALLBACK_COORDS = {
    "panaji": (15.4909, 73.8278),
    "mapusa": (15.5916, 73.8087),
    "margao": (15.2750, 73.9583),
    "vasco": (15.3860, 73.8440),
    "calangute": (15.5439, 73.7553),
    "ponda": (15.4029, 74.0154),
    "colva": (15.2797, 73.9228),
    "canacona": (15.0112, 74.0497),
}


@router.get("/user-density", response_model=list[UserDensityPointResponse])
def get_user_density_points():
    rows = db_ops.get_user_location_rows()
    grouped: dict[tuple[float, float], dict] = {}
    for row in rows:
        lat = row.get("latitude")
        lng = row.get("longitude")
        city = (row.get("city") or "").strip()
        green_coins = float(row.get("green_coins") or 0)

        if lat is None or lng is None:
            if not city:
                continue
            fallback = _CITY_FALLBACK_COORDS.get(city.lower())
            if fallback is None:
                continue
            lat, lng = fallback

        try:
            lat_f = float(lat)
            lng_f = float(lng)
        except (TypeError, ValueError):
            continue

        key = (round(lat_f, 4), round(lng_f, 4))
        if key not in grouped:
            grouped[key] = {
                "latitude": lat_f,
                "longitude": lng_f,
                "users": 0,
                "coin_total": 0.0,
                "city": city or None,
            }
        grouped[key]["users"] += 1
        grouped[key]["coin_total"] += green_coins
        if not grouped[key]["city"] and city:
            grouped[key]["city"] = city

    return [UserDensityPointResponse(**point) for point in grouped.values()]
