from unittest.mock import patch, AsyncMock
from tests.conftest import MOCK_SEARCH_RESULTS


def test_search_returns_results(client):
    with patch("routes.search.search_games", new_callable=AsyncMock, return_value=MOCK_SEARCH_RESULTS):
        response = client.get("/search/?title=cyberpunk")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["gameID"] == "12345"
    assert data[0]["title"] == "Cyberpunk 2077"


def test_search_no_results_returns_404(client):
    with patch("routes.search.search_games", new_callable=AsyncMock, return_value=[]):
        response = client.get("/search/?title=xyzgamethatdoesnotexist")
    assert response.status_code == 404


def test_search_missing_title_returns_422(client):
    response = client.get("/search/")
    assert response.status_code == 422


def test_search_no_auth_required(client):
    with patch("routes.search.search_games", new_callable=AsyncMock, return_value=MOCK_SEARCH_RESULTS):
        response = client.get("/search/?title=test")
    assert response.status_code == 200
