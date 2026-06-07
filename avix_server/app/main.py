from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.models import Message, User, VerificationCode
from app.routers import auth, messages
from app.schemas import (
    EmailRequest,
    MessageOut,
    MessageSend,
    TokenResponse,
    UserInfo,
    UserPublic,
    UserSearchResponse,
    VerifyRequest,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="Avix Server",
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

app.include_router(auth.router)
app.include_router(messages.router)
app.include_router(messages.contacts_router)


@app.get("/ping")
def ping() -> dict[str, str]:
    return {"status": "ok"}


__all__ = [
    "app",
    "auth",
    "messages",
    "Message",
    "MessageOut",
    "MessageSend",
    "EmailRequest",
    "TokenResponse",
    "User",
    "UserInfo",
    "UserPublic",
    "UserSearchResponse",
    "VerificationCode",
    "VerifyRequest",
]
