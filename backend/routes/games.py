import httpx
from fastapi import APIRouter, HTTPException, Query

from models.game_detail import GameDetail
from services.cheapshark_service import (
    CHEAPSHARK_BASE,
    HEADERS,
    _resolve_store,
    build_deal_url,
    get_display_steam_data,
)
from services.currency_service import convert_price, get_exchange_rate

router = APIRouter(prefix="/games", tags=["Games"])


@router.get("/{game_id}", response_model=GameDetail)
async def get_game_detail(
    game_id: str,
    currency: str = Query("USD", description="Currency code for prices (e.g. USD, EUR, ZAR)"),
):
    """Return detailed info for a game: CheapShark deals + Steam store data."""
    async with httpx.AsyncClient(timeout=10, headers=HEADERS) as client:
        try:
            response = await client.get(
                f"{CHEAPSHARK_BASE}/games", params={"id": game_id}
            )
            response.raise_for_status()
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 429:
                raise HTTPException(
                    status_code=502,
                    detail="CheapShark API rate limit — try again shortly",
                )
            raise HTTPException(
                status_code=502,
                detail=f"CheapShark API error: {e.response.status_code}",
            )
        except httpx.RequestError:
            raise HTTPException(
                status_code=503, detail="Could not reach CheapShark API"
            )

    data = response.json()
    info = data.get("info", {})
    deals = data.get("deals", [])
    title = info.get("title", "Unknown")

    cheapest = (
        min(deals, key=lambda d: float(d.get("price", 9999))) if deals else None
    )

    cheapest_price = float(cheapest["price"]) if cheapest else None
    retail_price   = float(cheapest["retailPrice"]) if cheapest else None

    currency = currency.upper()
    if currency != "USD" and cheapest_price is not None:
        rate = await get_exchange_rate(currency)
        cheapest_price = convert_price(cheapest_price, rate)
        if retail_price is not None:
            retail_price = convert_price(retail_price, rate)

    # Steam metadata (images, synopsis, screenshots) from the base game for editions.
    steam_data = await get_display_steam_data(game_id, title)
    steam_app_id = steam_data.pop("steamAppID", None) or info.get("steamAppID")

    deal_id = cheapest.get("dealID", "") if cheapest else ""

    return GameDetail(
        title=title,
        gameId=game_id,
        thumb=info.get("thumb", ""),
        steamAppID=steam_app_id,
        currency=currency,
        cheapestPrice=cheapest_price,
        retailPrice=retail_price,
        cheapestStore=_resolve_store(cheapest["storeID"]) if cheapest else None,
        dealUrl=build_deal_url(deal_id),
        **steam_data,
    )
