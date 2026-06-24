-- ====================================================================
-- Full Installation Script — World Cup Database Manager
-- Installs ALL DB objects for every stage using existing files.
-- RUN FROM PROJECT ROOT:
--   psql -U user_db -d world_cup_db -f stage_5/sql/full_install.sql
-- ====================================================================

-- ====================================================================
-- SET ENCODING (files are UTF-8, DB is UTF-8)
-- ====================================================================
SET client_encoding TO 'UTF8';

-- ====================================================================
-- DROP EVERYTHING
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
-- STAGE 1 — TABLES
-- ====================================================================
\i stage_1/createTables.sql

-- ====================================================================
-- STAGE 2 — CONSTRAINTS
-- ====================================================================
\i stage_2/Constraints.sql

-- ====================================================================
-- BETTING SYSTEM TABLES
-- ====================================================================
CREATE TABLE users (
    user_id INTEGER NOT NULL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    balance NUMERIC(12,2) DEFAULT 0,
    registration_date DATE NOT NULL,
    account_status VARCHAR(20) DEFAULT 'Active',
    CONSTRAINT chk_registration_date CHECK (registration_date <= CURRENT_DATE),
    CONSTRAINT users_balance_check CHECK (balance >= 0)
);

CREATE TABLE matches (
    match_id INTEGER NOT NULL PRIMARY KEY,
    match_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL,
    final_result VARCHAR(10),
    home_team_id INTEGER,
    away_team_id INTEGER,
    CONSTRAINT chk_different_teams CHECK (home_team_id <> away_team_id)
);

CREATE TABLE bets (
    bet_id INTEGER NOT NULL PRIMARY KEY,
    predicted_result VARCHAR(10) NOT NULL,
    bet_amount NUMERIC(10,2),
    bet_date DATE NOT NULL,
    bet_status VARCHAR(20) DEFAULT 'Pending',
    user_id INTEGER,
    match_id INTEGER,
    CONSTRAINT bets_bet_amount_check CHECK (bet_amount > 0)
);

CREATE TABLE odds (
    odd_id INTEGER NOT NULL PRIMARY KEY,
    home_win_odd NUMERIC(5,2),
    draw_odd NUMERIC(5,2),
    away_win_odd NUMERIC(5,2),
    update_date DATE NOT NULL,
    match_id INTEGER,
    CONSTRAINT odds_away_win_odd_check CHECK (away_win_odd > 1),
    CONSTRAINT odds_draw_odd_check CHECK (draw_odd > 1),
    CONSTRAINT odds_home_win_odd_check CHECK (home_win_odd > 1)
);

CREATE TABLE teams (
    team_id INTEGER NOT NULL PRIMARY KEY,
    team_name VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL
);

CREATE TABLE transactions (
    transaction_id INTEGER NOT NULL PRIMARY KEY,
    amount NUMERIC(10,2) NOT NULL,
    transaction_type VARCHAR(20),
    transaction_date DATE NOT NULL,
    user_id INTEGER,
    CONSTRAINT chk_positive_transaction CHECK (
        ((transaction_type IN ('Deposit', 'Winnings')) AND (amount > 0))
        OR (transaction_type IN ('Withdrawal', 'Bet Placement'))
    )
);

-- ====================================================================
-- STAGE 3 — INTEGRATION
-- ====================================================================
\i stage_3/Integrate.sql

-- ====================================================================
-- STAGE 3 — VIEWS
-- ====================================================================
\i stage_3/Views.sql

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
-- create_bet procedure used by stage_4 (CREATE OR REPLACE, no conflict)
\i stage_4/data_population/create_bet.sql
\i stage_4/boostStageOdds.sql

-- ====================================================================
-- STAGE 4 — TRIGGERS
-- ====================================================================
\i stage_4/trigger_payout.sql
\i stage_4/trigger_balance.sql

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
-- Get_Match_Bettors depends on Get_Match_Bettors_RefCursor (from stage_4)
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

-- ====================================================================
-- DATA NOTE
-- This creates the structure only. To populate data:
--   World Cup: run Python ETL (docker compose --profile import run --rm importer)
--   Betting:   psql -U user_db -d world_cup_db -f stage_3/backup2.sql
--   Then run integration DO blocks from stage_4/data_population/
-- ====================================================================
