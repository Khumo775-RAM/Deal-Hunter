from unittest.mock import patch, AsyncMock


def test_get_tracked_requires_auth(client):
    response = client.get("/track/")
    assert response.status_code == 401


def test_get_tracked_returns_empty_list(client, auth_headers):
    response = client.get("/track/", headers=auth_headers)
    assert response.status_code == 200
    assert response.json() == []


def test_track_game_success(client, auth_headers):
    with patch("routes.tracking.validate_game_id", new_callable=AsyncMock, return_value="Cyberpunk 2077"):
        response = client.post("/track/", json={"title": "Cyberpunk 2077", "gameId": "22881"}, headers=auth_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Cyberpunk 2077"
    assert data["gameId"] == "22881"
    assert "tracked_at" in data


def test_track_game_appears_in_list(client, auth_headers):
    with patch("routes.tracking.validate_game_id", new_callable=AsyncMock, return_value="Cyberpunk 2077"):
        client.post("/track/", json={"title": "Cyberpunk 2077", "gameId": "22881"}, headers=auth_headers)
    response = client.get("/track/", headers=auth_headers)
    assert len(response.json()) == 1


def test_track_game_invalid_id_returns_404(client, auth_headers):
    with patch("routes.tracking.validate_game_id", new_callable=AsyncMock, return_value=None):
        response = client.post("/track/", json={"title": "Fake Game", "gameId": "999999"}, headers=auth_headers)
    assert response.status_code == 404


def test_track_game_wrong_title_returns_400(client, auth_headers):
    with patch("routes.tracking.validate_game_id", new_callable=AsyncMock, return_value="Cyberpunk 2077"):
        response = client.post("/track/", json={"title": "Wrong Title", "gameId": "22881"}, headers=auth_headers)
    assert response.status_code == 400


def test_track_duplicate_game_returns_409(client, auth_headers):
    with patch("routes.tracking.validate_game_id", new_callable=AsyncMock, return_value="Cyberpunk 2077"):
        client.post("/track/", json={"title": "Cyberpunk 2077", "gameId": "22881"}, headers=auth_headers)
        response = client.post("/track/", json={"title": "Cyberpunk 2077", "gameId": "22881"}, headers=auth_headers)
    assert response.status_code == 409


def test_track_requires_auth(client):
    response = client.post("/track/", json={"title": "Cyberpunk 2077", "gameId": "22881"})
    assert response.status_code == 401


def test_untrack_game_success(client, auth_headers):
    with patch("routes.tracking.validate_game_id", new_callable=AsyncMock, return_value="Cyberpunk 2077"):
        client.post("/track/", json={"title": "Cyberpunk 2077", "gameId": "22881"}, headers=auth_headers)
    response = client.delete("/track/22881", headers=auth_headers)
    assert response.status_code == 204


def test_untrack_game_removes_from_list(client, auth_headers):
    with patch("routes.tracking.validate_game_id", new_callable=AsyncMock, return_value="Cyberpunk 2077"):
        client.post("/track/", json={"title": "Cyberpunk 2077", "gameId": "22881"}, headers=auth_headers)
    client.delete("/track/22881", headers=auth_headers)
    response = client.get("/track/", headers=auth_headers)
    assert response.json() == []


def test_untrack_nonexistent_returns_404(client, auth_headers):
    response = client.delete("/track/999999", headers=auth_headers)
    assert response.status_code == 404


def test_tracked_games_are_per_user(client):
    client.post("/auth/register", json={"username": "user1", "email": "u1@test.com", "password": "password123"})
    client.post("/auth/register", json={"username": "user2", "email": "u2@test.com", "password": "password123"})

    token1 = client.post("/auth/login", data={"username": "user1", "password": "password123"}).json()["access_token"]
    token2 = client.post("/auth/login", data={"username": "user2", "password": "password123"}).json()["access_token"]

    headers1 = {"Authorization": f"Bearer {token1}"}
    headers2 = {"Authorization": f"Bearer {token2}"}

    with patch("routes.tracking.validate_game_id", new_callable=AsyncMock, return_value="Cyberpunk 2077"):
        client.post("/track/", json={"title": "Cyberpunk 2077", "gameId": "22881"}, headers=headers1)

    assert len(client.get("/track/", headers=headers1).json()) == 1
    assert len(client.get("/track/", headers=headers2).json()) == 0
