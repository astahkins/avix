import os

from dotenv import load_dotenv

load_dotenv()


class Settings:
    JWT_SECRET: str = os.getenv("JWT_SECRET", "change-this-secret")
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./avix.db")
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")


settings = Settings()
