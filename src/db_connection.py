import os

from dotenv import load_dotenv
from sqlalchemy import create_engine

load_dotenv()


def get_engine():
    """Create a SQLAlchemy engine using Docker Compose environment values."""
    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "5433")
    database = os.getenv("DB_NAME", "nba_analytics")
    user = os.getenv("DB_USER", "nba_user")
    password = os.getenv("DB_PASSWORD", "nba_password")

    return create_engine(
        f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database}"
    )
