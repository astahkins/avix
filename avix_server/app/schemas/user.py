from typing import List

from pydantic import BaseModel


class UserPublic(BaseModel):
    nickname: str
    public_key: str


class UserSearchResponse(BaseModel):
    results: List[UserPublic]
