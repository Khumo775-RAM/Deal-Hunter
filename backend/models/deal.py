from pydantic import BaseModel


class Deal(BaseModel):
    title: str
    salePrice: float
    normalPrice: float
    discount: float
    store: str
    currency: str = "USD"
    dealID: str = ""
    dealUrl: str = ""
    gameID: str = ""
    steamAppID: str = ""
    thumb: str = ""
    lastSaleDate: str = ""
