from datetime import datetime
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware

from database import database, get_messages_for_chat, init_db, save_message
from models import MessageCreate, MessageOut


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    await database.connect()
    try:
        yield
    finally:
        await database.disconnect()


app = FastAPI(
    title="Avix Server",
    description="Simple relay server for regular Avix chats.",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/ping")
async def ping() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/send", response_model=MessageOut)
async def send_message(message: MessageCreate) -> dict:
    return await save_message(
        chat_id=message.chatId,
        sender_public_key=message.senderPublicKey,
        text=message.text,
        timestamp=message.timestamp,
        is_secret=message.isSecret,
    )


@app.get("/messages/{chat_id}", response_model=list[MessageOut])
async def messages_for_chat(
    chat_id: str,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    before_timestamp: datetime | None = Query(default=None),
) -> list[dict]:
    return await get_messages_for_chat(
        chat_id=chat_id,
        limit=limit,
        offset=offset,
        before_timestamp=before_timestamp,
    )


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
