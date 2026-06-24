-- ====================================================================
-- Full Installation Script — World Cup Database Manager
-- Creates only the 8 World Cup tables (no constraints, no objects).
-- RUN FROM PROJECT ROOT:
--   psql -U user_db -d world_cup_db -f stage_5/sql/full_install.sql
-- ====================================================================
SET client_encoding TO 'UTF8';

-- ====================================================================
-- DROP EVERYTHING (so the script is idempotent)
-- ====================================================================
DROP TRIGGER IF EXISTS trg_payout_on_win ON bets;
DROP TRIGGER IF EXISTS trg_prevent_negative_balance ON users;
DROP FUNCTION IF EXISTS trg_func_payout_on_win();
DROP FUNCTION IF EXISTS trg_func_prevent_negative_balance();

DROP VIEW IF EXISTS WorldCup_Odds_View, Bettors_On_WorldCup_View CASCADE;
DROP VIEW IF EXISTS vw_teams_list, vw_team_players, vw_team_matches,
    vw_players_list, vw_player_detail, vw_player_events,
    vw_player_match_stats, vw_matches_list, vw_match_detail, vw_match_events,
    vw_match_player_stats, vw_stadiums_list, vw_referees_list, vw_events_list,
    vw_high_scoring_matches, vw_big_stadiums_red_cards, vw_team_goals_analysis CASCADE;

DROP TABLE IF EXISTS MATCH_EVENT, PLAYER_MATCH_STATS, MATCH, PLAYER,
    REFEREE, PERSON, TEAM, STADIUM CASCADE;
DROP TABLE IF EXISTS GLOBAL_MATCH, transactions, bets, odds, matches, users, teams CASCADE;

DROP FUNCTION IF EXISTS Calculate_Potential_Payout(INT);
DROP FUNCTION IF EXISTS Get_Match_Bettors_RefCursor(INT);
DROP FUNCTION IF EXISTS Get_Match_Bettors(INT);

-- ====================================================================
-- STAGE 1 — TABLES (Minute is TEXT; constraints + FK added later)
-- ====================================================================
\i stage_1/createTables.sql
