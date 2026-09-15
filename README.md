# NBA Analytics

Docker-first NBA analytics project based on the Kaggle NBA Database by Wyatt Walsh.

Dataset: https://www.kaggle.com/datasets/wyattowalsh/basketball
License: CC BY-SA 4.0

## Current setup

The project currently provides:

- PostgreSQL 16 in Docker
- Python 3.12 and Streamlit in Docker
- SQLAlchemy database connectivity
- Project schemas: `raw`, `harmonized`, `analytics`, and `automation`
- Persistent PostgreSQL storage

## Start the environment

1. Copy `.env.example` to `.env` and change the database password.
2. Build and start the services:

```powershell
docker compose up --build -d
```

3. Open http://localhost:8501.
4. Check the logs if needed:

```powershell
docker compose logs -f nba_app
```

## Stop the environment

```powershell
docker compose down
```

The database volume is kept when containers stop. To remove the database volume too:

```powershell
docker compose down -v
```

## Data location

Place the downloaded Kaggle files in `data/kaggle/`. The source dataset is large, so the first analysis will use selected tables rather than importing every cataloged table into PostgreSQL.

## Download the Kaggle database

Create a Kaggle API token from your Kaggle account settings. Add the token to your local `.env` file:

```text
KAGGLE_API_TOKEN=your_token_here
```

Do not commit `.env` or share the token. It is excluded by `.gitignore`.

Rebuild the application image to install `kagglehub`:

```powershell
docker compose build nba_app
```

Download the dataset from inside the application container:

```powershell
docker compose run --rm nba_app python src/download_dataset.py
```

The download can be several gigabytes and may take time. The files are stored under `data/kaggle/.cache/`, which is mounted from your computer and persists after the container exits.

When running Streamlit directly on Windows, use the Docker PostgreSQL port `55432`. Inside Docker, the application continues to use the service name `postgres` and port `5432`.

## Run the analytics layer

After ingestion and harmonization, apply the analytics views:

```powershell
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U nba_user -d nba_analytics -f /docker-entrypoint-initdb.d/05_create_analytics_views.sql
```

The dashboard uses the views in the `analytics` schema and is available at http://localhost:8501.
