from datetime import datetime
from typing import Any

import databases
import sqlalchemy

DATABASE_URL = "sqlite:///./avix_server.db"

database = databases.Database(DATABASE_URL)
metadata = sqlalchemy.MetaData()

messages = sqlalchemy.Table(
    "messages",
    metadata,
    sqlalchemy.Column("id", sqlalchemy.Integer, primary_key=True, autoincrement=True),
    sqlalchemy.Column("chat_id", sqlalchemy.String, nullable=False, index=True),
    sqlalchemy.Column("sender_public_key", sqlalchemy.String, nullable=False, index=True),
    sqlalchemy.Column("text", sqlalchemy.Text, nullable=False),
    sqlalchemy.Column("timestamp", sqlalchemy.DateTime, nullable=False, index=True),
    sqlalchemy.Column("is_secret", sqlalchemy.Boolean, nullable=False, default=False),
)

engine = sqlalchemy.create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False},
)


def init_db() -> None:
    metadata.create_all(engine)


async def save_message(
    chat_id: str,
    sender_public_key: str,
    text: str,
    timestamp: datetime,
    is_secret: bool,
) -> dict[str, Any]:
    query = messages.insert().values(
        chat_id=chat_id,
        sender_public_key=sender_public_key,
        text=text,
        timestamp=timestamp,
        is_secret=is_secret,
    )
    message_id = await database.execute(query)

    return {
        "id": message_id,
        "chatId": chat_id,
        "senderPublicKey": sender_public_key,
        "text": text,
        "timestamp": timestamp,
        "isSecret": is_secret,
    }


async def get_messages_for_chat(
    chat_id: str,
    limit: int = 50,
    offset: int = 0,
    before_timestamp: datetime | None = None,
) -> list[dict[str, Any]]:
    query = messages.select().where(messages.c.chat_id == chat_id)

    if before_timestamp is not None:
        query = query.where(messages.c.timestamp < before_timestamp)

    query = query.order_by(messages.c.timestamp.asc()).limit(limit).offset(offset)
    rows = await database.fetch_all(query)

    return [
        {
            "id": row["id"],
            "chatId": row["chat_id"],
            "senderPublicKey": row["sender_public_key"],
            "text": row["text"],
            "timestamp": row["timestamp"],
            "isSecret": row["is_secret"],
        }
        for row in rows
    ]
