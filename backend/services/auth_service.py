import json
import os
import random
import string
from datetime import datetime, timedelta, timezone

import bcrypt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt

from models.user import UserInDB, UserPublic

SECRET_KEY = "changeme-use-a-long-random-secret-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

USERS_FILE = os.path.join(os.path.dirname(__file__), "..", "data", "users.json")
BLACKLIST_FILE = os.path.join(os.path.dirname(__file__), "..", "data", "blacklisted_tokens.json")

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


# ── User storage ────────────────────────────────────────────────────────────

def _load_users() -> list[dict]:
    if not os.path.exists(USERS_FILE):
        return []
    with open(USERS_FILE, "r", encoding="utf-8") as f:
        try:
            return json.load(f)
        except json.JSONDecodeError:
            return []


def _save_users(users: list[dict]) -> None:
    with open(USERS_FILE, "w", encoding="utf-8") as f:
        json.dump(users, f, indent=2)


def get_user_by_username(username: str) -> UserInDB | None:
    for u in _load_users():
        if u["username"].lower() == username.lower():
            return UserInDB(**{k: v for k, v in u.items() if k in UserInDB.model_fields})
    return None


def get_user_by_email(email: str) -> UserInDB | None:
    for u in _load_users():
        if u["email"].lower() == email.lower():
            return UserInDB(**{k: v for k, v in u.items() if k in UserInDB.model_fields})
    return None


def get_users_with_notifications() -> list[dict]:
    """Return raw user dicts (with email) for users who have notifications enabled."""
    return [u for u in _load_users() if u.get("email_notifications", False)]


def delete_user(username: str) -> None:
    """Permanently delete a user account and all their data."""
    import json as _json

    # Remove from users list
    users = _load_users()
    users = [u for u in users if u["username"].lower() != username.lower()]
    _save_users(users)

    # Remove tracked games
    from services import tracking_service
    tracking_data = tracking_service._load_all()
    tracking_data.pop(username, None)
    tracking_service._save_all(tracking_data)

    # Remove price cache entries
    cache_file = os.path.join(os.path.dirname(__file__), "..", "data", "price_cache.json")
    if os.path.exists(cache_file):
        with open(cache_file, "r", encoding="utf-8") as f:
            try:
                cache = _json.load(f)
            except _json.JSONDecodeError:
                cache = {}
        cache.pop(username, None)
        with open(cache_file, "w", encoding="utf-8") as f:
            _json.dump(cache, f, indent=2)


def update_notification_preference(username: str, enabled: bool) -> UserPublic:
    """Toggle email_notifications for the given user."""
    users = _load_users()
    for u in users:
        if u["username"].lower() == username.lower():
            u["email_notifications"] = enabled
            _save_users(users)
            return UserPublic(
                username=u["username"],
                email=u["email"],
                email_notifications=enabled,
            )
    raise ValueError(f"User '{username}' not found.")


def _generate_code() -> str:
    return "".join(random.choices(string.digits, k=6))


def _code_expiry() -> str:
    return (datetime.now(timezone.utc) + timedelta(minutes=15)).isoformat()


def create_user(username: str, email: str, password: str) -> tuple[UserPublic, str]:
    """Create an unverified user and return (UserPublic, verification_code)."""
    if get_user_by_username(username):
        raise ValueError(f"Username '{username}' is already taken.")
    if get_user_by_email(email):
        raise ValueError(f"An account with that email already exists.")

    from services.email_service import is_configured
    # If email is not configured skip verification so development still works.
    auto_verify = not is_configured()

    code = _generate_code()
    users = _load_users()
    new_user = {
        "username": username,
        "email": email,
        "hashed_password": hash_password(password),
        "is_verified": auto_verify,
        "verification_code": None if auto_verify else code,
        "verification_expires": None if auto_verify else _code_expiry(),
    }
    users.append(new_user)
    _save_users(users)
    pub = UserPublic(username=username, email=email, is_verified=auto_verify)
    return pub, code


def verify_email_code(username: str, code: str) -> UserPublic:
    """Verify the 6-digit code. Raises ValueError on wrong/expired code."""
    users = _load_users()
    for u in users:
        if u["username"].lower() != username.lower():
            continue
        if u.get("is_verified"):
            return UserPublic(
                username=u["username"],
                email=u["email"],
                is_verified=True,
                email_notifications=u.get("email_notifications", False),
            )
        stored = u.get("verification_code")
        expires_str = u.get("verification_expires")
        if stored is None:
            raise ValueError("No verification code was issued for this account.")
        if stored != code:
            raise ValueError("Incorrect verification code. Please try again.")
        if expires_str:
            expires = datetime.fromisoformat(expires_str)
            if datetime.now(timezone.utc) > expires:
                raise ValueError("Verification code has expired. Please request a new one.")
        u["is_verified"] = True
        u["verification_code"] = None
        u["verification_expires"] = None
        _save_users(users)
        return UserPublic(
            username=u["username"],
            email=u["email"],
            is_verified=True,
            email_notifications=u.get("email_notifications", False),
        )
    raise ValueError("User not found.")


def resend_verification_code(username: str) -> str:
    """Generate and store a fresh code. Returns the new code."""
    users = _load_users()
    for u in users:
        if u["username"].lower() != username.lower():
            continue
        if u.get("is_verified"):
            raise ValueError("Account is already verified.")
        code = _generate_code()
        u["verification_code"]    = code
        u["verification_expires"] = _code_expiry()
        _save_users(users)
        return code
    raise ValueError("User not found.")


# ── Password reset ────────────────────────────────────────────────────────────

def request_password_reset(email: str) -> tuple[str, str]:
    """
    Generate a reset code for the account with the given email.
    Returns (username, code). Raises ValueError if email not found.
    """
    users = _load_users()
    for u in users:
        if u["email"].lower() == email.lower():
            code = _generate_code()
            u["reset_code"]    = code
            u["reset_expires"] = _code_expiry()
            _save_users(users)
            return u["username"], code
    raise ValueError("No account found with that email address.")


def reset_password(email: str, code: str, new_password: str) -> None:
    """Verify reset code and update the password. Raises ValueError on failure."""
    if len(new_password) < 6:
        raise ValueError("Password must be at least 6 characters.")
    users = _load_users()
    for u in users:
        if u["email"].lower() != email.lower():
            continue
        stored  = u.get("reset_code")
        expires = u.get("reset_expires")
        if not stored:
            raise ValueError("No reset was requested for this account.")
        if stored != code:
            raise ValueError("Incorrect reset code. Please try again.")
        if expires and datetime.now(timezone.utc) > datetime.fromisoformat(expires):
            raise ValueError("Reset code has expired. Please request a new one.")
        u["hashed_password"] = hash_password(new_password)
        u["reset_code"]      = None
        u["reset_expires"]   = None
        _save_users(users)
        return
    raise ValueError("No account found with that email address.")


# ── Token blacklist ───────────────────────────────────────────────────────────

def _load_blacklist() -> list[str]:
    if not os.path.exists(BLACKLIST_FILE):
        return []
    with open(BLACKLIST_FILE, "r", encoding="utf-8") as f:
        try:
            return json.load(f)
        except json.JSONDecodeError:
            return []


def _save_blacklist(tokens: list[str]) -> None:
    with open(BLACKLIST_FILE, "w", encoding="utf-8") as f:
        json.dump(tokens, f, indent=2)


def blacklist_token(token: str) -> None:
    tokens = _load_blacklist()
    if token not in tokens:
        tokens.append(token)
        _save_blacklist(tokens)


def is_token_blacklisted(token: str) -> bool:
    return token in _load_blacklist()


# ── Password helpers ─────────────────────────────────────────────────────────

def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))


# ── JWT helpers ──────────────────────────────────────────────────────────────

def create_access_token(username: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": username, "exp": expire}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def authenticate_user(username: str, password: str) -> UserInDB:
    user = get_user_by_username(username)
    if not user or not verify_password(password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="EMAIL_NOT_VERIFIED",
        )
    return user


# ── Current user dependency ──────────────────────────────────────────────────

def get_current_user(token: str = Depends(oauth2_scheme)) -> UserPublic:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired token. Please log in again.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if is_token_blacklisted(token):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="You have been logged out. Please log in again.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if not username:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = get_user_by_username(username)
    if not user:
        raise credentials_exception

    return UserPublic(
        username=user.username,
        email=user.email,
        email_notifications=user.email_notifications,
        is_verified=user.is_verified,
    )
