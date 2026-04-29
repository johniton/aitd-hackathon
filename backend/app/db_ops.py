"""
Database operations — Supabase only.
"""

from app.database import get_supabase


def _sb():
    return get_supabase()


# ═══════════════════════════════════════════════════════════════════
# USERS
# ═══════════════════════════════════════════════════════════════════


def get_user(user_id: str) -> dict | None:
    resp = _sb().table("users").select("*").eq("id", user_id).execute()
    return resp.data[0] if resp.data else None


def create_user(data: dict) -> dict:
    resp = _sb().table("users").insert(data).execute()
    return resp.data[0]


def get_user_rank(user_id: str) -> int:
    resp = _sb().table("users").select("id").order("total_co2_saved", desc=True).execute()
    for i, row in enumerate(resp.data, 1):
        if row["id"] == user_id:
            return i
    return 0


def update_user(user_id: str, updates: dict) -> dict | None:
    resp = _sb().table("users").update(updates).eq("id", user_id).execute()
    return resp.data[0] if resp.data else None


def search_users_by_name(name: str) -> list[dict]:
    resp = _sb().table("users").select("*").ilike("name", f"%{name}%").limit(10).execute()
    return resp.data


def get_all_users_ranked(limit: int = 20, city: str | None = None) -> list[dict]:
    q = _sb().table("users").select("*")
    if city:
        q = q.eq("city", city)
    resp = q.order("total_co2_saved", desc=True).limit(limit).execute()
    return resp.data


def get_all_users_co2() -> list[dict]:
    resp = _sb().table("users").select("total_co2_saved").execute()
    return resp.data


# ═══════════════════════════════════════════════════════════════════
# ACTIVITIES
# ═══════════════════════════════════════════════════════════════════


def get_last_activity(user_id: str) -> dict | None:
    resp = (_sb().table("activities").select("logged_at")
            .eq("user_id", user_id).order("logged_at", desc=True).limit(1).execute())
    return resp.data[0] if resp.data else None


def insert_activity(data: dict) -> dict:
    resp = _sb().table("activities").insert(data).execute()
    return resp.data[0]


def list_activities(user_id: str, limit: int, offset: int, category: str | None) -> list[dict]:
    q = _sb().table("activities").select("*").eq("user_id", user_id)
    if category:
        q = q.eq("category", category)
    resp = q.order("logged_at", desc=True).range(offset, offset + limit - 1).execute()
    return resp.data


def get_activities_in_range(user_id: str, start: str, end: str) -> list[dict]:
    resp = (_sb().table("activities").select("co2_kg, logged_at")
            .eq("user_id", user_id).gte("logged_at", start).lte("logged_at", end).execute())
    return resp.data


def get_all_activities(user_id: str) -> list[dict]:
    resp = _sb().table("activities").select("*").eq("user_id", user_id).execute()
    return resp.data


# ═══════════════════════════════════════════════════════════════════
# HOUSE
# ═══════════════════════════════════════════════════════════════════


def get_house_items(user_id: str) -> list[dict]:
    resp = _sb().table("house_items").select("*").eq("user_id", user_id).execute()
    return resp.data


def has_house_item(user_id: str, item_key: str) -> bool:
    resp = _sb().table("house_items").select("id").eq("user_id", user_id).eq("item_key", item_key).execute()
    return bool(resp.data)


def insert_house_item(data: dict):
    _sb().table("house_items").insert(data).execute()


# ═══════════════════════════════════════════════════════════════════
# BUSINESS
# ═══════════════════════════════════════════════════════════════════


def get_business_by_owner(owner_id: str) -> dict | None:
    resp = _sb().table("businesses").select("*").eq("owner_id", owner_id).execute()
    return resp.data[0] if resp.data else None


def get_business_suggestions(business_id: str) -> list[str]:
    resp = _sb().table("business_suggestions").select("suggestion").eq("business_id", business_id).execute()
    return [s["suggestion"] for s in resp.data]


def get_business_badges(business_id: str) -> list[str]:
    resp = _sb().table("business_badges").select("badge_name").eq("business_id", business_id).execute()
    return [b["badge_name"] for b in resp.data]


def insert_business(data: dict) -> dict:
    resp = _sb().table("businesses").insert(data).execute()
    return resp.data[0]


def update_business_emissions(biz_id: str, sector: str, emissions_kg: float):
    sb = _sb()
    sb.table("businesses").update({"emissions_kg": emissions_kg}).eq("id", biz_id).execute()
    sector_resp = sb.table("businesses").select("emissions_kg").eq("sector", sector).execute()
    if sector_resp.data:
        avg = sum(b["emissions_kg"] for b in sector_resp.data) / len(sector_resp.data)
        sb.table("businesses").update({"peer_avg_kg": round(avg, 1)}).eq("sector", sector).execute()


def get_sector_peers(sector: str) -> list[dict]:
    resp = _sb().table("businesses").select("id, name, emissions_kg").eq("sector", sector).order("emissions_kg").execute()
    return resp.data


# ═══════════════════════════════════════════════════════════════════
# SUBSIDIES
# ═══════════════════════════════════════════════════════════════════


def get_all_subsidies() -> list[dict]:
    resp = _sb().table("subsidies").select("*").execute()
    return resp.data


# ═══════════════════════════════════════════════════════════════════
# EXCHANGE
# ═══════════════════════════════════════════════════════════════════


def get_active_exchange_listings() -> list[dict]:
    resp = _sb().table("exchange_listings").select("*, businesses(name)").eq("active", True).execute()
    return resp.data


def insert_exchange_listing(data: dict) -> dict:
    resp = _sb().table("exchange_listings").insert(data).execute()
    return resp.data[0]


def exchange_listing_exists(listing_id: str) -> bool:
    resp = _sb().table("exchange_listings").select("id").eq("id", listing_id).execute()
    return bool(resp.data)
