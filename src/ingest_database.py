"""Load the selected NBA SQLite tables into PostgreSQL raw tables."""

from pathlib import Path
import logging
import sqlite3

import pandas as pd
from sqlalchemy import text

from db_connection import get_engine


PROJECT_ROOT = Path(__file__).resolve().parent.parent
SOURCE_DATABASE = PROJECT_ROOT / "data" / "kaggle" / ".cache" / "nba.sqlite"
CHUNK_SIZE = 5_000

TABLES = {
    "game": "games",
    "player": "players",
    "team": "teams",
    "game_summary": "game_summary",
    "line_score": "line_scores",
}

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)
logger = logging.getLogger(__name__)


def source_row_count(connection: sqlite3.Connection, table_name: str) -> int:
    return connection.execute(f"SELECT COUNT(*) FROM [{table_name}]").fetchone()[0]


def load_table(
    source_connection: sqlite3.Connection,
    target_connection,
    source_table: str,
    target_table: str,
) -> int:
    query = f"SELECT * FROM [{source_table}]"
    expected_rows = source_row_count(source_connection, source_table)
    loaded_rows = 0

    target_connection.execute(text(f"TRUNCATE TABLE raw.{target_table}"))

    for chunk in pd.read_sql_query(query, source_connection, chunksize=CHUNK_SIZE):
        chunk.to_sql(
            target_table,
            target_connection,
            schema="raw",
            if_exists="append",
            index=False,
            method="multi",
        )
        loaded_rows += len(chunk)
        logger.info(
            "Loaded %s rows into raw.%s (%s/%s)",
            loaded_rows,
            target_table,
            loaded_rows,
            expected_rows,
        )

    if loaded_rows != expected_rows:
        raise RuntimeError(
            f"Row-count mismatch for {source_table}: "
            f"source={expected_rows}, loaded={loaded_rows}"
        )

    return loaded_rows


def run_ingestion() -> None:
    if not SOURCE_DATABASE.exists():
        raise FileNotFoundError(f"Source database not found: {SOURCE_DATABASE}")

    engine = get_engine()
    with sqlite3.connect(SOURCE_DATABASE) as source_connection:
        with engine.begin() as target_connection:
            for source_table, target_table in TABLES.items():
                logger.info("Starting %s -> raw.%s", source_table, target_table)
                load_table(
                    source_connection,
                    target_connection,
                    source_table,
                    target_table,
                )

    logger.info("NBA raw ingestion completed successfully.")


if __name__ == "__main__":
    run_ingestion()