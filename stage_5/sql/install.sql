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
    vw_high_scoring_matches, vw_big_stadiums_red_cards, vw_team_goals_analysis CASCADE;

-- ========== VIEWS ==========
\i views/vw_teams_list.sql
\i views/vw_team_players.sql
\i views/vw_team_matches.sql
\i views/vw_players_list.sql
\i views/vw_player_detail.sql
\i views/vw_player_events.sql
\i views/vw_player_match_stats.sql
\i views/vw_matches_list.sql
\i views/vw_match_detail.sql
\i views/vw_match_events.sql
\i views/vw_match_player_stats.sql
\i views/vw_stadiums_list.sql
\i views/vw_referees_list.sql
\i views/vw_events_list.sql
\i views/vw_high_scoring_matches.sql
\i views/vw_big_stadiums_red_cards.sql
\i views/vw_team_goals_analysis.sql

-- ========== FUNCTIONS ==========
-- Standalone functions first
\i functions/Calculate_Potential_Payout.sql
\i functions/Get_Match_Bettors_RefCursor.sql

-- Depends on Get_Match_Bettors_RefCursor
\i functions/Get_Match_Bettors.sql

-- ========== PROCEDURES ==========
-- CRUD procedures (standalone)
\i procedures/sp_team_insert.sql
\i procedures/sp_team_update.sql
\i procedures/sp_team_delete.sql
\i procedures/sp_player_insert.sql
\i procedures/sp_player_update.sql
\i procedures/sp_player_delete.sql
\i procedures/sp_match_insert.sql
\i procedures/sp_match_update.sql
\i procedures/sp_match_delete.sql
\i procedures/sp_stadium_insert.sql
\i procedures/sp_stadium_update.sql
\i procedures/sp_stadium_delete.sql
\i procedures/sp_referee_insert.sql
\i procedures/sp_referee_update.sql
\i procedures/sp_referee_delete.sql
\i procedures/sp_event_insert.sql
\i procedures/sp_event_delete.sql

-- Betting procedures (standalone)
\i procedures/Mass_Update_Stage_Odds.sql
\i procedures/create_bet.sql

-- Depends on create_bet + Calculate_Potential_Payout
\i procedures/create_bet_print_payout.sql

-- Depends on create_user (from stage_4) + create_bet + Get_Match_Bettors_RefCursor
\i procedures/crowd_wisdom.sql
