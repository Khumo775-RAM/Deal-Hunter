from pydantic import BaseModel


class Game(BaseModel):
    title: str
    gameId: str


class TrackedGame(Game):
    tracked_at: str
    thumb: str = ""
    currency: str = "USD"
    cheapestPrice: float | None = None
    cheapestStore: str | None = None
    retailPrice: float | None = None
