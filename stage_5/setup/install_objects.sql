-- ====================================================================
-- Install all DB objects: constraints, views, functions, procedures,
-- triggers. Runs AFTER all tables exist and data is loaded.
-- ====================================================================

-- ====================================================================
-- CONSTRAINTS (must run before views to avoid ALTER COLUMN TYPE errors)
-- ====================================================================
\i stage_2/Constraints.sql

-- ====================================================================
-- STAGE 4 — FUNCTIONS
-- ====================================================================
\i stage_4/calculate_payout.sql
\i stage_4/refCursor.sql

-- ====================================================================
-- STAGE 4 — PROCEDURES
-- ====================================================================
\i stage_4/data_population/create_user.sql
\i stage_4/data_population/create_odd.sql
\i stage_4/data_population/create_bet.sql
\i stage_4/boostStageOdds.sql

-- ====================================================================
-- STAGE 4 — TRIGGERS (need bets/users tables from backup2.sql)
-- ====================================================================
\i stage_4/trigger_payout.sql
\i stage_4/trigger_balance.sql

-- ====================================================================
-- STAGE 3 — VIEWS (reference GLOBAL_MATCH + betting tables)
-- ====================================================================
\i stage_3/Views.sql

-- ====================================================================
-- STAGE 5 — VIEWS (17, complex queries only)
-- ====================================================================
\i stage_5/sql/views/vw_teams_list.sql
\i stage_5/sql/views/vw_team_players.sql
\i stage_5/sql/views/vw_team_matches.sql
\i stage_5/sql/views/vw_players_list.sql
\i stage_5/sql/views/vw_player_detail.sql
\i stage_5/sql/views/vw_player_events.sql
\i stage_5/sql/views/vw_player_match_stats.sql
\i stage_5/sql/views/vw_matches_list.sql
\i stage_5/sql/views/vw_match_detail.sql
\i stage_5/sql/views/vw_match_events.sql
\i stage_5/sql/views/vw_match_player_stats.sql
\i stage_5/sql/views/vw_stadiums_list.sql
\i stage_5/sql/views/vw_referees_list.sql
\i stage_5/sql/views/vw_events_list.sql
\i stage_5/sql/views/vw_high_scoring_matches.sql
\i stage_5/sql/views/vw_big_stadiums_red_cards.sql
\i stage_5/sql/views/vw_team_goals_analysis.sql

-- ====================================================================
-- STAGE 5 — FUNCTIONS
-- ====================================================================
\i stage_5/sql/functions/Get_Match_Bettors.sql

-- ====================================================================
-- STAGE 5 — CRUD PROCEDURES (21)
-- ====================================================================
\i stage_5/sql/procedures/sp_team_insert.sql
\i stage_5/sql/procedures/sp_team_update.sql
\i stage_5/sql/procedures/sp_team_delete.sql
\i stage_5/sql/procedures/sp_player_insert.sql
\i stage_5/sql/procedures/sp_player_update.sql
\i stage_5/sql/procedures/sp_player_delete.sql
\i stage_5/sql/procedures/sp_match_insert.sql
\i stage_5/sql/procedures/sp_match_update.sql
\i stage_5/sql/procedures/sp_match_delete.sql
\i stage_5/sql/procedures/sp_stadium_insert.sql
\i stage_5/sql/procedures/sp_stadium_update.sql
\i stage_5/sql/procedures/sp_stadium_delete.sql
\i stage_5/sql/procedures/sp_referee_insert.sql
\i stage_5/sql/procedures/sp_referee_update.sql
\i stage_5/sql/procedures/sp_referee_delete.sql
\i stage_5/sql/procedures/sp_event_insert.sql
\i stage_5/sql/procedures/sp_event_delete.sql
\i stage_5/sql/procedures/create_bet.sql
\i stage_5/sql/procedures/Mass_Update_Stage_Odds.sql
\i stage_5/sql/procedures/create_bet_print_payout.sql
\i stage_5/sql/procedures/crowd_wisdom.sql
