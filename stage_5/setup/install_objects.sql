-- ====================================================================
-- Install all DB objects: constraints, views, functions, procedures,
-- triggers. Runs AFTER all tables exist and data is loaded.
-- ====================================================================

-- ====================================================================
-- CONSTRAINTS (must run before views to avoid ALTER COLUMN TYPE errors)
-- ====================================================================
\i stage_2/Constraints.sql

-- ====================================================================
-- STAGE 4 — PROCEDURES (kept as individual files from stage_4)
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
-- STAGE 5 — CONSOLIDATED ENTITY FILES (dependency order)
-- ====================================================================
\i stage_5/sql/entity/functions.sql
\i stage_5/sql/entity/betting.sql
\i stage_5/sql/entity/teams.sql
\i stage_5/sql/entity/players.sql
\i stage_5/sql/entity/matches.sql
\i stage_5/sql/entity/stadiums.sql
\i stage_5/sql/entity/referees.sql
\i stage_5/sql/entity/events.sql
\i stage_5/sql/entity/reports.sql
\i stage_5/sql/entity/dashboard.sql
