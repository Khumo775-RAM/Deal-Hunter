def format_discount(normal: float, sale: float) -> float:
    """Calculate percentage discount rounded to one decimal place."""
    if normal <= 0:
        return 0.0
    return round(((normal - sale) / normal) * 100, 1)


def safe_float(value, default: float = 0.0) -> float:
    """Safely convert a value to float, returning default on failure."""
    try:
        return float(value)
    except (TypeError, ValueError):
        return default
