"""
run_migration.py
----------------
Connects directly to Supabase PostgreSQL, creates tables, and seeds data.
Usage: python run_migration.py
"""
import os, sys
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SERVICE_KEY  = os.environ.get("SUPABASE_SERVICE_KEY", "")

if not SUPABASE_URL or not SERVICE_KEY:
    print("ERROR: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in .env")
    sys.exit(1)

# Build Postgres connection string from Supabase URL
# Supabase DB host: db.<project-ref>.supabase.co  port: 5432
project_ref = SUPABASE_URL.replace("https://", "").replace(".supabase.co", "")
DB_HOST = f"db.{project_ref}.supabase.co"
DB_PORT = 5432
DB_NAME = "postgres"
DB_USER = "postgres"
# The postgres password is NOT the service key — it's set in Supabase Dashboard
# We'll use the supabase-py client instead via the REST API with service role

print("=" * 60)
print("GoaGreen Supabase Migration")
print("=" * 60)
print(f"Project ref: {project_ref}")
print()

# ── Use supabase-py with service_role to run table operations ──────
# Since we can't run raw SQL easily, we'll create tables by checking
# if they exist and creating them via the Supabase client's table API.
# The supabase-py client with service_role can do full CRUD.

from supabase import create_client

print("Connecting to Supabase...")
sb = create_client(SUPABASE_URL, SERVICE_KEY)
print("Connected!")
print()

# ── Test connection ────────────────────────────────────────────────
import httpx

HEADERS = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
}

def table_exists(table_name: str) -> bool:
    r = httpx.get(f"{SUPABASE_URL}/rest/v1/{table_name}?limit=1", headers=HEADERS, timeout=10)
    return r.status_code == 200

# Check if tables already exist
print("Checking existing tables...")
tables_to_check = ["users", "activities", "businesses", "house_items", "subsidies", "exchange_listings"]
existing = [t for t in tables_to_check if table_exists(t)]
missing  = [t for t in tables_to_check if not table_exists(t)]

if existing:
    print(f"  Found: {', '.join(existing)}")
if missing:
    print(f"  Missing: {', '.join(missing)}")
print()

if missing:
    print("Tables are missing! You need to run schema.sql in the Supabase SQL Editor.")
    print()
    print(">>> ACTION REQUIRED <<<")
    print(f"1. Open: https://supabase.com/dashboard/project/{project_ref}/sql/new")
    print("2. Paste the contents of: schema.sql")
    print("3. Click RUN")
    print("4. Then re-run this script to seed data")
    sys.exit(1)

print("All tables exist!")
print()

# ── Seed data ─────────────────────────────────────────────────────
print("Seeding demo data...")

from datetime import datetime, timezone, timedelta

now = datetime.now(timezone.utc)

priya = "00000000-0000-0000-0000-000000000004"
rahul = "00000000-0000-0000-0000-000000000001"
biz1  = "00000000-0000-0000-0000-100000000001"
biz2  = "00000000-0000-0000-0000-100000000002"

# Clean existing demo data
print("  Cleaning old demo data...")
for t in ["exchange_listings", "business_badges", "business_suggestions",
          "house_items", "subsidies", "activities", "businesses", "users"]:
    try:
        sb.table(t).delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
    except Exception as e:
        print(f"    Warning cleaning {t}: {e}")

print("  Inserting users...")
sb.table("users").insert([
    {"id": rahul, "name": "Rahul Dessai",    "avatar_initials": "RD", "green_coins": 1240, "total_co2_saved": 210.3, "streak_days": 21, "city": "Margao"},
    {"id": "00000000-0000-0000-0000-000000000002", "name": "Sneha Kamat",      "avatar_initials": "SK", "green_coins": 1105, "total_co2_saved": 188.7, "streak_days": 18, "city": "Mapusa"},
    {"id": "00000000-0000-0000-0000-000000000003", "name": "Dev Borkar",       "avatar_initials": "DB", "green_coins": 980,  "total_co2_saved": 165.2, "streak_days": 15, "city": "Vasco"},
    {"id": priya,                                  "name": "Priya Naik",       "avatar_initials": "PN", "green_coins": 840,  "total_co2_saved": 124.5, "streak_days": 12, "city": "Panaji"},
    {"id": "00000000-0000-0000-0000-000000000005", "name": "Amit Gaonkar",     "avatar_initials": "AG", "green_coins": 720,  "total_co2_saved": 98.1,  "streak_days": 9,  "city": "Ponda"},
    {"id": "00000000-0000-0000-0000-000000000006", "name": "Meera Shirodkar",  "avatar_initials": "MS", "green_coins": 610,  "total_co2_saved": 87.4,  "streak_days": 7,  "city": "Panaji"},
    {"id": "00000000-0000-0000-0000-000000000007", "name": "Kiran Naik",       "avatar_initials": "KN", "green_coins": 540,  "total_co2_saved": 72.0,  "streak_days": 5,  "city": "Calangute"},
    {"id": "00000000-0000-0000-0000-000000000008", "name": "Tara Figueiredo",  "avatar_initials": "TF", "green_coins": 420,  "total_co2_saved": 60.3,  "streak_days": 4,  "city": "Colva"},
]).execute()
print("    8 users inserted")

print("  Inserting activities...")
sb.table("activities").insert([
    {"user_id": priya, "title": "Cycled to work",       "category": "transport", "co2_kg": 1.68, "is_saving": True,  "analogy": "~76 cashew trees absorbing for a day", "logged_at": (now - timedelta(hours=2)).isoformat()},
    {"user_id": priya, "title": "Vegetarian lunch",     "category": "food",      "co2_kg": 0.50, "is_saving": True,  "analogy": "~22 cashew trees absorbing for a day", "logged_at": (now - timedelta(hours=5)).isoformat()},
    {"user_id": priya, "title": "Used AC for 4 hours",  "category": "energy",    "co2_kg": 1.20, "is_saving": False, "analogy": "~12 hours of AC",                      "logged_at": (now - timedelta(hours=8)).isoformat()},
    {"user_id": priya, "title": "Composted kitchen waste","category": "waste",   "co2_kg": 0.30, "is_saving": True,  "analogy": "~14 cashew trees absorbing for a day", "logged_at": (now - timedelta(days=1)).isoformat()},
    {"user_id": priya, "title": "Auto rickshaw ride",   "category": "transport", "co2_kg": 0.95, "is_saving": False, "analogy": "~0.1 trips by ferry",                  "logged_at": (now - timedelta(days=1, hours=3)).isoformat()},
]).execute()
print("    5 activities inserted")

print("  Inserting house items...")
sb.table("house_items").insert({"user_id": priya, "item_key": "h5", "item_name": "Compost Bin", "cost": 80}).execute()

print("  Inserting businesses...")
sb.table("businesses").insert([
    {"id": biz1, "name": "Rodrigues Beach Shack", "sector": "tourism", "owner_id": priya, "emissions_kg": 420,  "peer_avg_kg": 580},
    {"id": biz2, "name": "Naik Cashew Factory",   "sector": "cashew",  "owner_id": rahul, "emissions_kg": 1240, "peer_avg_kg": 980},
]).execute()
print("    2 businesses inserted")

print("  Inserting business suggestions...")
sb.table("business_suggestions").insert([
    {"business_id": biz1, "suggestion": "Switch to LED lighting"},
    {"business_id": biz1, "suggestion": "Install solar water heater"},
    {"business_id": biz1, "suggestion": "Use biodegradable packaging"},
    {"business_id": biz2, "suggestion": "Optimise roasting schedule"},
    {"business_id": biz2, "suggestion": "Switch to biomass fuel"},
    {"business_id": biz2, "suggestion": "Install dust collectors"},
]).execute()

print("  Inserting business badges...")
sb.table("business_badges").insert([
    {"business_id": biz1, "badge_name": "Low Carbon Star"},
    {"business_id": biz1, "badge_name": "Green Vendor"},
    {"business_id": biz2, "badge_name": "Quality Processor"},
]).execute()

print("  Inserting subsidies...")
sb.table("subsidies").insert([
    {"title": "Goa Solar Mission",    "description": "30% subsidy on rooftop solar for SMEs",         "amount": "Rs.1,20,000", "deadline": "June 2026",     "eligible_sectors": ["tourism", "cashew", "farmer", "bakery"]},
    {"title": "Green Tourism Grant",  "description": "For beach shacks adopting zero-waste",           "amount": "Rs.50,000",   "deadline": "March 2026",    "eligible_sectors": ["tourism"]},
    {"title": "Biogas Plant Subsidy", "description": "MNRE scheme for organic waste processors",       "amount": "Rs.80,000",   "deadline": "December 2025", "eligible_sectors": ["farmer", "cashew"]},
]).execute()
print("    3 subsidies inserted")

print("  Inserting exchange listings...")
sb.table("exchange_listings").insert([
    {"business_id": biz2, "title": "Surplus cashew husks", "description": "Available monthly -- good fuel for biogas", "sector": "Cashew"},
    {"business_id": biz1, "title": "Used cooking oil",     "description": "Biofuel feedstock -- 50L/week",             "sector": "Tourism"},
]).execute()
print("    2 listings inserted")

print()
print("=" * 60)
print("SUCCESS! GoaGreen Supabase is ready.")
print("=" * 60)
print()
print("  8 users  |  5 activities  |  2 businesses")
print("  3 subsidies  |  2 exchange listings")
print()
print("Test user: Priya Naik")
print(f"  User ID: {priya}")
print(f"  Use header: X-Dev-User-Id: {priya}")
