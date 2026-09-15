from pathlib import Path
import sqlite3


DATABASE_PATH = Path("data/kaggle/.cache/nba.sqlite")
KEY_TABLES = ["game", "player", "team", "game_summary", "line_score", "play_by_play"]


def table_columns(connection: sqlite3.Connection, table_name: str) -> list[tuple[str, str]]:
    return [
        (row[1], row[2])
        for row in connection.execute(f"PRAGMA table_info([{table_name}])")
    ]


def main() -> None:
    with sqlite3.connect(DATABASE_PATH) as connection:
        for table_name in KEY_TABLES:
            columns = table_columns(connection, table_name)
            row_count = connection.execute(
                f"SELECT COUNT(*) FROM [{table_name}]"
            ).fetchone()[0]
            print(f"\n[{table_name}] rows={row_count:,}")
            print("columns:")
            print(", ".join(f"{name} ({data_type or 'untyped'})" for name, data_type in columns))

            quality = []
            for name, _ in columns:
                quoted_name = f"[{name}]"
                null_count = connection.execute(
                    f"SELECT COUNT(*) FROM [{table_name}] WHERE {quoted_name} IS NULL"
                ).fetchone()[0]
                empty_count = connection.execute(
                    f"SELECT COUNT(*) FROM [{table_name}] WHERE CAST({quoted_name} AS TEXT) = ''"
                ).fetchone()[0]
                if null_count or empty_count:
                    quality.append(
                        f"{name}: nulls={null_count:,} ({null_count / row_count:.1%}), "
                        f"empty={empty_count:,}"
                    )
            print("quality flags:")
            print("; ".join(quality) if quality else "none")

        print("\nDuplicate checks:")
        checks = {
            "player.id": "SELECT id, COUNT(*) FROM player GROUP BY id HAVING COUNT(*) > 1",
            "team.id": "SELECT id, COUNT(*) FROM team GROUP BY id HAVING COUNT(*) > 1",
            "game.game_id": "SELECT game_id, COUNT(*) FROM game GROUP BY game_id HAVING COUNT(*) > 1",
        }
        for label, query in checks.items():
            duplicates = connection.execute(query).fetchall()
            print(f"- {label}: {len(duplicates)} duplicate keys")

        print("\nDate and season coverage:")
        for table_name, date_column in [("game", "game_date"), ("game", "season_id")]:
            result = connection.execute(
                f"SELECT MIN([{date_column}]), MAX([{date_column}]), COUNT(DISTINCT [{date_column}]) FROM [{table_name}]"
            ).fetchone()
            print(f"- {table_name}.{date_column}: min={result[0]}, max={result[1]}, distinct={result[2]:,}")


if __name__ == "__main__":
    main()
