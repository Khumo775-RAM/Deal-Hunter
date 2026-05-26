import json
import os
from datetime import datetime, timezone
from typing import List

from models.game import Game, TrackedGame

DATA_FILE = os.path.join(os.path.dirname(__file__), "..", "data", "tracked_games.json")


def _load_all() -> dict:
    """Load the full tracking file, which is a dict keyed by username."""
    if not os.path.exists(DATA_FILE):
        return {}
    with open(DATA_FILE, "r", encoding="utf-8") as f:
        try:
            data = json.load(f)
            return data if isinstance(data, dict) else {}
        except json.JSONDecodeError:
            return {}


def _save_all(data: dict) -> None:
    with open(DATA_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


def get_all_tracked_games() -> List[TrackedGame]:
    """Return every tracked game across all users (used by the background price checker)."""
    all_data = _load_all()
    games = []
    for user_games in all_data.values():
        games.extend([TrackedGame(**g) for g in user_games])
    return games


def get_tracked_games(username: str) -> List[TrackedGame]:
    """Return only the games tracked by the given user."""
    all_data = _load_all()
    user_games = all_data.get(username, [])
    return [TrackedGame(**g) for g in user_games]


def add_tracked_game(game: Game, username: str) -> TrackedGame:
    """Add a game to the given user's tracking list. Rejects duplicates."""
    all_data = _load_all()
    user_games = all_data.get(username, [])

    for existing in user_games:
        if existing.get("gameId") == game.gameId:
            raise ValueError(f"'{game.title}' is already being tracked.")

    tracked = TrackedGame(
        title=game.title,
        gameId=game.gameId,
        tracked_at=datetime.now(timezone.utc).isoformat(),
    )
    user_games.append(tracked.model_dump())
    all_data[username] = user_games
    _save_all(all_data)
    return tracked


def remove_tracked_game(game_id: str, username: str) -> bool:
    """Remove a game from the given user's tracking list."""
    all_data = _load_all()
    user_games = all_data.get(username, [])
    filtered = [g for g in user_games if g.get("gameId") != game_id]
    if len(filtered) == len(user_games):
        return False
    all_data[username] = filtered
    _save_all(all_data)
    return True
