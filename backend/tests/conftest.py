import pytest
from unittest.mock import patch
from fastapi.testclient import TestClient

from main import app
from models.deal import Deal

# ── Shared mock data ──────────────────────────────────────────────────────────

MOCK_DEALS = [
    Deal(title="Game A", salePrice=5.0,  normalPrice=20.0, discount=75.0, store="Steam",    dealID="deal1", thumb="", lastSaleDate="01 April 2026"),
    Deal(title="Game B", salePrice=10.0, normalPrice=20.0, discount=50.0, store="GOG",      dealID="deal2", thumb="", lastSaleDate="02 April 2026"),
    Deal(title="Game C", salePrice=15.0, normalPrice=20.0, discount=25.0, store="Fanatical", dealID="deal3", thumb="", lastSaleDate="03 April 2026"),
]

MOCK_SEARCH_RESULTS = [
    {"gameID": "12345", "title": "Cyberpunk 2077",      "cheapest": "29.99", "thumb": ""},
    {"gameID": "12346", "title": "Cyberpunk 2077 Gold", "cheapest": "39.99", "thumb": ""},
]


# ── Fixtures ──────────────────────────────────────────────────────────────────

@pytest.fixture
def client(tmp_path):
    """Test client using isolated temp files for user/tracking storage."""
    users_file    = tmp_path / "users.json";    users_file.write_text("[]")
    tracked_file  = tmp_path / "tracked.json";  tracked_file.write_text("{}")
    blacklist_file = tmp_path / "blacklist.json"; blacklist_file.write_text("[]")

    with patch("services.auth_service.USERS_FILE",    str(users_file)), \
         patch("services.auth_service.BLACKLIST_FILE", str(blacklist_file)), \
         patch("services.tracking_service.DATA_FILE",  str(tracked_file)):
        with TestClient(app) as c:
            yield c


@pytest.fixture
def registered_user(client):
    """Register a test user and return their credentials."""
    client.post("/auth/register", json={
        "username": "testuser",
        "email": "test@example.com",
        "password": "password123",
    })
    return {"username": "testuser", "password": "password123"}


@pytest.fixture
def auth_token(client, registered_user):
    """Log in and return the JWT access token."""
    response = client.post("/auth/login", data={
        "username": registered_user["username"],
        "password": registered_user["password"],
    })
    return response.json()["access_token"]


@pytest.fixture
def auth_headers(auth_token):
    """Return Authorization header dict ready to pass to requests."""
    return {"Authorization": f"Bearer {auth_token}"}
