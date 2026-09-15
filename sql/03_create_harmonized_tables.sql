-- Harmonized tables convert source text into analytics-ready PostgreSQL types.
-- Source values remain available in the raw schema.

CREATE TABLE IF NOT EXISTS harmonized.teams (
    team_id TEXT PRIMARY KEY,
    full_name TEXT,
    abbreviation TEXT,
    nickname TEXT,
    city TEXT,
    state TEXT,
    year_founded INTEGER,
    source_table TEXT NOT NULL DEFAULT 'raw.teams',
    transformed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS harmonized.players (
    player_id TEXT PRIMARY KEY,
    full_name TEXT,
    first_name TEXT,
    last_name TEXT,
    is_active BOOLEAN,
    source_table TEXT NOT NULL DEFAULT 'raw.players',
    transformed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS harmonized.games (
    game_id TEXT PRIMARY KEY,
    season_id TEXT,
    game_date DATE,
    season_type TEXT,
    home_team_id TEXT,
    home_team_abbreviation TEXT,
    home_team_name TEXT,
    home_matchup TEXT,
    home_result CHAR(1),
    away_team_id TEXT,
    away_team_abbreviation TEXT,
    away_team_name TEXT,
    away_matchup TEXT,
    away_result CHAR(1),
    home_points NUMERIC(6, 1),
    away_points NUMERIC(6, 1),
    point_differential NUMERIC(6, 1),
    source_table TEXT NOT NULL DEFAULT 'raw.games',
    transformed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS harmonized.game_summary (
    game_id TEXT PRIMARY KEY,
    game_date DATE,
    game_sequence INTEGER,
    game_status_id INTEGER,
    game_status_text TEXT,
    gamecode TEXT,
    home_team_id TEXT,
    visitor_team_id TEXT,
    season TEXT,
    live_period INTEGER,
    live_pc_time TEXT,
    broadcaster TEXT,
    live_period_time_bcast TEXT,
    wh_status INTEGER,
    source_table TEXT NOT NULL DEFAULT 'raw.game_summary',
    transformed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS harmonized.line_scores (
    game_id TEXT PRIMARY KEY,
    game_date DATE,
    game_sequence INTEGER,
    home_team_id TEXT,
    home_team_abbreviation TEXT,
    home_team_city TEXT,
    home_team_nickname TEXT,
    home_wins_losses TEXT,
    home_q1 NUMERIC(6, 1),
    home_q2 NUMERIC(6, 1),
    home_q3 NUMERIC(6, 1),
    home_q4 NUMERIC(6, 1),
    home_ot1 NUMERIC(6, 1),
    home_ot2 NUMERIC(6, 1),
    home_ot3 NUMERIC(6, 1),
    home_ot4 NUMERIC(6, 1),
    home_ot5 NUMERIC(6, 1),
    home_ot6 NUMERIC(6, 1),
    home_ot7 NUMERIC(6, 1),
    home_ot8 NUMERIC(6, 1),
    home_ot9 NUMERIC(6, 1),
    home_ot10 NUMERIC(6, 1),
    home_points NUMERIC(6, 1),
    away_team_id TEXT,
    away_team_abbreviation TEXT,
    away_team_city TEXT,
    away_team_nickname TEXT,
    away_wins_losses TEXT,
    away_q1 NUMERIC(6, 1),
    away_q2 NUMERIC(6, 1),
    away_q3 NUMERIC(6, 1),
    away_q4 NUMERIC(6, 1),
    away_ot1 NUMERIC(6, 1),
    away_ot2 NUMERIC(6, 1),
    away_ot3 NUMERIC(6, 1),
    away_ot4 NUMERIC(6, 1),
    away_ot5 NUMERIC(6, 1),
    away_ot6 NUMERIC(6, 1),
    away_ot7 NUMERIC(6, 1),
    away_ot8 NUMERIC(6, 1),
    away_ot9 NUMERIC(6, 1),
    away_ot10 NUMERIC(6, 1),
    away_points NUMERIC(6, 1),
    source_table TEXT NOT NULL DEFAULT 'raw.line_scores',
    transformed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS ix_harmonized_games_date
    ON harmonized.games (game_date);
CREATE INDEX IF NOT EXISTS ix_harmonized_games_home_team
    ON harmonized.games (home_team_id);
CREATE INDEX IF NOT EXISTS ix_harmonized_games_away_team
    ON harmonized.games (away_team_id);
CREATE INDEX IF NOT EXISTS ix_harmonized_games_season
    ON harmonized.games (season_id);
CREATE INDEX IF NOT EXISTS ix_harmonized_line_scores_date
    ON harmonized.line_scores (game_date);