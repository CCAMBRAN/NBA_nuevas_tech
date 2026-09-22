from pathlib import Path
import sys

import pandas as pd
import plotly.express as px
import streamlit as st
from sqlalchemy import text

BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR / "src"))

from db_connection import get_engine

st.set_page_config(page_title="NBA Analytics", page_icon="NBA", layout="wide")
st.title("NBA Analytics")
st.caption("Historical team and game performance")


@st.cache_data(ttl=300)
def load_view(query: str, params: dict | None = None) -> pd.DataFrame:
    with engine.connect() as connection:
        return pd.read_sql(text(query), connection, params=params)

try:
    engine = get_engine()
    st.success("Connected to PostgreSQL")
    seasons = load_view(
        "SELECT DISTINCT season_id FROM analytics.team_season_summary "
        "WHERE season_id IS NOT NULL ORDER BY season_id DESC"
    )["season_id"].tolist()
    season_options = ["All seasons"] + seasons
    selected_season = st.sidebar.selectbox("Season", season_options)

    season_filter = "" if selected_season == "All seasons" else "WHERE season_id = :season_id"
    params = {} if not season_filter else {"season_id": selected_season}

    summary = load_view(
        f"""
        SELECT
            COUNT(DISTINCT game_id) AS games,
            COUNT(DISTINCT team_id) AS teams,
            MIN(game_date) AS first_game,
            MAX(game_date) AS last_game,
            ROUND(AVG(points_scored), 1) AS average_points
        FROM analytics.team_game_results
        {season_filter}
        """,
        params,
    ).iloc[0]
    metric_columns = st.columns(5)
    metric_columns[0].metric("Games", f"{int(summary['games']):,}")
    metric_columns[1].metric("Teams", f"{int(summary['teams']):,}")
    metric_columns[2].metric("Average points", f"{summary['average_points']:.1f}")
    metric_columns[3].metric("First game", str(summary["first_game"]))
    metric_columns[4].metric("Last game", str(summary["last_game"]))

    team_summary = load_view(
        f"""
        SELECT team_abbreviation, team_name, games_played, wins, losses,
               win_percentage, average_points_scored, average_point_differential
        FROM analytics.team_season_summary
        {season_filter}
        ORDER BY win_percentage DESC, wins DESC
        LIMIT 30
        """,
        params,
    )
    st.subheader("Team performance")
    st.dataframe(team_summary, use_container_width=True, hide_index=True)

    st.caption("Scoring volume vs. net efficiency — bubble size is games played, color is win %")
    efficiency_fig = px.scatter(
        team_summary,
        x="average_points_scored",
        y="average_point_differential",
        size="games_played",
        color="win_percentage",
        color_continuous_scale=["#86b6ef", "#6da7ec", "#5598e7", "#3987e5", "#2a78d6", "#256abf", "#1c5cab", "#184f95"],
        size_max=22,
        hover_name="team_name",
        custom_data=["team_abbreviation", "wins", "losses"],
        labels={
            "average_points_scored": "Average points scored",
            "average_point_differential": "Average point differential",
        },
    )
    efficiency_fig.update_traces(
        marker=dict(sizemin=8, line=dict(width=1, color="rgba(137,135,129,0.6)")),
        hovertemplate=(
            "<b>%{hovertext} (%{customdata[0]})</b><br>"
            "Record %{customdata[1]}-%{customdata[2]}<br>"
            "Win pct %{marker.color:.1%}<br>"
            "Avg points scored %{x:.1f}<br>"
            "Avg point differential %{y:+.1f}"
            "<extra></extra>"
        ),
    )
    efficiency_fig.add_hline(y=0, line_width=1, line_color="rgba(137,135,129,0.6)")
    top_team = team_summary.loc[team_summary["win_percentage"].idxmax()]
    efficiency_fig.add_annotation(
        x=top_team["average_points_scored"],
        y=top_team["average_point_differential"],
        text=top_team["team_abbreviation"],
        showarrow=True,
        arrowhead=0,
        arrowcolor="#898781",
        ax=20,
        ay=-20,
        font=dict(color="#898781"),
    )
    efficiency_fig.update_layout(
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(0,0,0,0)",
        font=dict(color="#898781"),
        coloraxis_colorbar=dict(title="Win %", tickformat=".0%"),
        margin=dict(l=10, r=10, t=10, b=10),
        height=450,
    )
    efficiency_fig.update_xaxes(gridcolor="rgba(137,135,129,0.3)", zeroline=False)
    efficiency_fig.update_yaxes(gridcolor="rgba(137,135,129,0.3)", zeroline=False)
    st.plotly_chart(efficiency_fig, use_container_width=True)

    scoring = load_view(
        """
        SELECT season_id, average_home_points, average_away_points,
               average_combined_points
        FROM analytics.scoring_trends
        ORDER BY season_start
        """
    )
    st.subheader("Scoring trends")
    st.line_chart(
        scoring.set_index("season_id")[[
            "average_home_points",
            "average_away_points",
            "average_combined_points",
        ]]
    )

    high_scores = load_view(
        """
        SELECT game_date, season_id, home_team_abbreviation, away_team_abbreviation,
               home_points, away_points, combined_points, point_differential
        FROM analytics.highest_scoring_games
        ORDER BY combined_points DESC
        LIMIT 10
        """
    )
    st.subheader("Highest-scoring games")
    st.dataframe(high_scores, use_container_width=True, hide_index=True)
except Exception as exc:
    st.error("PostgreSQL is not available yet.")
    st.exception(exc)
