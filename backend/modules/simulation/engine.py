def run(carbon: float, reduction: float = 0.7, days: int = 30) -> float:
    """
    Compute projected savings over a period of time.
    """
    # Simply project the daily savings over 'days'
    daily_savings = carbon * reduction
    projected_savings = daily_savings * days
    
    return round(projected_savings, 2)
