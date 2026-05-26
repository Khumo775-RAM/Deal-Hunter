def test_register_success(client):
    response = client.post("/auth/register", json={
        "username": "newuser",
        "email": "new@example.com",
        "password": "password123",
    })
    assert response.status_code == 201
    data = response.json()
    assert data["username"] == "newuser"
    assert data["email"] == "new@example.com"
    assert "password" not in data
    assert "hashed_password" not in data


def test_register_duplicate_username(client):
    payload = {"username": "dupuser", "email": "dup@example.com", "password": "password123"}
    client.post("/auth/register", json=payload)
    response = client.post("/auth/register", json={**payload, "email": "other@example.com"})
    assert response.status_code == 409


def test_register_duplicate_email(client):
    client.post("/auth/register", json={"username": "user1", "email": "shared@example.com", "password": "password123"})
    response = client.post("/auth/register", json={"username": "user2", "email": "shared@example.com", "password": "password123"})
    assert response.status_code == 409


def test_register_username_too_short(client):
    response = client.post("/auth/register", json={
        "username": "ab",
        "email": "x@example.com",
        "password": "password123",
    })
    assert response.status_code == 422


def test_register_password_too_short(client):
    response = client.post("/auth/register", json={
        "username": "validuser",
        "email": "x@example.com",
        "password": "abc",
    })
    assert response.status_code == 422


def test_register_invalid_email(client):
    response = client.post("/auth/register", json={
        "username": "validuser",
        "email": "notanemail",
        "password": "password123",
    })
    assert response.status_code == 422


def test_login_success(client, registered_user):
    response = client.post("/auth/login", data={
        "username": registered_user["username"],
        "password": registered_user["password"],
    })
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_login_wrong_password(client, registered_user):
    response = client.post("/auth/login", data={
        "username": registered_user["username"],
        "password": "wrongpassword",
    })
    assert response.status_code == 401


def test_login_unknown_user(client):
    response = client.post("/auth/login", data={
        "username": "nobody",
        "password": "password123",
    })
    assert response.status_code == 401


def test_me_returns_user_details(client, registered_user, auth_headers):
    response = client.get("/auth/me", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["username"] == registered_user["username"]


def test_me_without_token_returns_401(client):
    response = client.get("/auth/me")
    assert response.status_code == 401


def test_logout_invalidates_token(client, auth_headers):
    logout = client.post("/auth/logout", headers=auth_headers)
    assert logout.status_code == 200
    me = client.get("/auth/me", headers=auth_headers)
    assert me.status_code == 401
