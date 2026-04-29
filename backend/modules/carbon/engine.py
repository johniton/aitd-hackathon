from core.constants import EMISSION_FACTORS

def calculate(category: str, type: str, value: float) -> float:
    """
    Calculate carbon emissions based on predefined emission factors.
    """
    category_factors = EMISSION_FACTORS.get(category, {})
    factor = category_factors.get(type)
    
    if factor is None:
        raise ValueError(f"Unknown category '{category}' or type '{type}' for emission calculation.")
        
    return value * factor
