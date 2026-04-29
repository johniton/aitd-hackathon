"""
Database operations abstraction.

Each function works with either Supabase or SQLite depending on configuration.
Routers call these functions instead of directly using supabase or sqlalchemy.
"""

from datetime import datetime, timezone, timedelta, date
from collections import Counter
from typing import Any

from app.database import use_supabase, get_supabase

# ── Generic helpers ─────────────────────────────────────────────────


def _sb():
    return get_supabase()


def _sqlite_session():
    from app.database import get_db
    return next(get_db())


# ═══════════════════════════════════════════════════════════════════
# USERS
# ═══════════════════════════════════════════════════════════════════


def get_user(user_id: str) -> dict | None:
    if use_supabase():
        resp = _sb().table("users").select("*").eq("id", user_id).execute()
        return resp.data[0] if resp.data else None
    else:
        from app.database import UserDB
        db = _sqlite_session()
        u = db.query(UserDB).filter(UserDB.id == user_id).first()
        db.close()
        if not u:
            return None
        return {
            "id": u.id, "name": u.name, "avatar_initials": u.avatar_initials,
            "green_coins": u.green_coins, "total_co2_saved": u.total_co2_saved,
            "streak_days": u.streak_days, "city": u.city or "",
        }


def get_user_rank(user_id: str) -> int:
    if use_supabase():
        resp = _sb().table("users").select("id").order("total_co2_saved", desc=True).execute()
        for i, row in enumerate(resp.data, 1):
            if row["id"] == user_id:
                return i
        return 0
    else:
        from app.database import UserDB
        db = _sqlite_session()
        users = db.query(UserDB.id).order_by(UserDB.total_co2_saved.desc()).all()
        db.close()
        for i, (uid,) in enumerate(users, 1):
            if uid == user_id:
                return i
        return 0


def update_user(user_id: str, updates: dict) -> dict | None:
    if use_supabase():
        resp = _sb().table("users").update(updates).eq("id", user_id).execute()
        return resp.data[0] if resp.data else None
    else:
        from app.database import UserDB, _SessionLocal
        db = _SessionLocal()
        u = db.query(UserDB).filter(UserDB.id == user_id).first()
        if not u:
            db.close()
            return None
        for k, v in updates.items():
            setattr(u, k, v)
        db.commit()
        db.refresh(u)
        result = {
            "id": u.id, "name": u.name, "avatar_initials": u.avatar_initials,
            "green_coins": u.green_coins, "total_co2_saved": u.total_co2_saved,
            "streak_days": u.streak_days, "city": u.city or "",
        }
        db.close()
        return result


def get_all_users_ranked(limit: int = 20, city: str | None = None) -> list[dict]:
    if use_supabase():
        q = _sb().table("users").select("*")
        if city:
            q = q.eq("city", city)
        resp = q.order("total_co2_saved", desc=True).limit(limit).execute()
        return resp.data
    else:
        from app.database import UserDB, _SessionLocal
        db = _SessionLocal()
        q = db.query(UserDB)
        if city:
            q = q.filter(UserDB.city == city)
        users = q.order_by(UserDB.total_co2_saved.desc()).limit(limit).all()
        result = [
            {"id": u.id, "name": u.name, "avatar_initials": u.avatar_initials,
             "green_coins": u.green_coins, "total_co2_saved": u.total_co2_saved,
             "streak_days": u.streak_days, "city": u.city or ""}
            for u in users
        ]
        db.close()
        return result


def get_all_users_co2() -> list[dict]:
    if use_supabase():
        resp = _sb().table("users").select("total_co2_saved").execute()
        return resp.data
    else:
        from app.database import UserDB, _SessionLocal
        db = _SessionLocal()
        users = db.query(UserDB.total_co2_saved).all()
        db.close()
        return [{"total_co2_saved": u[0]} for u in users]


# ═══════════════════════════════════════════════════════════════════
# ACTIVITIES
# ═══════════════════════════════════════════════════════════════════


def get_last_activity(user_id: str) -> dict | None:
    if use_supabase():
        resp = (_sb().table("activities").select("logged_at")
                .eq("user_id", user_id).order("logged_at", desc=True).limit(1).execute())
        return resp.data[0] if resp.data else None
    else:
        from app.database import ActivityDB, _SessionLocal
        db = _SessionLocal()
        a = db.query(ActivityDB).filter(ActivityDB.user_id == user_id).order_by(ActivityDB.logged_at.desc()).first()
        db.close()
        if not a:
            return None
        return {"logged_at": a.logged_at.isoformat() if a.logged_at else None}


def insert_activity(data: dict) -> dict:
    if use_supabase():
        resp = _sb().table("activities").insert(data).execute()
        return resp.data[0]
    else:
        from app.database import ActivityDB, _SessionLocal
        db = _SessionLocal()
        a = ActivityDB(**data)
        db.add(a)
        db.commit()
        db.refresh(a)
        result = {
            "id": a.id, "user_id": a.user_id, "title": a.title, "category": a.category,
            "co2_kg": a.co2_kg, "is_saving": a.is_saving, "analogy": a.analogy or "",
            "logged_at": a.logged_at.isoformat() if a.logged_at else "",
        }
        db.close()
        return result


def list_activities(user_id: str, limit: int, offset: int, category: str | None) -> list[dict]:
    if use_supabase():
        q = _sb().table("activities").select("*").eq("user_id", user_id)
        if category:
            q = q.eq("category", category)
        resp = q.order("logged_at", desc=True).range(offset, offset + limit - 1).execute()
        return resp.data
    else:
        from app.database import ActivityDB, _SessionLocal
        db = _SessionLocal()
        q = db.query(ActivityDB).filter(ActivityDB.user_id == user_id)
        if category:
            q = q.filter(ActivityDB.category == category)
        acts = q.order_by(ActivityDB.logged_at.desc()).offset(offset).limit(limit).all()
        result = [
            {"id": a.id, "title": a.title, "category": a.category, "co2_kg": a.co2_kg,
             "is_saving": a.is_saving, "analogy": a.analogy or "",
             "logged_at": a.logged_at.isoformat() if a.logged_at else ""}
            for a in acts
        ]
        db.close()
        return result


def get_activities_in_range(user_id: str, start: str, end: str) -> list[dict]:
    if use_supabase():
        resp = (_sb().table("activities").select("co2_kg, logged_at")
                .eq("user_id", user_id).gte("logged_at", start).lte("logged_at", end).execute())
        return resp.data
    else:
        from app.database import ActivityDB, _SessionLocal
        db = _SessionLocal()
        acts = (db.query(ActivityDB)
                .filter(ActivityDB.user_id == user_id,
                        ActivityDB.logged_at >= start, ActivityDB.logged_at <= end).all())
        result = [{"co2_kg": a.co2_kg, "logged_at": a.logged_at.isoformat() if a.logged_at else ""}
                  for a in acts]
        db.close()
        return result


def get_all_activities(user_id: str) -> list[dict]:
    if use_supabase():
        resp = _sb().table("activities").select("*").eq("user_id", user_id).execute()
        return resp.data
    else:
        from app.database import ActivityDB, _SessionLocal
        db = _SessionLocal()
        acts = db.query(ActivityDB).filter(ActivityDB.user_id == user_id).all()
        result = [
            {"id": a.id, "title": a.title, "category": a.category, "co2_kg": a.co2_kg,
             "is_saving": a.is_saving, "analogy": a.analogy or "",
             "logged_at": a.logged_at.isoformat() if a.logged_at else ""}
            for a in acts
        ]
        db.close()
        return result


# ═══════════════════════════════════════════════════════════════════
# HOUSE
# ═══════════════════════════════════════════════════════════════════


def get_house_items(user_id: str) -> list[dict]:
    if use_supabase():
        resp = _sb().table("house_items").select("*").eq("user_id", user_id).execute()
        return resp.data
    else:
        from app.database import HouseItemDB, _SessionLocal
        db = _SessionLocal()
        items = db.query(HouseItemDB).filter(HouseItemDB.user_id == user_id).all()
        result = [{"item_key": i.item_key, "item_name": i.item_name, "cost": i.cost,
                    "purchased_at": i.purchased_at.isoformat() if i.purchased_at else ""}
                  for i in items]
        db.close()
        return result


def has_house_item(user_id: str, item_key: str) -> bool:
    if use_supabase():
        resp = _sb().table("house_items").select("id").eq("user_id", user_id).eq("item_key", item_key).execute()
        return bool(resp.data)
    else:
        from app.database import HouseItemDB, _SessionLocal
        db = _SessionLocal()
        exists = db.query(HouseItemDB).filter(HouseItemDB.user_id == user_id, HouseItemDB.item_key == item_key).first()
        db.close()
        return exists is not None


def insert_house_item(data: dict):
    if use_supabase():
        _sb().table("house_items").insert(data).execute()
    else:
        from app.database import HouseItemDB, _SessionLocal
        db = _SessionLocal()
        db.add(HouseItemDB(**data))
        db.commit()
        db.close()


# ═══════════════════════════════════════════════════════════════════
# BUSINESS
# ═══════════════════════════════════════════════════════════════════


def get_business_by_owner(owner_id: str) -> dict | None:
    if use_supabase():
        resp = _sb().table("businesses").select("*").eq("owner_id", owner_id).execute()
        return resp.data[0] if resp.data else None
    else:
        from app.database import BusinessDB, _SessionLocal
        db = _SessionLocal()
        b = db.query(BusinessDB).filter(BusinessDB.owner_id == owner_id).first()
        if not b:
            db.close()
            return None
        result = {"id": b.id, "name": b.name, "sector": b.sector, "owner_id": b.owner_id,
                  "emissions_kg": b.emissions_kg, "peer_avg_kg": b.peer_avg_kg}
        db.close()
        return result


def get_business_suggestions(business_id: str) -> list[str]:
    if use_supabase():
        resp = _sb().table("business_suggestions").select("suggestion").eq("business_id", business_id).execute()
        return [s["suggestion"] for s in resp.data]
    else:
        from app.database import BusinessSuggestionDB, _SessionLocal
        db = _SessionLocal()
        sugs = db.query(BusinessSuggestionDB).filter(BusinessSuggestionDB.business_id == business_id).all()
        result = [s.suggestion for s in sugs]
        db.close()
        return result


def get_business_badges(business_id: str) -> list[str]:
    if use_supabase():
        resp = _sb().table("business_badges").select("badge_name").eq("business_id", business_id).execute()
        return [b["badge_name"] for b in resp.data]
    else:
        from app.database import BusinessBadgeDB, _SessionLocal
        db = _SessionLocal()
        badges = db.query(BusinessBadgeDB).filter(BusinessBadgeDB.business_id == business_id).all()
        result = [b.badge_name for b in badges]
        db.close()
        return result


def insert_business(data: dict) -> dict:
    if use_supabase():
        resp = _sb().table("businesses").insert(data).execute()
        return resp.data[0]
    else:
        from app.database import BusinessDB, _SessionLocal
        db = _SessionLocal()
        b = BusinessDB(**data)
        db.add(b)
        db.commit()
        db.refresh(b)
        result = {"id": b.id, "name": b.name, "sector": b.sector, "owner_id": b.owner_id,
                  "emissions_kg": b.emissions_kg, "peer_avg_kg": b.peer_avg_kg}
        db.close()
        return result


def update_business_emissions(biz_id: str, sector: str, emissions_kg: float):
    if use_supabase():
        sb = _sb()
        sb.table("businesses").update({"emissions_kg": emissions_kg}).eq("id", biz_id).execute()
        # Recalculate peer avg
        sector_resp = sb.table("businesses").select("emissions_kg").eq("sector", sector).execute()
        if sector_resp.data:
            avg = sum(b["emissions_kg"] for b in sector_resp.data) / len(sector_resp.data)
            sb.table("businesses").update({"peer_avg_kg": round(avg, 1)}).eq("sector", sector).execute()
    else:
        from app.database import BusinessDB, _SessionLocal
        db = _SessionLocal()
        b = db.query(BusinessDB).filter(BusinessDB.id == biz_id).first()
        if b:
            b.emissions_kg = emissions_kg
            db.commit()
            # Recalculate peer avg
            sector_businesses = db.query(BusinessDB).filter(BusinessDB.sector == sector).all()
            if sector_businesses:
                avg = sum(sb.emissions_kg for sb in sector_businesses) / len(sector_businesses)
                for sb_ in sector_businesses:
                    sb_.peer_avg_kg = round(avg, 1)
                db.commit()
        db.close()


def get_sector_peers(sector: str) -> list[dict]:
    if use_supabase():
        resp = _sb().table("businesses").select("id, name, emissions_kg").eq("sector", sector).order("emissions_kg").execute()
        return resp.data
    else:
        from app.database import BusinessDB, _SessionLocal
        db = _SessionLocal()
        peers = db.query(BusinessDB).filter(BusinessDB.sector == sector).order_by(BusinessDB.emissions_kg).all()
        result = [{"id": p.id, "name": p.name, "emissions_kg": p.emissions_kg} for p in peers]
        db.close()
        return result


# ═══════════════════════════════════════════════════════════════════
# SUBSIDIES
# ═══════════════════════════════════════════════════════════════════


def get_all_subsidies() -> list[dict]:
    if use_supabase():
        resp = _sb().table("subsidies").select("*").execute()
        return resp.data
    else:
        from app.database import SubsidyDB, _SessionLocal
        db = _SessionLocal()
        subs = db.query(SubsidyDB).all()
        result = [{"id": s.id, "title": s.title, "description": s.description or "",
                    "amount": s.amount or "", "deadline": s.deadline or "",
                    "eligible_sectors": s.eligible_sectors or ""}
                  for s in subs]
        db.close()
        return result


# ═══════════════════════════════════════════════════════════════════
# EXCHANGE
# ═══════════════════════════════════════════════════════════════════


def get_active_exchange_listings() -> list[dict]:
    if use_supabase():
        resp = _sb().table("exchange_listings").select("*, businesses(name)").eq("active", True).execute()
        return resp.data
    else:
        from app.database import ExchangeListingDB, BusinessDB, _SessionLocal
        db = _SessionLocal()
        listings = db.query(ExchangeListingDB).filter(ExchangeListingDB.active == True).all()
        result = []
        for l in listings:
            biz = db.query(BusinessDB).filter(BusinessDB.id == l.business_id).first()
            result.append({
                "id": l.id, "title": l.title, "description": l.description or "",
                "sector": l.sector or "", "active": l.active,
                "businesses": {"name": biz.name} if biz else None,
            })
        db.close()
        return result


def insert_exchange_listing(data: dict) -> dict:
    if use_supabase():
        resp = _sb().table("exchange_listings").insert(data).execute()
        return resp.data[0]
    else:
        from app.database import ExchangeListingDB, _SessionLocal
        db = _SessionLocal()
        l = ExchangeListingDB(**data)
        db.add(l)
        db.commit()
        db.refresh(l)
        result = {"id": l.id, "title": l.title, "description": l.description or "",
                  "sector": l.sector or "", "active": l.active}
        db.close()
        return result


def exchange_listing_exists(listing_id: str) -> bool:
    if use_supabase():
        resp = _sb().table("exchange_listings").select("id").eq("id", listing_id).execute()
        return bool(resp.data)
    else:
        from app.database import ExchangeListingDB, _SessionLocal
        db = _SessionLocal()
        exists = db.query(ExchangeListingDB).filter(ExchangeListingDB.id == listing_id).first()
        db.close()
        return exists is not None
