from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas.user import UserPublic, UserSearchResponse
from app.utils.jwt_utils import get_current_user_from_token

router = APIRouter(prefix="/contacts", tags=["contacts"])


@router.get("/search", response_model=UserSearchResponse)
def search_contacts(
    q: str = Query(..., min_length=1),
    current_user: User = Depends(get_current_user_from_token),
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
            User.nickname.ilike(f"%{query}%"),
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
