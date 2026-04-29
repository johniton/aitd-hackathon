# GoaGreen — Backend Handover Document

**Project:** GoaGreen — Carbon tracking app for Goa, India  
**Frontend:** Flutter (Dart), fully built, currently running on 100% static mock data  
**Backend to build:** FastAPI (Python)  
**Database:** Supabase (PostgreSQL) — schema already exists at `lib/data/supabase_schema.sql`  
**Context:** This is a hackathon project. The Flutter app is complete. The backend engineer needs to build a FastAPI server that the Flutter app will eventually call instead of reading from `lib/data/static_data.dart`.

---

## 1. App Overview

GoaGreen has **two modes**:

### Personal Mode
Users track their individual carbon footprint via daily activity logging. They earn **GreenCoins** for eco-friendly actions, compete on a leaderboard, and upgrade a virtual eco-home (House Game).

### Business Mode
Small businesses (beach shacks, cashew factories, farms, bakeries) track their monthly emissions, compare against sector peers, apply for government subsidies, and list surplus materials for exchange.

---

## 2. Database Schema (already written)

File: `lib/data/supabase_schema.sql`

### Tables

#### `users`
```sql
id            uuid primary key
name          text
avatar_initials text
green_coins   numeric default 0
total_co2_saved numeric default 0
streak_days   integer default 0
city          text
created_at    timestamptz
```
This is the core personal user table. `green_coins` and `total_co2_saved` should be updated server-side whenever a new activity is logged (never trust client-sent totals).

#### `activities`
```sql
id        uuid primary key
user_id   uuid → users.id
title     text
category  text  -- enum: 'transport' | 'food' | 'energy' | 'waste'
co2_kg    numeric
is_saving boolean  -- true = eco action (saves carbon), false = carbon-emitting action
analogy   text     -- human-readable string e.g. "≈ 5 cashew trees absorbing for a day"
logged_at timestamptz
```

#### `businesses`
```sql
id           uuid primary key
name         text
sector       text  -- enum: 'tourism' | 'cashew' | 'farmer' | 'bakery'
owner_id     uuid → users.id
emissions_kg numeric   -- monthly total
peer_avg_kg  numeric   -- average for that sector
created_at   timestamptz
```

#### `business_suggestions`
```sql
id          uuid primary key
business_id uuid → businesses.id
suggestion  text
applied     boolean default false
```

#### `business_badges`
```sql
id          uuid primary key
business_id uuid → businesses.id
badge_name  text
earned_at   timestamptz
```

#### `house_items`
```sql
id           uuid primary key
user_id      uuid → users.id
item_key     text   -- e.g. 'h1', 'h2', etc. (see item catalogue below)
item_name    text
cost         integer
purchased_at timestamptz
```

#### `subsidies`
```sql
id               uuid primary key
title            text
description      text
amount           text    -- display string e.g. "₹1,20,000"
deadline         text    -- display string e.g. "June 2026"
eligible_sectors text[]  -- e.g. ['tourism', 'cashew']
```

#### `exchange_listings`
```sql
id          uuid primary key
business_id uuid → businesses.id
title       text
description text
sector      text
active      boolean default true
created_at  timestamptz
```

### Leaderboard View
The SQL file creates a view `leaderboard_view` that ranks users by `total_co2_saved` descending. Use this for the leaderboard endpoint — do not compute rank in Python.

### Row Level Security
RLS is enabled on `users`, `activities`, `house_items`. Policies restrict users to their own data. The FastAPI server should connect via the **service role key** (bypasses RLS) and enforce auth checks itself using the JWT from Supabase Auth.

---

## 3. Emission Factors (source of truth)

These are defined in `lib/data/emission_factors.dart`. The backend must use the same values when validating or computing CO₂:

```
Transport (kg CO₂ per km):
  car:      0.21
  bus:      0.089
  scooter:  0.113
  auto:     0.095
  bike/walk: 0.0

Food (kg CO₂ per meal):
  meat meal:  2.5
  veg meal:   0.5
  fish meal:  1.4

Energy (kg CO₂ per kWh, Goa grid):
  grid electricity: 0.82
  solar:            0.0

Waste (kg CO₂ per kg):
  landfill:  0.7
  composted: 0.1
  recycled:  0.05
```

### GreenCoin reward rules (defined in frontend log screen)
```
zero-carbon activity (co2_kg == 0): +20 coins
any carbon-emitting activity:       +5 coins  (for logging, not for emitting)
```

### Analogy string generator (replicate server-side for receipt/AI parsing):
```python
def analogy(co2_kg: float) -> str:
    if co2_kg < 1:
        return f"≈ {co2_kg * 10:.1f} hours of AC"
    if co2_kg < 5:
        return f"≈ {co2_kg / 0.022:.0f} cashew trees absorbing for a day"
    if co2_kg < 20:
        return f"≈ {co2_kg / 8:.1f} trips by ferry Panaji–Betim"
    return f"≈ {co2_kg / 21:.1f} days of average Goan household"
```

---

## 4. API Endpoints Needed

All endpoints return JSON. Base URL: `/api/v1`

Authentication: Supabase JWT in `Authorization: Bearer <token>` header.

---

### 4.1 Auth

The Flutter app will use Supabase Auth directly (email/password or phone OTP). After login, Supabase returns a JWT. FastAPI just needs to verify that JWT.

```
No custom auth endpoints needed.
Verify JWT using supabase-py or python-jose with the Supabase JWT secret.
```

---

### 4.2 Users

#### `GET /users/me`
Returns the current user's profile.

**Response:**
```json
{
  "id": "uuid",
  "name": "Priya Naik",
  "avatar_initials": "PN",
  "green_coins": 840,
  "total_co2_saved": 124.5,
  "streak_days": 12,
  "rank": 4,
  "city": "Panaji"
}
```

#### `PATCH /users/me`
Update display name or city.

**Body:**
```json
{
  "name": "Priya Naik",
  "city": "Panaji"
}
```

---

### 4.3 Activities

#### `GET /activities`
Returns current user's activity log, newest first.

**Query params:** `limit` (default 20), `offset` (default 0), `category` (optional filter)

**Response:**
```json
[
  {
    "id": "uuid",
    "title": "Cycled to work",
    "category": "transport",
    "co2_kg": 1.68,
    "is_saving": true,
    "analogy": "≈ 76 cashew trees absorbing for a day",
    "logged_at": "2026-04-29T10:00:00Z"
  }
]
```

#### `POST /activities`
Log a new activity. Backend must:
1. Validate `category` is one of transport/food/energy/waste
2. Validate `co2_kg` is non-negative
3. Generate `analogy` string server-side
4. Award GreenCoins (+20 if co2_kg == 0, else +5) and update `users.green_coins`
5. Add co2_kg to `users.total_co2_saved` only if `is_saving == true`
6. Update `streak_days` if this is the first activity logged today for this user

**Request body:**
```json
{
  "title": "Cycled to work",
  "category": "transport",
  "co2_kg": 1.68,
  "is_saving": true
}
```

**Response:** The created activity object (same shape as GET).

#### `GET /activities/weekly`
Returns 7 floats representing total CO₂ for Mon–Sun of the current week.

**Response:**
```json
{
  "days": [2.1, 4.3, 1.8, 5.2, 3.6, 2.9, 4.1]
}
```

#### `GET /activities/wrapped`
Returns annual summary stats for the "Spotify Wrapped" screen.

**Response:**
```json
{
  "co2_saved": 124.5,
  "trees_equivalent": 17,
  "top_category": "transport",
  "best_week": "March 3–9",
  "percentile": 82,
  "activities_logged": 147,
  "green_coins_earned": 840
}
```
`trees_equivalent` = `total_co2_saved / 7.3` (one mature tree absorbs ~7.3 kg CO₂/year).  
`percentile` = what % of users this person beats by total_co2_saved.

---

### 4.4 Leaderboard

#### `GET /leaderboard`
Returns top users ranked by total_co2_saved.

**Query params:** `limit` (default 20), `city` (optional)

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Rahul Dessai",
    "avatar_initials": "RD",
    "green_coins": 1240,
    "total_co2_saved": 210.3,
    "streak_days": 21,
    "rank": 1,
    "city": "Margao"
  }
]
```

---

### 4.5 House Game

#### `GET /house`
Returns the current user's purchased house items.

**Response:**
```json
{
  "coins": 840,
  "items": [
    {
      "item_key": "h5",
      "item_name": "Compost Bin",
      "cost": 80,
      "purchased_at": "2026-04-01T00:00:00Z"
    }
  ]
}
```

#### `POST /house/buy`
Purchase a house item. Backend must:
1. Check user has enough `green_coins`
2. Check item not already purchased by this user
3. Deduct coins from `users.green_coins`
4. Insert into `house_items`

**Request body:**
```json
{
  "item_key": "h1"
}
```

**Response:**
```json
{
  "success": true,
  "coins_remaining": 640,
  "item_key": "h1"
}
```

### House Item Catalogue (static — no DB table needed)
| item_key | name | cost (coins) | description |
|---|---|---|---|
| h1 | Solar Roof | 200 | -30% energy emissions |
| h2 | Rain Garden | 150 | Absorbs 5kg CO₂/month |
| h3 | EV Charger | 300 | Unlock EV transport logging |
| h4 | Rainwater Tank | 180 | Save 500L water/month |
| h5 | Compost Bin | 80 | Double waste points |
| h6 | Terrace Farm | 220 | Grow your own food |

---

### 4.6 Business

#### `GET /business/my`
Returns the current user's business profile (if they registered as a business).

**Response:**
```json
{
  "id": "uuid",
  "name": "Rodrigues Beach Shack",
  "sector": "tourism",
  "sector_icon": "🏖️",
  "emissions_kg": 420,
  "peer_avg_kg": 580,
  "suggestions": ["Switch to LED lighting", "Install solar water heater"],
  "badges": ["Low Carbon Star", "Green Vendor"]
}
```

#### `POST /business`
Register a business for the current user.

**Request body:**
```json
{
  "name": "My Beach Shack",
  "sector": "tourism"
}
```

#### `PATCH /business/my/emissions`
Update monthly emissions figure.

**Request body:**
```json
{
  "emissions_kg": 450
}
```
Backend should recalculate peer_avg_kg automatically as the mean of all businesses in the same sector.

#### `GET /business/benchmark`
Returns benchmark data for the current user's business sector.

**Response:**
```json
{
  "my_emissions_kg": 420,
  "sector_avg_kg": 580,
  "best_in_class_kg": 210,
  "sector": "tourism",
  "peer_ranking": [
    {"name": "Rodrigues Beach Shack", "emissions_kg": 420, "is_me": true},
    {"name": "Silva Shack", "emissions_kg": 510, "is_me": false}
  ]
}
```

---

### 4.7 Subsidies

#### `GET /subsidies`
Returns all subsidies. Optionally filter by sector to mark eligibility.

**Query params:** `sector` (optional — if provided, marks `is_eligible` based on `eligible_sectors` array)

**Response:**
```json
[
  {
    "id": "uuid",
    "title": "Goa Solar Mission",
    "description": "30% subsidy on rooftop solar for SMEs",
    "amount": "₹1,20,000",
    "deadline": "June 2026",
    "is_eligible": true
  }
]
```

---

### 4.8 Exchange

#### `GET /exchange`
Returns all active exchange listings.

**Response:**
```json
[
  {
    "id": "uuid",
    "title": "Surplus cashew husks",
    "offered_by": "Naik Cashew",
    "sector": "cashew",
    "description": "Available monthly — good fuel for biogas",
    "active": true
  }
]
```

#### `POST /exchange`
Post a new exchange listing.

**Request body:**
```json
{
  "title": "Used cooking oil",
  "description": "Biofuel feedstock — 50L/week",
  "sector": "tourism"
}
```

#### `POST /exchange/{id}/interest`
Express interest in a listing. Can be a simple record or just trigger an email notification.

---

### 4.9 Green Map

#### `GET /map/zones`
Returns carbon intensity data per Goa city zone. This is currently hardcoded in the Flutter app — move it to the backend so it can be updated.

**Response:**
```json
[
  {
    "name": "Panaji",
    "label": "Low Carbon",
    "co2_per_cap": 2.1,
    "position_x": 0.42,
    "position_y": 0.28,
    "color_hex": "#10B981"
  },
  {"name": "Mapusa",    "label": "Medium",     "co2_per_cap": 4.8, "position_x": 0.35, "position_y": 0.18, "color_hex": "#EAB308"},
  {"name": "Margao",    "label": "Medium",     "co2_per_cap": 5.2, "position_x": 0.48, "position_y": 0.68, "color_hex": "#EAB308"},
  {"name": "Vasco",     "label": "High",       "co2_per_cap": 7.1, "position_x": 0.25, "position_y": 0.55, "color_hex": "#EF4444"},
  {"name": "Calangute", "label": "Low Carbon", "co2_per_cap": 1.9, "position_x": 0.22, "position_y": 0.22, "color_hex": "#10B981"},
  {"name": "Ponda",     "label": "Low Carbon", "co2_per_cap": 2.6, "position_x": 0.62, "position_y": 0.45, "color_hex": "#10B981"},
  {"name": "Colva",     "label": "Low Carbon", "co2_per_cap": 1.5, "position_x": 0.38, "position_y": 0.78, "color_hex": "#10B981"},
  {"name": "Canacona",  "label": "Low Carbon", "co2_per_cap": 1.2, "position_x": 0.45, "position_y": 0.92, "color_hex": "#10B981"}
]
```
`position_x` and `position_y` are fractions (0–1) of the map canvas width/height — the Flutter painter uses these directly.

---

## 5. FastAPI Project Structure (recommended)

```
backend/
├── main.py                  # FastAPI app, CORS, router includes
├── requirements.txt
├── .env                     # SUPABASE_URL, SUPABASE_SERVICE_KEY, SUPABASE_JWT_SECRET
├── app/
│   ├── auth.py              # JWT verification via python-jose or supabase-py
│   ├── database.py          # Supabase client setup
│   ├── models/
│   │   ├── user.py          # Pydantic models
│   │   ├── activity.py
│   │   ├── business.py
│   │   ├── house.py
│   │   ├── subsidy.py
│   │   └── exchange.py
│   ├── routers/
│   │   ├── users.py
│   │   ├── activities.py
│   │   ├── leaderboard.py
│   │   ├── house.py
│   │   ├── business.py
│   │   ├── subsidies.py
│   │   ├── exchange.py
│   │   └── map.py
│   └── logic/
│       ├── emission_factors.py   # Port of lib/data/emission_factors.dart
│       └── coins.py              # GreenCoin award logic
```

---

## 6. Requirements (requirements.txt)

```
fastapi>=0.111.0
uvicorn[standard]>=0.29.0
supabase>=2.4.0
python-jose[cryptography]>=3.3.0
pydantic>=2.0.0
python-dotenv>=1.0.0
httpx>=0.27.0
```

---

## 7. Auth Setup

Supabase issues JWTs. Verify them in FastAPI:

```python
# app/auth.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
import os

bearer_scheme = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)):
    token = credentials.credentials
    try:
        payload = jwt.decode(
            token,
            os.environ["SUPABASE_JWT_SECRET"],
            algorithms=["HS256"],
            audience="authenticated",
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

Use as a dependency:
```python
@router.get("/activities")
def get_activities(user_id: str = Depends(get_current_user)):
    ...
```

---

## 8. Supabase Client Setup

```python
# app/database.py
import os
from supabase import create_client, Client

def get_supabase() -> Client:
    url = os.environ["SUPABASE_URL"]
    key = os.environ["SUPABASE_SERVICE_KEY"]  # service role key, not anon key
    return create_client(url, key)
```

---

## 9. Emission Logic (Python port)

```python
# app/logic/emission_factors.py

TRANSPORT_KG_PER_KM = {
    "car": 0.21,
    "bus": 0.089,
    "scooter": 0.113,
    "auto": 0.095,
    "bike": 0.0,
    "walk": 0.0,
}

FOOD_KG_PER_MEAL = {
    "meat": 2.5,
    "veg": 0.5,
    "fish": 1.4,
}

ENERGY_KG_PER_KWH = {
    "grid": 0.82,
    "solar": 0.0,
}

WASTE_KG_PER_KG = {
    "landfill": 0.7,
    "composted": 0.1,
    "recycled": 0.05,
}

def analogy(co2_kg: float) -> str:
    if co2_kg < 1:
        return f"≈ {co2_kg * 10:.1f} hours of AC"
    if co2_kg < 5:
        return f"≈ {co2_kg / 0.022:.0f} cashew trees absorbing for a day"
    if co2_kg < 20:
        return f"≈ {co2_kg / 8:.1f} trips by ferry Panaji–Betim"
    return f"≈ {co2_kg / 21:.1f} days of average Goan household"

def coins_for_activity(co2_kg: float) -> int:
    return 20 if co2_kg == 0 else 5
```

---

## 10. CORS

The Flutter app will make requests from a mobile device or emulator. Add permissive CORS for development:

```python
# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="GoaGreen API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## 11. What the Flutter App Expects (Integration Notes)

- All dates/times as **ISO 8601 UTC strings** (`2026-04-29T10:00:00Z`)
- All monetary amounts as **display strings** (`"₹1,20,000"`) — Flutter shows them verbatim
- All CO₂ values as **floats in kg** — Flutter formats them with `.toStringAsFixed(3)`
- Endpoints that the Flutter app currently mocks from `lib/data/static_data.dart` and needs replaced:
  - `currentUser` → `GET /users/me`
  - `recentActivities` → `GET /activities?limit=5`
  - `weeklyData` → `GET /activities/weekly`
  - `leaderboard` → `GET /leaderboard`
  - `shopItems` + purchased state → `GET /house`
  - `businessProfiles` → `GET /business/my`
  - `subsidies` → `GET /subsidies?sector=tourism`
  - `exchangeItems` → `GET /exchange`
  - `wrappedStats` → `GET /activities/wrapped`
  - `_zones` (map) → `GET /map/zones`

---

## 12. Streaks Logic

When a user logs an activity:
1. Check `activities` for the user's most recent activity before this one
2. If the most recent was **yesterday** (date only, not time): `streak_days += 1`
3. If the most recent was **today**: streak unchanged
4. If the most recent was **2+ days ago** or there are no previous activities: `streak_days = 1`

---

## 13. Sector Peer Average

When a business updates `emissions_kg`, recalculate `peer_avg_kg` for all businesses in that sector:

```python
avg = db.table("businesses") \
    .select("emissions_kg") \
    .eq("sector", sector) \
    .execute()
new_avg = sum(r["emissions_kg"] for r in avg.data) / len(avg.data)
# update all businesses in that sector with new_avg
```

---

## 14. Error Response Format

Use standard HTTP status codes. Return errors as:
```json
{
  "detail": "Not enough GreenCoins"
}
```
FastAPI's default `HTTPException` format matches this — no custom error handling needed.

---

## 15. Deployment

For the hackathon, run locally:
```bash
uvicorn main:app --reload --port 8000
```

Update `lib/data/static_data.dart` with API calls pointing to `http://10.0.2.2:8000/api/v1` (Android emulator localhost alias) or `http://localhost:8000/api/v1` (iOS simulator / web).
