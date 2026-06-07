from datetime import datetime

from pydantic import BaseModel


class MessageSend(BaseModel):
    to_nickname_or_publicKey: str
    text: str
    is_secret: bool = False


class MessageOut(BaseModel):
    id: int
    from_user_id: int
    from_nickname: str
    text: str
    is_secret: bool
    created_at: datetime
    delivered: bool
