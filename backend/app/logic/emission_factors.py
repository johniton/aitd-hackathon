"""
Emission factors — exact port of lib/data/emission_factors.dart.
These are the source of truth for CO₂ calculations.
"""

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
    """Generate a Goa-specific analogy string for a CO₂ amount."""
    if co2_kg < 1:
        return f"≈ {co2_kg * 10:.1f} hours of AC"
    if co2_kg < 5:
        return f"≈ {co2_kg / 0.022:.0f} cashew trees absorbing for a day"
    if co2_kg < 20:
        return f"≈ {co2_kg / 8:.1f} trips by ferry Panaji–Betim"
    return f"≈ {co2_kg / 21:.1f} days of average Goan household"


def coins_for_activity(co2_kg: float) -> int:
    """GreenCoin reward: +20 for zero-carbon, +5 for any emission activity."""
    return 20 if co2_kg == 0 else 5
