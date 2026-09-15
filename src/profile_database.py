from pathlib import Path
import sqlite3


DATABASE_PATH = Path("data/kaggle/.cache/nba.sqlite")


def get_tables(connection: sqlite3.Connection) -> list[str]:
    rows = connection.execute(
        """
        SELECT name
        FROM sqlite_master
        WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
        ORDER BY name
        """
    ).fetchall()
    return [row[0] for row in rows]


def profile_table(connection: sqlite3.Connection, table_name: str) -> tuple[int, int]:
    columns = connection.execute(
        f"PRAGMA table_info([{table_name}])"
    ).fetchall()
    row_count = connection.execute(
        f"SELECT COUNT(*) FROM [{table_name}]"
    ).fetchone()[0]
    return len(columns), row_count


def main() -> None:
    if not DATABASE_PATH.exists():
        raise FileNotFoundError(f"Database not found: {DATABASE_PATH}")

    with sqlite3.connect(DATABASE_PATH) as connection:
        tables = get_tables(connection)
        print(f"Database: {DATABASE_PATH}")
        print(f"Table count: {len(tables)}")
        print("\nTable inventory:")
        for table_name in tables:
            column_count, row_count = profile_table(connection, table_name)
            print(f"- {table_name}: {row_count:,} rows, {column_count} columns")


if __name__ == "__main__":
    main()
