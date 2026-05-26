from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel

from models.user import UserRegister, UserPublic, TokenResponse
from services import auth_service
from services.email_service import send_verification_email, send_password_reset_email

router = APIRouter(prefix="/auth", tags=["Authentication"])


class NotificationToggle(BaseModel):
    enabled: bool


class ForgotPasswordRequest(BaseModel):
    email: str


class ResetPasswordRequest(BaseModel):
    email: str
    code: str
    new_password: str


class VerifyEmailRequest(BaseModel):
    username: str
    code: str


class ResendRequest(BaseModel):
    username: str


@router.post("/register", response_model=UserPublic, status_code=201)
def register(user: UserRegister):
    """Create a new unverified account and send a verification code."""
    try:
        pub, code = auth_service.create_user(
            username=user.username,
            email=user.email,
            password=user.password,
        )
        send_verification_email(pub.email, pub.username, code)
        return pub
    except ValueError as e:
        raise HTTPException(status_code=409, detail=str(e))


@router.post("/verify-email", response_model=UserPublic)
def verify_email(body: VerifyEmailRequest):
    """Verify the 6-digit code sent to the user's email."""
    try:
        return auth_service.verify_email_code(body.username, body.code)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/resend-verification", status_code=200)
def resend_verification(body: ResendRequest):
    """Generate and re-send a fresh verification code."""
    try:
        code = auth_service.resend_verification_code(body.username)
        user = auth_service.get_user_by_username(body.username)
        if user:
            send_verification_email(user.email, user.username, code)
        return {"message": "Verification code resent."}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/login", response_model=TokenResponse)
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    """Log in and receive a JWT access token."""
    user = auth_service.authenticate_user(form_data.username, form_data.password)
    token = auth_service.create_access_token(user.username)
    return TokenResponse(access_token=token)


@router.get("/me", response_model=UserPublic)
def me(current_user: UserPublic = Depends(auth_service.get_current_user)):
    """Return the currently logged-in user's details."""
    return current_user


@router.post("/logout")
def logout(token: str = Depends(auth_service.oauth2_scheme)):
    """Log out by invalidating the current JWT token."""
    auth_service.blacklist_token(token)
    return {"message": "Successfully logged out."}


@router.delete("/account", status_code=200)
def delete_account(
    token: str = Depends(auth_service.oauth2_scheme),
    current_user: UserPublic = Depends(auth_service.get_current_user),
):
    """Permanently delete the logged-in user's account and all their data."""
    auth_service.blacklist_token(token)
    auth_service.delete_user(current_user.username)
    return {"message": "Account deleted."}


@router.post("/forgot-password", status_code=200)
def forgot_password(body: ForgotPasswordRequest):
    """Send a 6-digit reset code to the given email address."""
    try:
        username, code = auth_service.request_password_reset(body.email)
        send_password_reset_email(body.email, username, code)
        # Always return the same message to avoid email enumeration.
        return {"message": "If that email is registered, a reset code has been sent."}
    except ValueError:
        return {"message": "If that email is registered, a reset code has been sent."}


@router.post("/reset-password", status_code=200)
def reset_password(body: ResetPasswordRequest):
    """Verify the reset code and set a new password."""
    try:
        auth_service.reset_password(body.email, body.code, body.new_password)
        return {"message": "Password reset successfully."}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.patch("/notifications", response_model=UserPublic)
def set_notifications(
    body: NotificationToggle,
    current_user: UserPublic = Depends(auth_service.get_current_user),
):
    """Enable or disable email deal notifications for the logged-in user."""
    try:
        return auth_service.update_notification_preference(
            current_user.username, body.enabled
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
