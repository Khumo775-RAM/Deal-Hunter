from typing import List
from pydantic import BaseModel


class GameDetail(BaseModel):
    # CheapShark data
    title: str
    gameId: str
    thumb: str = ""
    steamAppID: str | None = None
    currency: str = "USD"
    cheapestPrice: float | None = None
    retailPrice: float | None = None
    cheapestStore: str | None = None
    dealUrl: str = ""

    # Steam data
    description: str = ""
    headerImage: str = ""
    genres: List[str] = []
    developers: List[str] = []
    publishers: List[str] = []
    releaseDate: str = ""
    metacriticScore: int | None = None
    screenshots: List[str] = []
    steamPrice: str = ""
    steamDiscount: int = 0
