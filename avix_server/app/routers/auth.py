from datetime import datetime, timedelta, timezone
import secrets

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.verification_code import VerificationCode
from app.schemas.auth import EmailRequest, TokenResponse, UserInfo, VerifyRequest
from app.utils.email_utils import send_verification_code
from app.utils.jwt_utils import create_access_token, get_current_user_from_token

router = APIRouter(prefix="/auth", tags=["auth"])


def _utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _generate_code() -> str:
    return "".join(secrets.choice("0123456789") for _ in range(6))


def _extract_bearer_token(authorization: str | None) -> str:
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authorization header",
        )

    scheme, _, token = authorization.partition(" ")

    if scheme.lower() != "bearer" or not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header",
        )

    return token


@router.post("/register/email")
def request_registration_code(
    request: EmailRequest,
    db: Session = Depends(get_db),
) -> dict[str, str]:
    email = str(request.email).lower()
    code = _generate_code()
    expires_at = _utc_now() + timedelta(minutes=10)

    verification_code = (
        db.query(VerificationCode)
        .filter(VerificationCode.email == email)
        .first()
    )

    if verification_code is None:
        verification_code = VerificationCode(
            email=email,
            code=code,
            expires_at=expires_at,
        )
        db.add(verification_code)
    else:
        verification_code.code = code
        verification_code.expires_at = expires_at

    db.commit()
    send_verification_code(email, code)

    return {"message": "Verification code sent to email"}


@router.post("/register/verify", response_model=TokenResponse)
def verify_registration_code(
    request: VerifyRequest,
    db: Session = Depends(get_db),
) -> TokenResponse:
    email = str(request.email).lower()
    now = _utc_now()

    verification_code = (
        db.query(VerificationCode)
        .filter(
            VerificationCode.email == email,
            VerificationCode.code == request.code,
        )
        .first()
    )

    if verification_code is None or verification_code.expires_at <= now:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired code",
        )

    existing_user = db.query(User).filter(User.email == email).first()

    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    existing_nickname = (
        db.query(User)
        .filter(User.nickname == request.nickname)
        .first()
    )

    if existing_nickname is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nickname already taken",
        )

    user = User(
        email=email,
        nickname=request.nickname,
        public_key=request.publicKey,
    )

    db.add(user)
    db.delete(verification_code)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email or nickname already registered",
        ) from None

    db.refresh(user)

    token = create_access_token(
        user_id=user.id,
        nickname=user.nickname,
        public_key=user.public_key,
    )

    return TokenResponse(access_token=token)


@router.get("/me", response_model=UserInfo)
def get_me(
    authorization: str | None = Header(default=None, alias="Authorization"),
    db: Session = Depends(get_db),
) -> UserInfo:
    token = _extract_bearer_token(authorization)
    user = get_current_user_from_token(token, db)

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

    return UserInfo(
        id=user.id,
        email=user.email,
        nickname=user.nickname,
        public_key=user.public_key,
    )
