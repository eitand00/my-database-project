-- ================================================================
-- Install all DB objects (views, functions, procedures)
-- Run from stage_5/ directory:
--   psql -U user_db -d world_cup_db -f sql\install.sql
-- ================================================================

-- Drop views first (CASCADE to handle dependencies)
DROP VIEW IF EXISTS vw_teams_list, vw_team_players,
    vw_team_matches, vw_players_list, vw_player_detail, vw_player_events,
    vw_player_match_stats, vw_matches_list, vw_match_detail, vw_match_events,
    vw_match_player_stats, vw_stadiums_list, vw_referees_list, vw_events_list,
    vw_high_scoring_matches, vw_big_stadiums_red_cards, vw_team_goals_analysis,
    vw_dashboard_counts, vw_teams_short, vw_stadiums_short, vw_referees_short,
    vw_team_detail, vw_tournaments CASCADE;

-- ========== CONSOLIDATED ENTITY FILES ==========
\i entity/functions.sql
\i entity/betting.sql
\i entity/teams.sql
\i entity/players.sql
\i entity/matches.sql
\i entity/stadiums.sql
\i entity/referees.sql
\i entity/events.sql
\i entity/reports.sql
\i entity/dashboard.sql
