from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import Depends, Header, HTTPException, status
import jwt
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models.user import User


def create_access_token(
    user_id: int,
    nickname: str,
    public_key: str,
    expires_delta: timedelta = timedelta(days=7),
) -> str:
    expire = datetime.now(timezone.utc) + expires_delta
    payload = {
        "user_id": user_id,
        "nickname": nickname,
        "public_key": public_key,
        "exp": expire,
    }

    return jwt.encode(
        payload,
        settings.JWT_SECRET,
        algorithm=settings.JWT_ALGORITHM,
    )


def decode_token(token: str) -> dict[str, Any]:
    return jwt.decode(
        token,
        settings.JWT_SECRET,
        algorithms=[settings.JWT_ALGORITHM],
    )


def get_current_user_from_token(
    token: str = Header(..., alias="Authorization"),
    db: Session = Depends(get_db),
) -> User:
    try:
        if token.lower().startswith("bearer "):
            token = token[7:].strip()

        payload = decode_token(token)
        user_id = payload.get("user_id")

        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token",
            )

        user = db.query(User).filter(User.id == user_id).first()

        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found",
            )

        return user
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        ) from None
