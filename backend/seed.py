"""
Seed script -- populates the database with demo data matching static_data.dart.
Works with both SQLite (local) and Supabase (production).

Usage:  python seed.py
"""

from datetime import datetime, timezone, timedelta
from app.database import use_supabase


def seed_supabase():
    from app.database import get_supabase
    sb = get_supabase()
    now = datetime.now(timezone.utc)

    # Clean
    for t in ["exchange_listings", "business_badges", "business_suggestions",
              "house_items", "subsidies", "activities", "businesses", "users"]:
        sb.table(t).delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()

    priya = "00000000-0000-0000-0000-000000000004"
    rahul = "00000000-0000-0000-0000-000000000001"
    biz1 = "00000000-0000-0000-0000-100000000001"
    biz2 = "00000000-0000-0000-0000-100000000002"

    sb.table("users").insert([
        {"id": rahul, "name": "Rahul Dessai", "avatar_initials": "RD", "green_coins": 1240, "total_co2_saved": 210.3, "streak_days": 21, "city": "Margao"},
        {"id": "00000000-0000-0000-0000-000000000002", "name": "Sneha Kamat", "avatar_initials": "SK", "green_coins": 1105, "total_co2_saved": 188.7, "streak_days": 18, "city": "Mapusa"},
        {"id": "00000000-0000-0000-0000-000000000003", "name": "Dev Borkar", "avatar_initials": "DB", "green_coins": 980, "total_co2_saved": 165.2, "streak_days": 15, "city": "Vasco"},
        {"id": priya, "name": "Priya Naik", "avatar_initials": "PN", "green_coins": 840, "total_co2_saved": 124.5, "streak_days": 12, "city": "Panaji"},
        {"id": "00000000-0000-0000-0000-000000000005", "name": "Amit Gaonkar", "avatar_initials": "AG", "green_coins": 720, "total_co2_saved": 98.1, "streak_days": 9, "city": "Ponda"},
        {"id": "00000000-0000-0000-0000-000000000006", "name": "Meera Shirodkar", "avatar_initials": "MS", "green_coins": 610, "total_co2_saved": 87.4, "streak_days": 7, "city": "Panaji"},
        {"id": "00000000-0000-0000-0000-000000000007", "name": "Kiran Naik", "avatar_initials": "KN", "green_coins": 540, "total_co2_saved": 72.0, "streak_days": 5, "city": "Calangute"},
        {"id": "00000000-0000-0000-0000-000000000008", "name": "Tara Figueiredo", "avatar_initials": "TF", "green_coins": 420, "total_co2_saved": 60.3, "streak_days": 4, "city": "Colva"},
    ]).execute()

    sb.table("activities").insert([
        {"user_id": priya, "title": "Cycled to work", "category": "transport", "co2_kg": 1.68, "is_saving": True, "analogy": "~76 cashew trees absorbing for a day", "logged_at": (now - timedelta(hours=2)).isoformat()},
        {"user_id": priya, "title": "Vegetarian lunch", "category": "food", "co2_kg": 0.5, "is_saving": True, "analogy": "~22 cashew trees absorbing for a day", "logged_at": (now - timedelta(hours=5)).isoformat()},
        {"user_id": priya, "title": "Used AC for 4 hours", "category": "energy", "co2_kg": 1.2, "is_saving": False, "analogy": "~12 hours of AC", "logged_at": (now - timedelta(hours=8)).isoformat()},
        {"user_id": priya, "title": "Composted kitchen waste", "category": "waste", "co2_kg": 0.3, "is_saving": True, "analogy": "~14 cashew trees absorbing for a day", "logged_at": (now - timedelta(days=1)).isoformat()},
        {"user_id": priya, "title": "Auto rickshaw ride", "category": "transport", "co2_kg": 0.95, "is_saving": False, "analogy": "~0.1 trips by ferry", "logged_at": (now - timedelta(days=1, hours=3)).isoformat()},
    ]).execute()

    sb.table("house_items").insert({"user_id": priya, "item_key": "h5", "item_name": "Compost Bin", "cost": 80}).execute()
    sb.table("businesses").insert([
        {"id": biz1, "name": "Rodrigues Beach Shack", "sector": "tourism", "owner_id": priya, "emissions_kg": 420, "peer_avg_kg": 580},
        {"id": biz2, "name": "Naik Cashew Factory", "sector": "cashew", "owner_id": rahul, "emissions_kg": 1240, "peer_avg_kg": 980},
    ]).execute()
    sb.table("business_suggestions").insert([
        {"business_id": biz1, "suggestion": "Switch to LED lighting"}, {"business_id": biz1, "suggestion": "Install solar water heater"},
        {"business_id": biz1, "suggestion": "Use biodegradable packaging"},
        {"business_id": biz2, "suggestion": "Optimise roasting schedule"}, {"business_id": biz2, "suggestion": "Switch to biomass fuel"},
        {"business_id": biz2, "suggestion": "Install dust collectors"},
    ]).execute()
    sb.table("business_badges").insert([
        {"business_id": biz1, "badge_name": "Low Carbon Star"}, {"business_id": biz1, "badge_name": "Green Vendor"},
        {"business_id": biz2, "badge_name": "Quality Processor"},
    ]).execute()
    sb.table("subsidies").insert([
        {"title": "Goa Solar Mission", "description": "30% subsidy on rooftop solar for SMEs", "amount": "Rs.1,20,000", "deadline": "June 2026", "eligible_sectors": ["tourism", "cashew", "farmer", "bakery"]},
        {"title": "Green Tourism Grant", "description": "For beach shacks adopting zero-waste", "amount": "Rs.50,000", "deadline": "March 2026", "eligible_sectors": ["tourism"]},
        {"title": "Biogas Plant Subsidy", "description": "MNRE scheme for organic waste processors", "amount": "Rs.80,000", "deadline": "December 2025", "eligible_sectors": ["farmer", "cashew"]},
    ]).execute()
    sb.table("exchange_listings").insert([
        {"business_id": biz2, "title": "Surplus cashew husks", "description": "Available monthly -- good fuel for biogas", "sector": "Cashew"},
        {"business_id": biz1, "title": "Used cooking oil", "description": "Biofuel feedstock -- 50L/week", "sector": "Tourism"},
    ]).execute()

    print("[OK] Supabase seeded!")


def seed_sqlite():
    from app.database import _init_sqlite, _SessionLocal, Base, _engine
    import app.database as db_mod

    _init_sqlite()
    Base.metadata.drop_all(bind=_engine)
    Base.metadata.create_all(bind=_engine)
    session = _SessionLocal()
    now = datetime.now(timezone.utc)

    users = [
        db_mod.UserDB(id="l1", name="Rahul Dessai", avatar_initials="RD", green_coins=1240, total_co2_saved=210.3, streak_days=21, city="Margao"),
        db_mod.UserDB(id="l2", name="Sneha Kamat", avatar_initials="SK", green_coins=1105, total_co2_saved=188.7, streak_days=18, city="Mapusa"),
        db_mod.UserDB(id="l3", name="Dev Borkar", avatar_initials="DB", green_coins=980, total_co2_saved=165.2, streak_days=15, city="Vasco"),
        db_mod.UserDB(id="u1", name="Priya Naik", avatar_initials="PN", green_coins=840, total_co2_saved=124.5, streak_days=12, city="Panaji"),
        db_mod.UserDB(id="l5", name="Amit Gaonkar", avatar_initials="AG", green_coins=720, total_co2_saved=98.1, streak_days=9, city="Ponda"),
        db_mod.UserDB(id="l6", name="Meera Shirodkar", avatar_initials="MS", green_coins=610, total_co2_saved=87.4, streak_days=7, city="Panaji"),
        db_mod.UserDB(id="l7", name="Kiran Naik", avatar_initials="KN", green_coins=540, total_co2_saved=72.0, streak_days=5, city="Calangute"),
        db_mod.UserDB(id="l8", name="Tara Figueiredo", avatar_initials="TF", green_coins=420, total_co2_saved=60.3, streak_days=4, city="Colva"),
    ]
    session.add_all(users)

    activities = [
        db_mod.ActivityDB(id="a1", user_id="u1", title="Cycled to work", category="transport", co2_kg=1.68, is_saving=True, analogy="~76 cashew trees absorbing for a day", logged_at=now - timedelta(hours=2)),
        db_mod.ActivityDB(id="a2", user_id="u1", title="Vegetarian lunch", category="food", co2_kg=0.5, is_saving=True, analogy="~22 cashew trees absorbing for a day", logged_at=now - timedelta(hours=5)),
        db_mod.ActivityDB(id="a3", user_id="u1", title="Used AC for 4 hours", category="energy", co2_kg=1.2, is_saving=False, analogy="~12 hours of AC", logged_at=now - timedelta(hours=8)),
        db_mod.ActivityDB(id="a4", user_id="u1", title="Composted kitchen waste", category="waste", co2_kg=0.3, is_saving=True, analogy="~14 cashew trees absorbing for a day", logged_at=now - timedelta(days=1)),
        db_mod.ActivityDB(id="a5", user_id="u1", title="Auto rickshaw ride", category="transport", co2_kg=0.95, is_saving=False, analogy="~0.1 trips by ferry", logged_at=now - timedelta(days=1, hours=3)),
    ]
    session.add_all(activities)
    session.add(db_mod.HouseItemDB(user_id="u1", item_key="h5", item_name="Compost Bin", cost=80))

    biz1 = db_mod.BusinessDB(id="b1", name="Rodrigues Beach Shack", sector="tourism", owner_id="u1", emissions_kg=420, peer_avg_kg=580)
    biz2 = db_mod.BusinessDB(id="b2", name="Naik Cashew Factory", sector="cashew", owner_id="l1", emissions_kg=1240, peer_avg_kg=980)
    session.add_all([biz1, biz2])
    session.flush()

    for s in ["Switch to LED lighting", "Install solar water heater", "Use biodegradable packaging"]:
        session.add(db_mod.BusinessSuggestionDB(business_id="b1", suggestion=s))
    for s in ["Optimise roasting schedule", "Switch to biomass fuel", "Install dust collectors"]:
        session.add(db_mod.BusinessSuggestionDB(business_id="b2", suggestion=s))
    for b in ["Low Carbon Star", "Green Vendor"]:
        session.add(db_mod.BusinessBadgeDB(business_id="b1", badge_name=b))
    session.add(db_mod.BusinessBadgeDB(business_id="b2", badge_name="Quality Processor"))

    session.add_all([
        db_mod.SubsidyDB(title="Goa Solar Mission", description="30% subsidy on rooftop solar for SMEs", amount="Rs.1,20,000", deadline="June 2026", eligible_sectors="tourism,cashew,farmer,bakery"),
        db_mod.SubsidyDB(title="Green Tourism Grant", description="For beach shacks adopting zero-waste", amount="Rs.50,000", deadline="March 2026", eligible_sectors="tourism"),
        db_mod.SubsidyDB(title="Biogas Plant Subsidy", description="MNRE scheme for organic waste processors", amount="Rs.80,000", deadline="December 2025", eligible_sectors="farmer,cashew"),
    ])
    session.add_all([
        db_mod.ExchangeListingDB(business_id="b2", title="Surplus cashew husks", description="Available monthly -- good fuel for biogas", sector="Cashew"),
        db_mod.ExchangeListingDB(business_id="b1", title="Used cooking oil", description="Biofuel feedstock -- 50L/week", sector="Tourism"),
    ])
    session.commit()
    session.close()
    print("[OK] SQLite seeded!")


if __name__ == "__main__":
    if use_supabase():
        print("Seeding Supabase...")
        seed_supabase()
    else:
        print("No Supabase credentials found. Seeding SQLite...")
        seed_sqlite()
    print("   8 users, 5 activities, 2 businesses, 3 subsidies, 2 exchange listings")
    print("   Default test user: u1 (Priya Naik)")
