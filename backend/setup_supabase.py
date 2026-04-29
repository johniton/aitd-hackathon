"""
setup_supabase.py
-----------------
Creates all Supabase tables (via the SQL endpoint) and seeds demo data.

Usage:
    python setup_supabase.py

Requirements:
- SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in .env
- The service_role key (JWT starting with eyJ...) is needed for the SQL endpoint.
  The anon/publishable key won't work for DDL.

To get the service_role key:
  Supabase Dashboard → Project Settings → API → service_role key (reveal it)
"""

import os, sys, httpx
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")

if not SUPABASE_URL or not SERVICE_KEY:
    print("ERROR: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in .env")
    sys.exit(1)

# ── Check if the key is the correct service_role JWT format ─────────

if not SERVICE_KEY.startswith("eyJ"):
    print("=" * 70)
    print("ERROR: SUPABASE_SERVICE_KEY does not look like a JWT service_role key.")
    print()
    print("Your current key starts with:", SERVICE_KEY[:20])
    print()
    print("The correct key should start with 'eyJ...' (a long JWT string).")
    print()
    print("To get it:")
    print(f"  1. Go to: {SUPABASE_URL.replace('.supabase.co', '')}/settings/api")
    print("     (or: Supabase Dashboard → Your Project → Project Settings → API)")
    print("  2. Under 'Project API keys', find 'service_role' and click 'Reveal'")
    print("  3. Copy the full JWT and update SUPABASE_SERVICE_KEY in your .env file")
    print("  4. Re-run this script")
    print("=" * 70)
    sys.exit(1)

HEADERS = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
}

# ── SQL Schema ──────────────────────────────────────────────────────

SCHEMA_SQL = """
-- Drop existing tables in reverse dependency order
drop table if exists exchange_listings cascade;
drop table if exists business_badges cascade;
drop table if exists business_suggestions cascade;
drop table if exists house_items cascade;
drop table if exists subsidies cascade;
drop table if exists activities cascade;
drop table if exists businesses cascade;
drop table if exists users cascade;

-- Users
create table users (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  avatar_initials text not null,
  green_coins numeric default 0,
  total_co2_saved numeric default 0,
  streak_days integer default 0,
  city text default '',
  created_at timestamptz default now()
);

-- Activities
create table activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  title text not null,
  category text check (category in ('transport', 'food', 'energy', 'waste')),
  co2_kg numeric not null,
  is_saving boolean default true,
  analogy text default '',
  logged_at timestamptz default now()
);

-- Businesses
create table businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sector text check (sector in ('tourism', 'cashew', 'farmer', 'bakery')),
  owner_id uuid references users(id) unique,
  emissions_kg numeric default 0,
  peer_avg_kg numeric default 0,
  created_at timestamptz default now()
);

create table business_suggestions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade,
  suggestion text not null,
  applied boolean default false
);

create table business_badges (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade,
  badge_name text not null,
  earned_at timestamptz default now()
);

-- House Game
create table house_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  item_key text not null,
  item_name text not null,
  cost integer not null,
  purchased_at timestamptz default now()
);

-- Subsidies
create table subsidies (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text default '',
  amount text default '',
  deadline text default '',
  eligible_sectors text[] default '{}'
);

-- Exchange
create table exchange_listings (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id) on delete cascade,
  title text not null,
  description text default '',
  sector text default '',
  active boolean default true,
  created_at timestamptz default now()
);

-- Disable RLS for service role (service role bypasses RLS anyway)
alter table users disable row level security;
alter table activities disable row level security;
alter table house_items disable row level security;
alter table businesses disable row level security;
alter table subsidies disable row level security;
alter table exchange_listings disable row level security;
alter table business_suggestions disable row level security;
alter table business_badges disable row level security;
"""


def run_sql(sql: str, label: str):
    """Execute SQL via the Supabase SQL endpoint."""
    # Try the management API first
    project_ref = SUPABASE_URL.replace("https://", "").replace(".supabase.co", "")
    mgmt_url = f"https://api.supabase.com/v1/projects/{project_ref}/database/query"
    
    r = httpx.post(
        mgmt_url,
        headers={"Authorization": f"Bearer {SERVICE_KEY}", "Content-Type": "application/json"},
        json={"query": sql},
        timeout=30,
    )
    if r.status_code == 200:
        print(f"  ✅ {label}")
        return True
    
    # Fallback: try the rpc/sql method  
    rpc_url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
    r2 = httpx.post(rpc_url, headers=HEADERS, json={"query": sql}, timeout=30)
    if r2.status_code == 200:
        print(f"  ✅ {label}")
        return True
    
    print(f"  ❌ {label} failed: {r.status_code} {r.text[:200]}")
    return False


def verify_tables():
    """Check if tables now exist."""
    r = httpx.get(f"{SUPABASE_URL}/rest/v1/users?limit=1", headers=HEADERS, timeout=10)
    return r.status_code == 200


print("=" * 60)
print("GoaGreen Supabase Setup")
print("=" * 60)
print(f"Project: {SUPABASE_URL}")
print()

# ── Step 1: Create tables ───────────────────────────────────────────
print("Step 1: Creating database schema...")
print("  Note: If this fails, please run schema.sql manually in the")
print(f"  Supabase SQL Editor: {SUPABASE_URL.replace('.supabase.co', '')}/sql/new")
print()

ok = run_sql(SCHEMA_SQL, "Schema created")

if not ok:
    print()
    print("Automatic schema creation failed. Please:")
    print("1. Open the Supabase SQL Editor")
    print(f"   → https://supabase.com/dashboard/project/{SUPABASE_URL.replace('https://','').replace('.supabase.co','')}/sql/new")
    print("2. Paste the contents of: schema.sql")
    print("3. Click 'Run'")
    print("4. Then run: python seed.py")
    sys.exit(1)

# ── Step 2: Verify ──────────────────────────────────────────────────
print()
print("Step 2: Verifying tables exist...")
if verify_tables():
    print("  ✅ Tables are accessible!")
else:
    print("  ❌ Tables still not accessible via REST API.")
    print("  Please run schema.sql manually in the Supabase SQL Editor.")
    sys.exit(1)

# ── Step 3: Seed ────────────────────────────────────────────────────
print()
print("Step 3: Seeding demo data...")
from app.database import use_supabase
if use_supabase():
    from seed import seed_supabase
    seed_supabase()
else:
    print("  ⚠️  Supabase not detected — check .env")

print()
print("=" * 60)
print("✅ Setup complete! Your GoaGreen backend is ready.")
print("=" * 60)
