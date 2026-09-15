CREATE OR REPLACE PROCEDURE automation.sp_transform_nba()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE
        harmonized.line_scores,
        harmonized.game_summary,
        harmonized.games,
        harmonized.players,
        harmonized.teams;

    INSERT INTO harmonized.teams (
        team_id, full_name, abbreviation, nickname, city, state, year_founded
    )
    SELECT
        NULLIF(TRIM(id), ''),
        NULLIF(TRIM(full_name), ''),
        NULLIF(UPPER(TRIM(abbreviation)), ''),
        NULLIF(TRIM(nickname), ''),
        NULLIF(TRIM(city), ''),
        NULLIF(TRIM(state), ''),
        NULLIF(TRIM(year_founded), '')::NUMERIC::INTEGER
    FROM raw.teams
    WHERE NULLIF(TRIM(id), '') IS NOT NULL;

    INSERT INTO harmonized.players (
        player_id, full_name, first_name, last_name, is_active
    )
    SELECT
        NULLIF(TRIM(id), ''),
        NULLIF(TRIM(full_name), ''),
        NULLIF(TRIM(first_name), ''),
        NULLIF(TRIM(last_name), ''),
        CASE LOWER(TRIM(is_active))
            WHEN '1' THEN TRUE
            WHEN 'true' THEN TRUE
            WHEN '0' THEN FALSE
            WHEN 'false' THEN FALSE
            ELSE NULL
        END
    FROM raw.players
    WHERE NULLIF(TRIM(id), '') IS NOT NULL;

    INSERT INTO harmonized.games (
        game_id, season_id, game_date, season_type,
        home_team_id, home_team_abbreviation, home_team_name, home_matchup, home_result,
        away_team_id, away_team_abbreviation, away_team_name, away_matchup, away_result,
        home_points, away_points, point_differential
    )
    SELECT DISTINCT ON (NULLIF(TRIM(game_id), ''))
        NULLIF(TRIM(game_id), ''),
        NULLIF(TRIM(season_id), ''),
        NULLIF(TRIM(game_date), '')::TIMESTAMP::DATE,
        CASE
            WHEN LOWER(TRIM(season_type)) IN ('all star', 'all-star') THEN 'All-Star'
            ELSE NULLIF(TRIM(season_type), '')
        END,
        NULLIF(TRIM(team_id_home), ''),
        NULLIF(UPPER(TRIM(team_abbreviation_home)), ''),
        NULLIF(TRIM(team_name_home), ''),
        NULLIF(TRIM(matchup_home), ''),
        NULLIF(UPPER(TRIM(wl_home)), ''),
        NULLIF(TRIM(team_id_away), ''),
        NULLIF(UPPER(TRIM(team_abbreviation_away)), ''),
        NULLIF(TRIM(team_name_away), ''),
        NULLIF(TRIM(matchup_away), ''),
        NULLIF(UPPER(TRIM(wl_away)), ''),
        NULLIF(TRIM(pts_home), '')::NUMERIC,
        NULLIF(TRIM(pts_away), '')::NUMERIC,
        NULLIF(TRIM(pts_home), '')::NUMERIC - NULLIF(TRIM(pts_away), '')::NUMERIC
    FROM raw.games
    WHERE NULLIF(TRIM(game_id), '') IS NOT NULL;

    INSERT INTO harmonized.game_summary (
        game_id, game_date, game_sequence, game_status_id, game_status_text,
        gamecode, home_team_id, visitor_team_id, season, live_period, live_pc_time,
        broadcaster, live_period_time_bcast, wh_status
    )
    SELECT DISTINCT ON (NULLIF(TRIM(game_id), ''))
        NULLIF(TRIM(game_id), ''),
        NULLIF(TRIM(game_date_est), '')::TIMESTAMP::DATE,
        NULLIF(TRIM(game_sequence), '')::NUMERIC::INTEGER,
        NULLIF(TRIM(game_status_id), '')::NUMERIC::INTEGER,
        NULLIF(TRIM(game_status_text), ''),
        NULLIF(TRIM(gamecode), ''),
        NULLIF(TRIM(home_team_id), ''),
        NULLIF(TRIM(visitor_team_id), ''),
        NULLIF(TRIM(season), ''),
        NULLIF(TRIM(live_period), '')::NUMERIC::INTEGER,
        NULLIF(TRIM(live_pc_time), ''),
        NULLIF(TRIM(natl_tv_broadcaster_abbreviation), ''),
        NULLIF(TRIM(live_period_time_bcast), ''),
        NULLIF(TRIM(wh_status), '')::NUMERIC::INTEGER
    FROM raw.game_summary
    WHERE NULLIF(TRIM(game_id), '') IS NOT NULL
    ORDER BY NULLIF(TRIM(game_id), ''),
        NULLIF(TRIM(game_status_text), '') IS NOT NULL DESC,
        NULLIF(TRIM(game_sequence), '') IS NOT NULL DESC;

    INSERT INTO harmonized.line_scores (
        game_id, game_date, game_sequence,
        home_team_id, home_team_abbreviation, home_team_city, home_team_nickname,
        home_wins_losses, home_q1, home_q2, home_q3, home_q4,
        home_ot1, home_ot2, home_ot3, home_ot4, home_ot5, home_ot6,
        home_ot7, home_ot8, home_ot9, home_ot10, home_points,
        away_team_id, away_team_abbreviation, away_team_city, away_team_nickname,
        away_wins_losses, away_q1, away_q2, away_q3, away_q4,
        away_ot1, away_ot2, away_ot3, away_ot4, away_ot5, away_ot6,
        away_ot7, away_ot8, away_ot9, away_ot10, away_points
    )
    SELECT DISTINCT ON (NULLIF(TRIM(game_id), ''))
        NULLIF(TRIM(game_id), ''),
        NULLIF(TRIM(game_date_est), '')::TIMESTAMP::DATE,
        NULLIF(TRIM(game_sequence), '')::NUMERIC::INTEGER,
        NULLIF(TRIM(team_id_home), ''),
        NULLIF(UPPER(TRIM(team_abbreviation_home)), ''),
        NULLIF(TRIM(team_city_name_home), ''),
        NULLIF(TRIM(team_nickname_home), ''),
        NULLIF(TRIM(team_wins_losses_home), ''),
        NULLIF(TRIM(pts_qtr1_home), '')::NUMERIC,
        NULLIF(TRIM(pts_qtr2_home), '')::NUMERIC,
        NULLIF(TRIM(pts_qtr3_home), '')::NUMERIC,
        NULLIF(TRIM(pts_qtr4_home), '')::NUMERIC,
        COALESCE(NULLIF(TRIM(pts_ot1_home), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot2_home), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot3_home), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot4_home), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot5_home), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot6_home), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot7_home), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot8_home), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot9_home), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot10_home), '')::NUMERIC, 0),
        NULLIF(TRIM(pts_home), '')::NUMERIC,
        NULLIF(TRIM(team_id_away), ''),
        NULLIF(UPPER(TRIM(team_abbreviation_away)), ''),
        NULLIF(TRIM(team_city_name_away), ''),
        NULLIF(TRIM(team_nickname_away), ''),
        NULLIF(TRIM(team_wins_losses_away), ''),
        NULLIF(TRIM(pts_qtr1_away), '')::NUMERIC,
        NULLIF(TRIM(pts_qtr2_away), '')::NUMERIC,
        NULLIF(TRIM(pts_qtr3_away), '')::NUMERIC,
        NULLIF(TRIM(pts_qtr4_away), '')::NUMERIC,
        COALESCE(NULLIF(TRIM(pts_ot1_away), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot2_away), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot3_away), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot4_away), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot5_away), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot6_away), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot7_away), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot8_away), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot9_away), '')::NUMERIC, 0),
        COALESCE(NULLIF(TRIM(pts_ot10_away), '')::NUMERIC, 0),
        NULLIF(TRIM(pts_away), '')::NUMERIC
    FROM raw.line_scores
    WHERE NULLIF(TRIM(game_id), '') IS NOT NULL
    ORDER BY NULLIF(TRIM(game_id), ''),
        NULLIF(TRIM(pts_home), '') IS NOT NULL DESC,
        NULLIF(TRIM(pts_away), '') IS NOT NULL DESC;
END;
$$;