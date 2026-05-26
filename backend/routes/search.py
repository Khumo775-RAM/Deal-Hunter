from fastapi import APIRouter, Query, HTTPException
from services.cheapshark_service import search_games
from services.currency_service import get_exchange_rate, convert_price

router = APIRouter(prefix="/search", tags=["Search"])


@router.get("/")
async def search(
    title: str = Query(..., min_length=1, description="Game title to search for"),
    currency: str = Query("USD", description="Currency code for prices"),
):
    """Search for games by title using the CheapShark API."""
    results = await search_games(title)
    if not results:
        raise HTTPException(status_code=404, detail=f"No games found matching '{title}'")

    currency = currency.upper()
    if currency != "USD":
        rate = await get_exchange_rate(currency)
        for r in results:
            try:
                r["cheapest"] = f"{convert_price(float(r['cheapest']), rate):.2f}"
            except (ValueError, KeyError, TypeError):
                pass

    for r in results:
        r["currency"] = currency

    return results
