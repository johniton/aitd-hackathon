def get_suggestions(category: str, type: str, value: float, current_carbon: float) -> list[dict]:
    """
    Rule-based recommendations based on activity.
    """
    suggestions = []
    
    if category == "transport" and type == "car":
        suggestions.append({
            "alternative": "metro",
            "message": "Consider taking the metro instead of driving.",
            "estimated_savings_kg": round(current_carbon * 0.7, 2)
        })
    elif category == "food" and type == "meat":
        suggestions.append({
            "alternative": "veg",
            "message": "Switching to a vegetarian meal could significantly reduce emissions.",
            "estimated_savings_kg": round(current_carbon * 0.6, 2)
        })
    elif category == "waste" and type == "plastic":
        suggestions.append({
            "alternative": "reusable",
            "message": "Using a reusable bag or container helps reduce plastic waste.",
            "estimated_savings_kg": round(current_carbon * 0.9, 2)
        })
        
    return suggestions
