CREATE OR REPLACE VIEW analytics.team_game_results AS
SELECT
    game_id,
    season_id,
    game_date,
    season_type,
    home_team_id AS team_id,
    home_team_abbreviation AS team_abbreviation,
    home_team_name AS team_name,
    away_team_id AS opponent_id,
    away_team_abbreviation AS opponent_abbreviation,
    away_team_name AS opponent_name,
    'Home' AS location,
    home_result AS result,
    home_points AS points_scored,
    away_points AS points_allowed,
    point_differential,
    home_points + away_points AS combined_points
FROM harmonized.games
WHERE home_team_id IS NOT NULL
UNION ALL
SELECT
    game_id,
    season_id,
    game_date,
    season_type,
    away_team_id,
    away_team_abbreviation,
    away_team_name,
    home_team_id,
    home_team_abbreviation,
    home_team_name,
    'Away',
    away_result,
    away_points,
    home_points,
    -point_differential,
    home_points + away_points
FROM harmonized.games
WHERE away_team_id IS NOT NULL;

CREATE OR REPLACE VIEW analytics.team_season_summary AS
SELECT
    team_id,
    team_abbreviation,
    team_name,
    season_id,
    COUNT(*) AS games_played,
    COUNT(*) FILTER (WHERE result = 'W') AS wins,
    COUNT(*) FILTER (WHERE result = 'L') AS losses,
    ROUND(
        COUNT(*) FILTER (WHERE result = 'W')::NUMERIC / NULLIF(COUNT(*), 0),
        4
    ) AS win_percentage,
    ROUND(AVG(points_scored), 2) AS average_points_scored,
    ROUND(AVG(points_allowed), 2) AS average_points_allowed,
    ROUND(AVG(point_differential), 2) AS average_point_differential
FROM analytics.team_game_results
GROUP BY team_id, team_abbreviation, team_name, season_id;

CREATE OR REPLACE VIEW analytics.home_away_performance AS
SELECT
    team_id,
    team_abbreviation,
    team_name,
    COUNT(*) FILTER (WHERE location = 'Home') AS home_games,
    COUNT(*) FILTER (WHERE location = 'Home' AND result = 'W') AS home_wins,
    ROUND(
        COUNT(*) FILTER (WHERE location = 'Home' AND result = 'W')::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE location = 'Home'), 0),
        4
    ) AS home_win_percentage,
    COUNT(*) FILTER (WHERE location = 'Away') AS away_games,
    COUNT(*) FILTER (WHERE location = 'Away' AND result = 'W') AS away_wins,
    ROUND(
        COUNT(*) FILTER (WHERE location = 'Away' AND result = 'W')::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE location = 'Away'), 0),
        4
    ) AS away_win_percentage,
    ROUND(AVG(points_scored) FILTER (WHERE location = 'Home'), 2) AS home_average_points,
    ROUND(AVG(points_scored) FILTER (WHERE location = 'Away'), 2) AS away_average_points
FROM analytics.team_game_results
GROUP BY team_id, team_abbreviation, team_name;

CREATE OR REPLACE VIEW analytics.scoring_trends AS
SELECT
    season_id,
    COUNT(DISTINCT game_id) AS games_played,
    ROUND(AVG(home_points), 2) AS average_home_points,
    ROUND(AVG(away_points), 2) AS average_away_points,
    ROUND(AVG(home_points + away_points), 2) AS average_combined_points,
    MAX(home_points + away_points) AS highest_combined_points,
    MIN(home_points + away_points) AS lowest_combined_points
FROM harmonized.games
GROUP BY season_id;

CREATE OR REPLACE VIEW analytics.highest_scoring_games AS
SELECT
    game_id,
    season_id,
    game_date,
    season_type,
    home_team_abbreviation,
    home_team_name,
    away_team_abbreviation,
    away_team_name,
    home_points,
    away_points,
    home_points + away_points AS combined_points,
    point_differential
FROM harmonized.games
WHERE home_points IS NOT NULL AND away_points IS NOT NULL;

CREATE OR REPLACE VIEW analytics.quarter_scoring_summary AS
SELECT
    games.season_id,
    COUNT(*) AS games_played,
    ROUND(AVG(home_q1 + away_q1), 2) AS average_q1_points,
    ROUND(AVG(home_q2 + away_q2), 2) AS average_q2_points,
    ROUND(AVG(home_q3 + away_q3), 2) AS average_q3_points,
    ROUND(AVG(home_q4 + away_q4), 2) AS average_q4_points,
    ROUND(AVG(
        home_ot1 + home_ot2 + home_ot3 + home_ot4 + home_ot5
        + home_ot6 + home_ot7 + home_ot8 + home_ot9 + home_ot10
        + away_ot1 + away_ot2 + away_ot3 + away_ot4 + away_ot5
        + away_ot6 + away_ot7 + away_ot8 + away_ot9 + away_ot10
    ), 2) AS average_overtime_points
FROM harmonized.line_scores
JOIN harmonized.games
    ON games.game_id = line_scores.game_id
GROUP BY games.season_id;