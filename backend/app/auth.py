"""
Authentication module.

In DEV_MODE (default for hackathon):
  - Pass `X-Dev-User-Id: <user_id>` header to identify the user.
  - No JWT required.

In production:
  - Pass `Authorization: Bearer <supabase_jwt>` header.
  - JWT is verified against SUPABASE_JWT_SECRET.
"""

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from core.config import settings

bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> str:
    """Return the current user's ID (string UUID)."""

    # ── Dev mode: accept X-Dev-User-Id header ──
    if settings.DEV_MODE:
        dev_user_id = request.headers.get("X-Dev-User-Id")
        if dev_user_id:
            return dev_user_id

    # ── Production: verify Supabase JWT ──
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authentication token",
        )

    try:
        from jose import jwt, JWTError

        payload = jwt.decode(
            credentials.credentials,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            audience="authenticated",
        )
        user_id: str | None = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token: no sub claim")
        return user_id
    except ImportError:
        raise HTTPException(
            status_code=500,
            detail="python-jose not installed; cannot verify JWT",
        )
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
