import httpx

STEAM_API = "https://store.steampowered.com/api/appdetails"
STEAM_CDN = "https://cdn.akamai.steamstatic.com/steam/apps"


def _steam_hero_url(steam_app_id: str) -> str:
    """Wide hero banner (~1920×620) — much sharper than header.jpg (~460×215)."""
    if steam_app_id and steam_app_id != "0":
        return f"{STEAM_CDN}/{steam_app_id}/library_hero.jpg"
    return ""


async def get_steam_details(steam_app_id: str) -> dict:
    """Fetch rich game details from the Steam Store API. Returns {} if unavailable."""
    async with httpx.AsyncClient(timeout=10) as client:
        try:
            response = await client.get(
                STEAM_API,
                params={"appids": steam_app_id, "cc": "us", "l": "english"},
            )
            response.raise_for_status()
        except (httpx.HTTPStatusError, httpx.RequestError):
            return {}

    data = response.json()
    app_data = data.get(str(steam_app_id), {})
    if not app_data.get("success"):
        return {}

    d = app_data.get("data", {})
    price = d.get("price_overview", {})

    api_header = d.get("header_image", "")
    hero = _steam_hero_url(steam_app_id)

    return {
        "description": d.get("short_description", ""),
        "headerImage": hero or api_header,
        "genres": [g["description"] for g in d.get("genres", [])],
        "developers": d.get("developers", []),
        "publishers": d.get("publishers", []),
        "releaseDate": d.get("release_date", {}).get("date", ""),
        "metacriticScore": d.get("metacritic", {}).get("score"),
        "screenshots": [
            s["path_full"] for s in d.get("screenshots", [])[:6]
        ],
        "steamPrice": price.get("final_formatted", ""),
        "steamDiscount": price.get("discount_percent", 0),
    }
