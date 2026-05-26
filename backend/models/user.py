from pydantic import BaseModel, EmailStr, field_validator


class UserRegister(BaseModel):
    username: str
    email: EmailStr
    password: str

    @field_validator("username")
    @classmethod
    def username_min_length(cls, v: str) -> str:
        if len(v.strip()) < 3:
            raise ValueError("Username must be at least 3 characters.")
        return v.strip()

    @field_validator("password")
    @classmethod
    def password_min_length(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters.")
        return v


class UserLogin(BaseModel):
    username: str
    password: str


class UserPublic(BaseModel):
    username: str
    email: str
    email_notifications: bool = False
    is_verified: bool = False


class UserInDB(BaseModel):
    username: str
    email: str
    hashed_password: str
    email_notifications: bool = False
    is_verified: bool = False
    verification_code: str | None = None
    verification_expires: str | None = None
    reset_code: str | None = None
    reset_expires: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
