import asyncio

from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List

from models.game import Game, TrackedGame
from models.user import UserPublic
from services import tracking_service
from services.auth_service import get_current_user
from services.cheapshark_service import validate_game_id, get_game_info
from services.currency_service import get_exchange_rate, convert_price

router = APIRouter(prefix="/track", tags=["Tracking"])


@router.get("/", response_model=List[TrackedGame])
async def get_tracked(
    current_user: UserPublic = Depends(get_current_user),
    currency: str = Query("USD", description="Currency code for prices"),
):
    """Return tracked games enriched with current thumbnail and cheapest deal."""
    games = tracking_service.get_tracked_games(username=current_user.username)
    if not games:
        return []

    infos = await asyncio.gather(
        *[get_game_info(g.gameId) for g in games],
        return_exceptions=True,
    )

    currency = currency.upper()
    rate = await get_exchange_rate(currency) if currency != "USD" else None

    result = []
    for game, info in zip(games, infos):
        enriched = game.model_dump()
        if isinstance(info, dict):
            enriched.update(info)
            if rate is not None:
                if enriched.get("cheapestPrice") is not None:
                    enriched["cheapestPrice"] = convert_price(enriched["cheapestPrice"], rate)
                if enriched.get("retailPrice") is not None:
                    enriched["retailPrice"] = convert_price(enriched["retailPrice"], rate)
        enriched["currency"] = currency
        result.append(TrackedGame(**enriched))
    return result


@router.post("/", response_model=TrackedGame, status_code=201)
async def track_game(game: Game, current_user: UserPublic = Depends(get_current_user)):
    """Add a game to the logged-in user's tracking list. Validates both title and gameId against CheapShark."""
    real_title = await validate_game_id(game.gameId)

    if real_title is None:
        raise HTTPException(
            status_code=404,
            detail=f"Game ID '{game.gameId}' was not found on CheapShark. Please use a valid game ID from the search results."
        )

    if game.title.strip().lower() != real_title.strip().lower():
        raise HTTPException(
            status_code=400,
            detail=f"Game name '{game.title}' does not match the game ID provided. The correct name is '{real_title}'."
        )

    verified_game = Game(title=real_title, gameId=game.gameId)

    try:
        return tracking_service.add_tracked_game(verified_game, username=current_user.username)
    except ValueError as e:
        raise HTTPException(status_code=409, detail=str(e))


@router.delete("/{game_id}", status_code=204)
def untrack_game(game_id: str, current_user: UserPublic = Depends(get_current_user)):
    """Remove a game from the logged-in user's tracking list."""
    removed = tracking_service.remove_tracked_game(game_id, username=current_user.username)
    if not removed:
        raise HTTPException(status_code=404, detail=f"Game with id '{game_id}' is not being tracked.")
