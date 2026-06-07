from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.message import Message
from app.models.user import User
from app.schemas.message import MessageOut, MessageSend
from app.schemas.user import UserPublic, UserSearchResponse
from app.utils.jwt_utils import get_current_user_from_token as get_current_user

router = APIRouter(prefix="/messages", tags=["messages"])
contacts_router = APIRouter(prefix="/contacts", tags=["contacts"])


def _find_user_by_nickname_or_key(
    db: Session,
    nickname_or_public_key: str,
) -> User | None:
    user = db.query(User).filter(User.nickname == nickname_or_public_key).first()

    if user is not None:
        return user

    return db.query(User).filter(User.public_key == nickname_or_public_key).first()


@router.post("/send")
def send_message(
    message: MessageSend,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, int | str]:
    recipient = _find_user_by_nickname_or_key(
        db,
        message.to_nickname_or_publicKey,
    )

    if recipient is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    db_message = Message(
        from_user_id=current_user.id,
        to_user_id=recipient.id,
        text=message.text,
        is_secret=message.is_secret,
        created_at=datetime.utcnow(),
        delivered=False,
    )

    db.add(db_message)
    db.commit()
    db.refresh(db_message)

    return {
        "message_id": db_message.id,
        "created_at": db_message.created_at.isoformat(),
    }


@router.get("/unread", response_model=list[MessageOut])
def get_unread_messages(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[MessageOut]:
    rows = (
        db.query(Message, User.nickname)
        .join(User, User.id == Message.from_user_id)
        .filter(
            Message.to_user_id == current_user.id,
            Message.delivered.is_(False),
        )
        .order_by(Message.created_at.asc())
        .all()
    )

    result = [
        MessageOut(
            id=message.id,
            from_user_id=message.from_user_id,
            from_nickname=from_nickname,
            text=message.text,
            is_secret=message.is_secret,
            created_at=message.created_at,
            delivered=message.delivered,
        )
        for message, from_nickname in rows
    ]

    message_ids = [message.id for message, _ in rows]

    if message_ids:
        (
            db.query(Message)
            .filter(Message.id.in_(message_ids))
            .update({"delivered": True}, synchronize_session=False)
        )
        db.commit()

    return result


@contacts_router.get("/search", response_model=UserSearchResponse)
def search_contacts(
    q: str = Query(..., min_length=1),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> UserSearchResponse:
    query = q.strip()

    if not query:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Search query cannot be empty",
        )

    users = (
        db.query(User)
        .filter(
            User.id != current_user.id,
            or_(
                User.nickname.ilike(f"%{query}%"),
                User.public_key.ilike(f"%{query}%"),
            ),
        )
        .limit(10)
        .all()
    )

    return UserSearchResponse(
        results=[
            UserPublic(
                nickname=user.nickname,
                public_key=user.public_key,
            )
            for user in users
        ]
    )
