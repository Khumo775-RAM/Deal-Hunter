from unittest.mock import patch, AsyncMock
from tests.conftest import MOCK_DEALS


def test_get_deals_returns_list(client):
    with patch("routes.deals.fetch_deals", new_callable=AsyncMock, return_value=MOCK_DEALS):
        response = client.get("/deals/")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
    assert len(response.json()) == 3


def test_get_deals_sorted_by_discount(client):
    with patch("routes.deals.fetch_deals", new_callable=AsyncMock, return_value=MOCK_DEALS):
        response = client.get("/deals/?sort_by=discount")
    discounts = [d["discount"] for d in response.json()]
    assert discounts == sorted(discounts, reverse=True)


def test_get_deals_sorted_by_price(client):
    with patch("routes.deals.fetch_deals", new_callable=AsyncMock, return_value=MOCK_DEALS):
        response = client.get("/deals/?sort_by=price")
    prices = [d["salePrice"] for d in response.json()]
    assert prices == sorted(prices)


def test_get_deals_min_discount_filters_results(client):
    with patch("routes.deals.fetch_deals", new_callable=AsyncMock, return_value=MOCK_DEALS):
        response = client.get("/deals/?min_discount=50")
    data = response.json()
    assert all(d["discount"] >= 50 for d in data)
    assert len(data) == 2


def test_get_deals_min_discount_100_returns_empty(client):
    with patch("routes.deals.fetch_deals", new_callable=AsyncMock, return_value=MOCK_DEALS):
        response = client.get("/deals/?min_discount=100")
    assert response.json() == []


def test_get_deals_invalid_currency_returns_400(client):
    with patch("routes.deals.fetch_deals", new_callable=AsyncMock, return_value=MOCK_DEALS):
        response = client.get("/deals/?currency=FAKE")
    assert response.status_code == 400


def test_get_deals_currency_conversion(client):
    with patch("routes.deals.fetch_deals", new_callable=AsyncMock, return_value=MOCK_DEALS), \
         patch("routes.deals.get_exchange_rate", new_callable=AsyncMock, return_value=18.5):
        response = client.get("/deals/?currency=ZAR")
    assert response.status_code == 200
    data = response.json()
    assert data[0]["currency"] == "ZAR"
    assert data[0]["salePrice"] == round(5.0 * 18.5, 2)


def test_get_deals_no_auth_required(client):
    with patch("routes.deals.fetch_deals", new_callable=AsyncMock, return_value=MOCK_DEALS):
        response = client.get("/deals/")
    assert response.status_code == 200
