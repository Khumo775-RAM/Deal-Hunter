"""Gmail SMTP email service.

Credentials are read from environment variables (loaded from .env):
  GMAIL_SENDER   – the Gmail address that sends notifications
  GMAIL_APP_PASS – the 16-character App Password generated in Google Account settings
"""

import os
import smtplib
import ssl
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from dotenv import load_dotenv

load_dotenv()

GMAIL_SENDER   = os.getenv("GMAIL_SENDER", "")
GMAIL_APP_PASS = os.getenv("GMAIL_APP_PASS", "")

_CONFIGURED = bool(GMAIL_SENDER and GMAIL_APP_PASS)


def is_configured() -> bool:
    return _CONFIGURED


def send_deal_alert(
    recipient_email: str,
    recipient_name: str,
    alerts: list[dict],
) -> bool:
    """
    Send a deal-alert email to a user.

    Each item in `alerts` should be:
      {title, store, sale_price, normal_price, discount, currency_symbol}

    Returns True on success, False on failure.
    """
    if not _CONFIGURED:
        print("[Email] Not configured — set GMAIL_SENDER and GMAIL_APP_PASS in .env")
        return False

    subject = (
        f"🎮 {len(alerts)} game deal{'s' if len(alerts) != 1 else ''} "
        f"on your watchlist!"
    )

    html = _build_html(recipient_name, alerts)
    plain = _build_plain(alerts)

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"]    = f"DealHunter <{GMAIL_SENDER}>"
    msg["To"]      = recipient_email

    msg.attach(MIMEText(plain, "plain"))
    msg.attach(MIMEText(html, "html"))

    try:
        ctx = ssl.create_default_context()
        with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=ctx) as server:
            server.login(GMAIL_SENDER, GMAIL_APP_PASS)
            server.sendmail(GMAIL_SENDER, recipient_email, msg.as_string())
        print(f"[Email] Sent deal alert to {recipient_email} ({len(alerts)} game(s))")
        return True
    except smtplib.SMTPAuthenticationError:
        print("[Email] Authentication failed — check GMAIL_SENDER and GMAIL_APP_PASS in .env")
    except Exception as e:
        print(f"[Email] Failed to send to {recipient_email}: {e}")
    return False


def send_verification_email(recipient_email: str, username: str, code: str) -> bool:
    """Send a 6-digit verification code to a newly registered user."""
    if not _CONFIGURED:
        print(f"[Email] Not configured — verification code for {username}: {code}")
        return False

    subject = "DealHunter — Verify your email address"
    html = f"""<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#0f0f1a;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0"
         style="max-width:480px;margin:40px auto;background:#1a1a2e;
                border-radius:16px;overflow:hidden;">
    <tr>
      <td style="background:linear-gradient(135deg,#6c63ff,#9b97c5);
                 padding:28px 24px;text-align:center;">
        <h1 style="margin:0;color:#fff;font-size:24px;">🎮 DealHunter</h1>
        <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:14px;">
          Verify your email to get started
        </p>
      </td>
    </tr>
    <tr>
      <td style="padding:32px 24px;text-align:center;">
        <p style="color:#fff;font-size:15px;margin:0 0 24px;">
          Hi <strong>{username}</strong>, enter this code in the app to verify
          your account:
        </p>
        <div style="display:inline-block;background:#0f0f1a;
                    border:2px solid #6c63ff;border-radius:12px;
                    padding:16px 40px;">
          <span style="color:#6c63ff;font-size:36px;font-weight:bold;
                       letter-spacing:8px;">{code}</span>
        </div>
        <p style="color:rgba(255,255,255,0.4);font-size:12px;margin:24px 0 0;">
          This code expires in <strong style="color:rgba(255,255,255,0.6);">
          15 minutes</strong>. If you didn't create a DealHunter account,
          you can safely ignore this email.
        </p>
      </td>
    </tr>
  </table>
</body>
</html>"""
    plain = (
        f"DealHunter — Email Verification\n\n"
        f"Hi {username},\n\n"
        f"Your verification code is: {code}\n\n"
        f"It expires in 15 minutes.\n"
        f"If you didn't register, ignore this email."
    )

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"]    = f"DealHunter <{GMAIL_SENDER}>"
    msg["To"]      = recipient_email
    msg.attach(MIMEText(plain, "plain"))
    msg.attach(MIMEText(html,  "html"))

    try:
        ctx = ssl.create_default_context()
        with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=ctx) as server:
            server.login(GMAIL_SENDER, GMAIL_APP_PASS)
            server.sendmail(GMAIL_SENDER, recipient_email, msg.as_string())
        print(f"[Email] Verification code sent to {recipient_email}")
        return True
    except Exception as e:
        print(f"[Email] Failed to send verification to {recipient_email}: {e}")
        return False


def send_password_reset_email(recipient_email: str, username: str, code: str) -> bool:
    """Send a password reset code to the user."""
    if not _CONFIGURED:
        print(f"[Email] Not configured — reset code for {username}: {code}")
        return False

    subject = "DealHunter — Reset your password"
    html = f"""<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#0f0f1a;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0"
         style="max-width:480px;margin:40px auto;background:#1a1a2e;
                border-radius:16px;overflow:hidden;">
    <tr>
      <td style="background:linear-gradient(135deg,#6c63ff,#9b97c5);
                 padding:28px 24px;text-align:center;">
        <h1 style="margin:0;color:#fff;font-size:24px;">🎮 DealHunter</h1>
        <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:14px;">
          Password reset request
        </p>
      </td>
    </tr>
    <tr>
      <td style="padding:32px 24px;text-align:center;">
        <p style="color:#fff;font-size:15px;margin:0 0 24px;">
          Hi <strong>{username}</strong>, use this code to reset your password:
        </p>
        <div style="display:inline-block;background:#0f0f1a;
                    border:2px solid #6c63ff;border-radius:12px;
                    padding:16px 40px;">
          <span style="color:#6c63ff;font-size:36px;font-weight:bold;
                       letter-spacing:8px;">{code}</span>
        </div>
        <p style="color:rgba(255,255,255,0.4);font-size:12px;margin:24px 0 0;">
          This code expires in <strong style="color:rgba(255,255,255,0.6);">
          15 minutes</strong>.<br>
          If you didn't request a password reset, you can safely ignore this email.
        </p>
      </td>
    </tr>
  </table>
</body>
</html>"""
    plain = (
        f"DealHunter — Password Reset\n\n"
        f"Hi {username},\n\n"
        f"Your password reset code is: {code}\n\n"
        f"It expires in 15 minutes.\n"
        f"If you didn't request this, ignore this email."
    )

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"]    = f"DealHunter <{GMAIL_SENDER}>"
    msg["To"]      = recipient_email
    msg.attach(MIMEText(plain, "plain"))
    msg.attach(MIMEText(html,  "html"))

    try:
        ctx = ssl.create_default_context()
        with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=ctx) as server:
            server.login(GMAIL_SENDER, GMAIL_APP_PASS)
            server.sendmail(GMAIL_SENDER, recipient_email, msg.as_string())
        print(f"[Email] Password reset code sent to {recipient_email}")
        return True
    except Exception as e:
        print(f"[Email] Failed to send reset to {recipient_email}: {e}")
        return False


# ── HTML + plain-text builders ────────────────────────────────────────────────

def _build_html(name: str, alerts: list[dict]) -> str:
    rows = ""
    for a in alerts:
        sym      = a.get("currency_symbol", "$")
        sale     = f"{sym}{a['sale_price']:.2f}"
        normal   = f"{sym}{a['normal_price']:.2f}"
        discount = f"{a['discount']:.0f}%"
        rows += f"""
        <tr>
          <td style="padding:12px 16px;border-bottom:1px solid #2a2a40;">
            <strong style="color:#ffffff;font-size:15px;">{a['title']}</strong><br>
            <span style="color:#9b97c5;font-size:12px;">{a['store']}</span>
          </td>
          <td style="padding:12px 16px;border-bottom:1px solid #2a2a40;text-align:center;">
            <span style="color:#4CAF50;font-size:18px;font-weight:bold;">{sale}</span><br>
            <span style="color:#666;font-size:12px;text-decoration:line-through;">{normal}</span>
          </td>
          <td style="padding:12px 16px;border-bottom:1px solid #2a2a40;text-align:center;">
            <span style="background:#c0392b;color:#fff;padding:4px 10px;
                         border-radius:6px;font-weight:bold;font-size:13px;">
              -{discount}
            </span>
          </td>
        </tr>"""

    return f"""<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#0f0f1a;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0"
         style="max-width:600px;margin:32px auto;background:#1a1a2e;
                border-radius:16px;overflow:hidden;">
    <!-- Header -->
    <tr>
      <td colspan="3"
          style="background:linear-gradient(135deg,#6c63ff,#9b97c5);
                 padding:28px 24px;text-align:center;">
        <h1 style="margin:0;color:#fff;font-size:24px;letter-spacing:1px;">
          🎮 DealHunter
        </h1>
        <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:14px;">
          Hi {name}, games on your watchlist are on sale!
        </p>
      </td>
    </tr>
    <!-- Column headers -->
    <tr style="background:#12122a;">
      <td style="padding:10px 16px;color:#6c63ff;font-size:11px;
                 font-weight:bold;letter-spacing:1px;text-transform:uppercase;">
        Game
      </td>
      <td style="padding:10px 16px;color:#6c63ff;font-size:11px;
                 font-weight:bold;letter-spacing:1px;text-transform:uppercase;
                 text-align:center;">
        Price
      </td>
      <td style="padding:10px 16px;color:#6c63ff;font-size:11px;
                 font-weight:bold;letter-spacing:1px;text-transform:uppercase;
                 text-align:center;">
        Discount
      </td>
    </tr>
    {rows}
    <!-- Footer -->
    <tr>
      <td colspan="3"
          style="padding:20px 24px;text-align:center;
                 color:rgba(255,255,255,0.3);font-size:11px;">
        You're receiving this because you enabled deal notifications in DealHunter.<br>
        Open the app and go to Settings → Notifications to turn them off.
      </td>
    </tr>
  </table>
</body>
</html>"""


def _build_plain(alerts: list[dict]) -> str:
    lines = ["DealHunter — Games on your watchlist are on sale!\n"]
    for a in alerts:
        sym = a.get("currency_symbol", "$")
        lines.append(
            f"• {a['title']} — {sym}{a['sale_price']:.2f} "
            f"(was {sym}{a['normal_price']:.2f}, -{a['discount']:.0f}%) "
            f"at {a['store']}"
        )
    lines.append("\nOpen DealHunter to see full details.")
    return "\n".join(lines)
