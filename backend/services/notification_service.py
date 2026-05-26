"""
Notification service — Option B implementation.

  • Keeps a price cache (data/price_cache.json) that maps:
      { username → { gameId → last_notified_price } }
  • On every check (startup + periodic):
      1. For each user with notifications enabled, fetch their tracked games.
      2. For each game, get the current best sale price from CheapShark.
      3. If the current price is lower than the cached price (or there is no
         cached entry), add it to that user's alert list.
      4. Send one email per user containing all new deals.
      5. Update the cache so repeat notifications aren't sent for the same price.
"""

import json
import os

import httpx

from services.auth_service import get_users_with_notifications
from services.cheapshark_service import get_game_info
from services.email_service import send_deal_alert, is_configured
from services import tracking_service

CACHE_FILE = os.path.join(os.path.dirname(__file__), "..", "data", "price_cache.json")


# ── Cache helpers ─────────────────────────────────────────────────────────────

def _load_cache() -> dict:
    if not os.path.exists(CACHE_FILE):
        return {}
    with open(CACHE_FILE, "r", encoding="utf-8") as f:
        try:
            return json.load(f)
        except json.JSONDecodeError:
            return {}


def _save_cache(cache: dict) -> None:
    os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(cache, f, indent=2)


# ── Main check function ───────────────────────────────────────────────────────

async def check_and_notify() -> None:
    """
    Check prices for all users with notifications enabled and send email
    alerts for any games that dropped in price since the last check.
    """
    if not is_configured():
        print("[Notifications] Email not configured — set GMAIL_SENDER and GMAIL_APP_PASS in .env")
        return

    users = get_users_with_notifications()
    if not users:
        print("[Notifications] No users have notifications enabled — skipping.")
        return

    cache = _load_cache()
    cache_dirty = False

    print(f"[Notifications] Checking prices for {len(users)} user(s)...")

    for user in users:
        username = user["username"]
        email    = user["email"]

        games = tracking_service.get_tracked_games(username)
        if not games:
            continue

        user_cache: dict = cache.setdefault(username, {})
        alerts: list[dict] = []

        for game in games:
            try:
                info = await get_game_info(game.gameId)
            except Exception as e:
                print(f"  [Notifications] Error fetching '{game.title}': {e}")
                continue

            current_price = info.get("cheapestPrice")
            if current_price is None:
                continue

            last_price = user_cache.get(game.gameId)

            # Notify if: no previous price on record, or price has dropped.
            if last_price is None or current_price < last_price:
                store    = info.get("cheapestStore", "Unknown")
                retail   = info.get("retailPrice") or current_price
                discount = round((1 - current_price / retail) * 100) if retail > 0 else 0

                alerts.append({
                    "title":           game.title,
                    "store":           store,
                    "sale_price":      current_price,
                    "normal_price":    retail,
                    "discount":        discount,
                    "currency_symbol": "$",   # cache always stores USD prices
                })
                user_cache[game.gameId] = current_price
                cache_dirty = True

        if alerts:
            recipient_name = username.capitalize()
            send_deal_alert(email, recipient_name, alerts)

    if cache_dirty:
        _save_cache(cache)

    print("[Notifications] Price check complete.")
