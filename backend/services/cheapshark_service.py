import asyncio
import re
import httpx
from datetime import datetime, timezone
from fastapi import HTTPException
from typing import List
from models.deal import Deal

# Matches edition/pack suffixes so we can find the base game on Steam.
# Handles patterns like "Back 4 Blood Deluxe", "Game: Deluxe Edition",
# "Game - Digital Deluxe Edition", "Destiny 2: Legacy Collection 2025".
_EDITION_RE = re.compile(
    r"(?:\s*[-–:]\s*|\s+)"
    r"(?:Deluxe|Ultimate|Standard|Gold|Premium|Complete|Definitive|"
    r"Enhanced|Remastered|Elite|Legendary|Platinum|Diamond|"
    r"Director.?s Cut|Collector.?s|Game of the Year|GOTY|"
    r"Digital Deluxe|Annual Pass|Season Pass|Legacy Collection|"
    r"Founder|Supporter|Starter|Special|Limited|Extended|"
    r"Anthology|Bundle|Pack|Collection|Trilogy|Saga|Series|"
    r"Anniversary|Expanded|Upgraded|Turbo|Super|Hyper|Mega|"
    r"Year One|Year 1|Season \d|Volume \d|Vol\.?\s*\d)"
    r".*$",
    re.IGNORECASE,
)


def _strip_edition(title: str) -> str:
    """Return the base game name with edition/pack suffixes removed."""
    stripped = _EDITION_RE.sub("", title).strip()
    return stripped if stripped else title

CHEAPSHARK_BASE = "https://www.cheapshark.com/api/1.0"
CHEAPSHARK_REDIRECT = "https://www.cheapshark.com/redirect.php"


def build_deal_url(deal_id: str) -> str:
    """CheapShark redirect link that sends the user to the store's purchase page."""
    if not deal_id or not str(deal_id).strip():
        return ""
    return f"{CHEAPSHARK_REDIRECT}?dealID={deal_id}"

HEADERS = {
    "User-Agent": (
        "GameDealTracker/1.0 - A personal game deal tracking app that fetches "
        "and monitors PC game prices across stores using the CheapShark API."
    )
}

STORE_NAMES = {
    "1":  "Steam",
    "2":  "GamersGate",
    "3":  "GreenManGaming",
    "4":  "Amazon",
    "5":  "GameStop",
    "6":  "Direct2Drive",
    "7":  "GOG",
    "8":  "Origin",
    "9":  "Get Games",
    "10": "Shiny Loot",
    "11": "Humble Store",
    "12": "Desura",
    "13": "Uplay",
    "14": "IndieGameStand",
    "15": "Fanatical",
    "16": "Gamesrocket",
    "17": "Games Republic",
    "18": "SilaGames",
    "19": "Playfield",
    "20": "ImperialGames",
    "21": "WinGameStore",
    "22": "FunStockDigital",
    "23": "GameBillet",
    "24": "Voidu",
    "25": "Epic Games Store",
    "26": "Razer Game Store",
    "27": "Gamesplanet",
    "28": "Gamesload",
    "29": "2Game",
    "30": "IndieGala",
    "31": "Blizzard Shop",
    "32": "AllYouPlay",
    "33": "DLGamer",
    "34": "Noctre",
    "35": "DreamGame",
}


def _resolve_store(store_id: str) -> str:
    return STORE_NAMES.get(str(store_id), f"Store {store_id}")


def _unix_to_date(timestamp) -> str:
    try:
        return datetime.fromtimestamp(int(timestamp), tz=timezone.utc).strftime("%d %B %Y")
    except (TypeError, ValueError, OSError):
        return ""


def _steam_header(steam_app_id: str) -> str:
    """Steam CDN header image — more reliably available than capsule thumbnails."""
    return f"https://cdn.akamai.steamstatic.com/steam/apps/{steam_app_id}/header.jpg"


def _parse_deal(raw: dict) -> Deal:
    normal_price = float(raw.get("normalPrice", 0))
    sale_price = float(raw.get("salePrice", 0))
    discount = round(((normal_price - sale_price) / normal_price) * 100, 1) if normal_price > 0 else 0.0

    steam_app_id = str(raw.get("steamAppID") or "")

    # Prefer the Steam CDN header when we have a valid steamAppID — it's far
    # more reliable than whatever third-party CDN CheapShark may point to.
    if steam_app_id and steam_app_id != "0":
        thumb = _steam_header(steam_app_id)
    else:
        thumb = raw.get("thumb", "")

    deal_id = raw.get("dealID", "") or ""

    return Deal(
        title=raw.get("title", "Unknown"),
        salePrice=sale_price,
        normalPrice=normal_price,
        discount=discount,
        store=_resolve_store(raw.get("storeID", "0")),
        dealID=deal_id,
        dealUrl=build_deal_url(deal_id),
        gameID=raw.get("gameID", ""),
        steamAppID=steam_app_id,
        thumb=thumb,
        lastSaleDate=_unix_to_date(raw.get("lastChange")),
    )


# Simple in-memory cache: gameID → steamAppID (avoids repeat CheapShark calls)
_steam_id_cache: dict[str, str] = {}

# Limit concurrent CheapShark enrichment calls to avoid 429 rate-limiting
_enrich_sem = asyncio.Semaphore(3)


async def _cheapshark_steam_id(client: httpx.AsyncClient, game_id: str) -> str:
    """Ask CheapShark /games for the steamAppID of a known gameID."""
    if game_id in _steam_id_cache:
        return _steam_id_cache[game_id]
    try:
        async with _enrich_sem:
            r = await client.get(f"{CHEAPSHARK_BASE}/games", params={"id": game_id})
            r.raise_for_status()
        sid = str(r.json().get("info", {}).get("steamAppID") or "")
        _steam_id_cache[game_id] = sid
        return sid
    except Exception:
        return ""


async def _steam_search_id(client: httpx.AsyncClient, query: str) -> str:
    """Search the Steam store for a title and return the first appid found."""
    try:
        async with _enrich_sem:
            r = await client.get(
                "https://store.steampowered.com/api/storesearch/",
                params={"term": query, "l": "english", "cc": "US"},
            )
            r.raise_for_status()
        items = r.json().get("items", [])
        if items:
            return str(items[0]["id"])
    except Exception:
        pass
    return ""


async def _resolve_steam_id(client: httpx.AsyncClient, game_id: str, title: str) -> str:
    """
    Return the Steam App ID for a deal, trying two strategies:
      1. CheapShark /games endpoint — authoritative direct gameID→steamAppID mapping
      2. Steam store search — fallback when CheapShark has no mapping (newer / unlisted games)
    """
    # Strategy 1 — CheapShark has a direct authoritative mapping for most games
    sid = await _cheapshark_steam_id(client, game_id)
    if sid and sid != "0":
        return sid

    # Strategy 2 — Steam store search by base title (avoids edition noise)
    base = _strip_edition(title)
    sid = await _steam_search_id(client, base)
    if sid and sid != "0":
        return sid

    return ""


def _is_edition_title(title: str) -> bool:
    """True when the title includes a deluxe/edition/collection suffix."""
    base = _strip_edition(title)
    return base.lower() != title.strip().lower()


async def resolve_display_steam_id(
    client: httpx.AsyncClient, game_id: str, title: str
) -> str:
    """
    Steam App ID used for images and store metadata in the UI.
    Edition listings (Deluxe, Ultimate, etc.) always map to the base game's Steam page.
    """
    base = _strip_edition(title)
    if _is_edition_title(title):
        sid = await _steam_search_id(client, base)
        if sid and sid != "0":
            return sid

    return await _resolve_steam_id(client, game_id, title)


async def get_display_steam_data(game_id: str, title: str) -> dict:
    """
    Fetch Steam store metadata for UI display.
    Returns description, screenshots, headerImage, steamAppID, etc.
    Edition games reuse the base game's Steam page.
    """
    from services.steam_service import get_steam_details

    async with httpx.AsyncClient(timeout=10, headers=HEADERS) as client:
        sid = await resolve_display_steam_id(client, game_id, title)

    if not sid or sid == "0":
        return {}

    data = await get_steam_details(sid)
    if not data and _is_edition_title(title):
        async with httpx.AsyncClient(timeout=10, headers=HEADERS) as client:
            sid = await _steam_search_id(client, _strip_edition(title))
        if sid and sid != "0":
            data = await get_steam_details(sid)

    if data:
        data["steamAppID"] = sid
    return data


async def fetch_deals(page: int = 0, page_size: int = 60, store_id: str | None = None) -> List[Deal]:
    params: dict = {"pageNumber": page, "pageSize": page_size, "onSale": 1}
    if store_id:
        params["storeID"] = store_id

    async with httpx.AsyncClient(timeout=10, headers=HEADERS) as client:
        try:
            response = await client.get(f"{CHEAPSHARK_BASE}/deals", params=params)
            response.raise_for_status()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=502, detail=f"CheapShark API error: {e.response.status_code}")
        except httpx.RequestError:
            raise HTTPException(status_code=503, detail="Could not reach CheapShark API")

    deals = [_parse_deal(item) for item in response.json()]

    # For deals without a Steam App ID, resolve it then back-fill both thumb and steamAppID.
    missing = [(i, d) for i, d in enumerate(deals) if not d.steamAppID and d.gameID]
    if missing:
        async with httpx.AsyncClient(timeout=8, headers=HEADERS) as enrich:
            resolved = await asyncio.gather(
                *[_resolve_steam_id(enrich, d.gameID, d.title) for _, d in missing],
                return_exceptions=True,
            )
        for (i, deal), steam_id in zip(missing, resolved):
            if isinstance(steam_id, str) and steam_id:
                updated = deal.model_dump()
                updated["steamAppID"] = steam_id
                updated["thumb"] = _steam_header(steam_id)
                deals[i] = Deal(**updated)

    return deals


async def search_games(title: str) -> list:
    async with httpx.AsyncClient(timeout=10, headers=HEADERS) as client:
        try:
            response = await client.get(f"{CHEAPSHARK_BASE}/games", params={"title": title})
            response.raise_for_status()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=502, detail=f"CheapShark API error: {e.response.status_code}")
        except httpx.RequestError:
            raise HTTPException(status_code=503, detail="Could not reach CheapShark API")

    results = []
    for item in response.json():
        results.append(
            {
                "gameID": item.get("gameID"),
                "title": item.get("external"),
                "cheapest": item.get("cheapest"),
                "thumb": item.get("thumb", ""),
            }
        )

    # Use the base game's Steam cover for deluxe/edition listings.
    if results:
        enriched = await asyncio.gather(
            *[_enrich_search_result(client, r) for r in results],
            return_exceptions=True,
        )
        results = [
            r if isinstance(r, dict) else results[i]
            for i, r in enumerate(enriched)
        ]

    return results


async def _enrich_search_result(client: httpx.AsyncClient, item: dict) -> dict:
    game_id = str(item.get("gameID") or "")
    title = item.get("title") or ""
    if not game_id or not title:
        return item
    sid = await resolve_display_steam_id(client, game_id, title)
    if sid and sid != "0":
        item = dict(item)
        item["thumb"] = _steam_header(sid)
    return item


async def validate_game_id(game_id: str) -> str | None:
    """Check if a gameId exists on CheapShark. Returns the real title or None if not found."""
    async with httpx.AsyncClient(timeout=10, headers=HEADERS) as client:
        try:
            response = await client.get(f"{CHEAPSHARK_BASE}/games", params={"id": game_id})
            response.raise_for_status()
        except (httpx.HTTPStatusError, httpx.RequestError):
            return None

    data = response.json()
    return data.get("info", {}).get("title") or None


async def get_game_info(game_id: str) -> dict:
    """Return thumbnail and cheapest current deal for a game."""
    async with httpx.AsyncClient(timeout=10, headers=HEADERS) as client:
        try:
            response = await client.get(f"{CHEAPSHARK_BASE}/games", params={"id": game_id})
            response.raise_for_status()
        except (httpx.HTTPStatusError, httpx.RequestError):
            return {}

    data = response.json()
    info = data.get("info", {})
    deals = data.get("deals", [])
    title = info.get("title", "")

    cheapest = min(deals, key=lambda d: float(d.get("price", 9999))) if deals else None

    thumb = info.get("thumb", "")
    if title and game_id:
        async with httpx.AsyncClient(timeout=10, headers=HEADERS) as enrich_client:
            sid = await resolve_display_steam_id(enrich_client, game_id, title)
        if sid and sid != "0":
            thumb = _steam_header(sid)

    deal_id = cheapest.get("dealID", "") if cheapest else ""

    return {
        "thumb": thumb,
        "cheapestPrice": float(cheapest["price"]) if cheapest else None,
        "retailPrice": float(cheapest["retailPrice"]) if cheapest else None,
        "cheapestStore": _resolve_store(cheapest["storeID"]) if cheapest else None,
        "dealUrl": build_deal_url(deal_id),
    }


async def fetch_game_deals(game_id: str) -> List[Deal]:
    """Fetch all current deals for a specific game by gameID."""
    async with httpx.AsyncClient(timeout=10, headers=HEADERS) as client:
        try:
            response = await client.get(f"{CHEAPSHARK_BASE}/games", params={"id": game_id})
            response.raise_for_status()
        except (httpx.HTTPStatusError, httpx.RequestError):
            return []

    data = response.json()
    deals_raw = data.get("deals", [])
    game_title = data.get("info", {}).get("title", "Unknown")

    result = []
    for d in deals_raw:
        normal_price = float(d.get("retailPrice", 0))
        sale_price = float(d.get("price", 0))
        discount = round(((normal_price - sale_price) / normal_price) * 100, 1) if normal_price > 0 else 0.0
        result.append(
            Deal(
                title=game_title,
                salePrice=sale_price,
                normalPrice=normal_price,
                discount=discount,
                store=_resolve_store(d.get("storeID", "0")),
                dealID=d.get("dealID", ""),
            )
        )
    return result
