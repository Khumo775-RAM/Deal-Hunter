from fastapi import APIRouter, Query
from typing import List, Optional

from models.deal import Deal
from services.cheapshark_service import fetch_deals
from services.currency_service import get_exchange_rate, convert_price

router = APIRouter(prefix="/deals", tags=["Deals"])


@router.get("/", response_model=List[Deal])
async def get_deals(
    page: int = Query(0, ge=0, description="Page number (0-indexed)"),
    page_size: int = Query(20, ge=1, le=60, description="Number of deals per page"),
    store_id: Optional[str] = Query(None, description="Filter by store ID (e.g. 1=Steam, 7=GOG)"),
    min_discount: float = Query(0, ge=0, le=100, description="Minimum discount percentage to include"),
    sort_by: Optional[str] = Query(None, description="Sort results: 'discount' (best deals first) or 'price' (lowest price first)"),
    currency: str = Query("USD", description="Currency code for prices (e.g. USD, EUR, GBP, ZAR)"),
):
    """Return current game deals from CheapShark with optional filtering, sorting, and currency conversion."""
    deals = await fetch_deals(page=page, page_size=page_size, store_id=store_id)

    if min_discount > 0:
        deals = [d for d in deals if d.discount >= min_discount]

    if sort_by == "discount":
        deals.sort(key=lambda d: d.discount, reverse=True)
    elif sort_by == "price":
        deals.sort(key=lambda d: d.salePrice)

    currency = currency.upper()
    if currency != "USD":
        rate = await get_exchange_rate(currency)
        converted = []
        for deal in deals:
            converted.append(Deal(
                title=deal.title,
                salePrice=convert_price(deal.salePrice, rate),
                normalPrice=convert_price(deal.normalPrice, rate),
                discount=deal.discount,
                store=deal.store,
                currency=currency,
                dealID=deal.dealID,
                dealUrl=deal.dealUrl,
                gameID=deal.gameID,
                steamAppID=deal.steamAppID,
                thumb=deal.thumb,
                lastSaleDate=deal.lastSaleDate,
            ))
        return converted

    return deals
