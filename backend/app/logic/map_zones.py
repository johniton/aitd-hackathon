"""
Goa carbon-intensity map zones.
Matches the _zones list in green_map_screen.dart.
"""

SECTOR_ICONS = {
    "tourism": "🏖️",
    "cashew": "🌰",
    "farmer": "🌾",
    "bakery": "🍞",
}

MAP_ZONES = [
    {"name": "Panaji",    "label": "Low Carbon", "co2_per_cap": 2.1, "position_x": 0.42, "position_y": 0.28, "color_hex": "#10B981"},
    {"name": "Mapusa",    "label": "Medium",     "co2_per_cap": 4.8, "position_x": 0.35, "position_y": 0.18, "color_hex": "#EAB308"},
    {"name": "Margao",    "label": "Medium",     "co2_per_cap": 5.2, "position_x": 0.48, "position_y": 0.68, "color_hex": "#EAB308"},
    {"name": "Vasco",     "label": "High",       "co2_per_cap": 7.1, "position_x": 0.25, "position_y": 0.55, "color_hex": "#EF4444"},
    {"name": "Calangute", "label": "Low Carbon", "co2_per_cap": 1.9, "position_x": 0.22, "position_y": 0.22, "color_hex": "#10B981"},
    {"name": "Ponda",     "label": "Low Carbon", "co2_per_cap": 2.6, "position_x": 0.62, "position_y": 0.45, "color_hex": "#10B981"},
    {"name": "Colva",     "label": "Low Carbon", "co2_per_cap": 1.5, "position_x": 0.38, "position_y": 0.78, "color_hex": "#10B981"},
    {"name": "Canacona",  "label": "Low Carbon", "co2_per_cap": 1.2, "position_x": 0.45, "position_y": 0.92, "color_hex": "#10B981"},
]
