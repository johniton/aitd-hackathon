"""
House item catalogue — static data, no DB table needed.
Matches the shopItems list in static_data.dart.
"""

HOUSE_ITEMS = {
    "h1": {"name": "Solar Roof",     "icon": "☀️",  "cost": 200, "description": "-30% energy emissions"},
    "h2": {"name": "Rain Garden",    "icon": "🌿",  "cost": 150, "description": "Absorbs 5kg CO₂/month"},
    "h3": {"name": "EV Charger",     "icon": "⚡",  "cost": 300, "description": "Unlock EV transport logging"},
    "h4": {"name": "Rainwater Tank", "icon": "💧",  "cost": 180, "description": "Save 500L water/month"},
    "h5": {"name": "Compost Bin",    "icon": "♻️",  "cost": 80,  "description": "Double waste points"},
    "h6": {"name": "Terrace Farm",   "icon": "🥦",  "cost": 220, "description": "Grow your own food"},
}
