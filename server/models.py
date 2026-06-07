from datetime import datetime

from pydantic import BaseModel, Field


class MessageCreate(BaseModel):
    chatId: str = Field(..., min_length=1)
    senderPublicKey: str = Field(..., min_length=1)
    text: str = Field(..., min_length=1)
    timestamp: datetime
    isSecret: bool = False


class MessageOut(BaseModel):
    id: int
    chatId: str
    senderPublicKey: str
    text: str
    timestamp: datetime
    isSecret: bool
