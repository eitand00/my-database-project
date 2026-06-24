-- ====================================================================
-- Full Installation Script — World Cup Database Manager
-- Creates ALL DB objects: tables, constraints, views, functions,
-- procedures, triggers. Run on an empty PostgreSQL database:
--   psql -U user_db -d world_cup_db -f full_install.sql
--
-- DATA NOTE: This creates the structure only. To populate data:
--   World Cup data: run the Python ETL (generate_data.py)
--   Betting data:   restore from stage_3/backup2.sql
--   Integration:    INSERT INTO GLOBAL_MATCH (WCMatchID) SELECT MatchID FROM MATCH
--                   INSERT INTO GLOBAL_MATCH (BettingMatchID) SELECT match_id FROM matches
-- ====================================================================

-- ====================================================================
-- 1. DROP ALL EXISTING OBJECTS (order matters for FK dependencies)
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

DROP TABLE IF EXISTS MATCH_EVENT CASCADE;
DROP TABLE IF EXISTS PLAYER_MATCH_STATS CASCADE;
DROP TABLE IF EXISTS MATCH CASCADE;
DROP TABLE IF EXISTS PLAYER CASCADE;
DROP TABLE IF EXISTS REFEREE CASCADE;
DROP TABLE IF EXISTS PERSON CASCADE;
DROP TABLE IF EXISTS TEAM CASCADE;
DROP TABLE IF EXISTS STADIUM CASCADE;

DROP TABLE IF EXISTS GLOBAL_MATCH CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS bets CASCADE;
DROP TABLE IF EXISTS odds CASCADE;
DROP TABLE IF EXISTS matches CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS teams CASCADE;

-- ====================================================================
-- 2. WORLD CUP TABLES (stage_1)
-- ====================================================================
CREATE TABLE PERSON (
    ID VARCHAR(50) NOT NULL,
    FamilyName TEXT,
    GivenName TEXT NOT NULL,
    WikipediaPage TEXT,
    PRIMARY KEY (ID)
);

CREATE TABLE TEAM (
    TeamCode VARCHAR(50) NOT NULL,
    CountryName TEXT NOT NULL,
    ConfederationName TEXT NOT NULL,
    ConfederationCode VARCHAR(50) NOT NULL,
    WikipediaPage TEXT,
    PRIMARY KEY (TeamCode)
);

CREATE TABLE PLAYER (
    DateOfBirth DATE,
    TeamCode VARCHAR(50),
    ID VARCHAR(50) NOT NULL,
    PRIMARY KEY (ID),
    FOREIGN KEY (TeamCode) REFERENCES TEAM(TeamCode),
    FOREIGN KEY (ID) REFERENCES PERSON(ID)
);

CREATE TABLE REFEREE (
    Country TEXT NOT NULL,
    ConfederationCode VARCHAR(50) NOT NULL,
    ConfederationName TEXT NOT NULL,
    ID VARCHAR(50) NOT NULL,
    PRIMARY KEY (ID),
    FOREIGN KEY (ID) REFERENCES PERSON(ID)
);

CREATE TABLE STADIUM (
    StadiumID VARCHAR(50) NOT NULL,
    City TEXT NOT NULL,
    Name TEXT NOT NULL,
    Capacity INT NOT NULL,
    WikipediaPage TEXT,
    Country TEXT NOT NULL,
    PRIMARY KEY (StadiumID)
);

CREATE TABLE MATCH (
    MatchID VARCHAR(50) NOT NULL,
    MatchDate DATE NOT NULL,
    Stage TEXT NOT NULL,
    Tournament TEXT NOT NULL,
    MatchTime TIME,
    StadiumID VARCHAR(50) NOT NULL,
    GuestTeamCode VARCHAR(50) NOT NULL,
    HomeTeamCode VARCHAR(50) NOT NULL,
    RefereeID VARCHAR(50) NOT NULL,
    PRIMARY KEY (MatchID),
    FOREIGN KEY (StadiumID) REFERENCES STADIUM(StadiumID),
    FOREIGN KEY (GuestTeamCode) REFERENCES TEAM(TeamCode),
    FOREIGN KEY (HomeTeamCode) REFERENCES TEAM(TeamCode),
    FOREIGN KEY (RefereeID) REFERENCES REFEREE(ID)
);

CREATE TABLE MATCH_EVENT (
    Minute TEXT NOT NULL,
    EventType TEXT NOT NULL,
    MatchEventID VARCHAR(50) NOT NULL,
    MatchID VARCHAR(50) NOT NULL,
    ID VARCHAR(50) NOT NULL,
    PRIMARY KEY (MatchEventID),
    FOREIGN KEY (MatchID) REFERENCES MATCH(MatchID),
    FOREIGN KEY (ID) REFERENCES PLAYER(ID)
);

CREATE TABLE PLAYER_MATCH_STATS (
    Position TEXT NOT NULL,
    ShirtNumber INT NOT NULL,
    MatchID VARCHAR(50) NOT NULL,
    PlayerID VARCHAR(50) NOT NULL,
    PRIMARY KEY (MatchID, PlayerID),
    FOREIGN KEY (MatchID) REFERENCES MATCH(MatchID),
    FOREIGN KEY (PlayerID) REFERENCES PLAYER(ID)
);

-- ====================================================================
-- 3. BETTING SYSTEM TABLES (stage_3 backup2)
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
-- 4. CONSTRAINTS (stage_2)
-- ====================================================================
ALTER TABLE MATCH_EVENT
ALTER COLUMN Minute TYPE INTEGER
USING (
    split_part(REPLACE(Minute, '''', ''), '+', 1)::INTEGER +
    COALESCE(NULLIF(split_part(REPLACE(Minute, '''', ''), '+', 2), ''), '0')::INTEGER
);

ALTER TABLE STADIUM
ADD CONSTRAINT chk_stadium_capacity CHECK (Capacity > 0);

ALTER TABLE MATCH_EVENT
ADD CONSTRAINT chk_event_minute CHECK (Minute > 0 AND Minute <= 130);

ALTER TABLE MATCH
ADD CONSTRAINT chk_match_stage CHECK (Stage IN ('Group Stage', 'Round of 16', 'Quarter-Final', 'Semi-Final', 'Third Place', 'Final'));

-- ====================================================================
-- 5. INTEGRATION — GLOBAL_MATCH + DATA MIGRATION (stage_3)
-- ====================================================================
CREATE TABLE GLOBAL_MATCH (
    GlobalMatchID SERIAL PRIMARY KEY,
    MatchSource VARCHAR(20) NOT NULL,
    WCMatchID VARCHAR(50),
    BettingMatchID INT,
    CONSTRAINT fk_global_wc FOREIGN KEY (WCMatchID) REFERENCES MATCH(MatchID),
    CONSTRAINT fk_global_betting FOREIGN KEY (BettingMatchID) REFERENCES matches(match_id),
    CONSTRAINT chk_exclusive_match CHECK (
        (WCMatchID IS NOT NULL AND BettingMatchID IS NULL) OR
        (WCMatchID IS NULL AND BettingMatchID IS NOT NULL)
    )
);

ALTER TABLE bets ADD COLUMN global_match_id INT;
ALTER TABLE odds ADD COLUMN global_match_id INT;

ALTER TABLE bets ADD CONSTRAINT fk_bets_global FOREIGN KEY (global_match_id) REFERENCES GLOBAL_MATCH(GlobalMatchID);
ALTER TABLE odds ADD CONSTRAINT fk_odds_global FOREIGN KEY (global_match_id) REFERENCES GLOBAL_MATCH(GlobalMatchID);

-- ====================================================================
-- 6. STAGE 3 VIEWS
-- ====================================================================
CREATE OR REPLACE VIEW WorldCup_Odds_View AS
SELECT
    m.MatchDate, m.Stage,
    ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
    o.home_win_odd, o.draw_odd, o.away_win_odd
FROM MATCH m
JOIN GLOBAL_MATCH gm ON m.MatchID = gm.WCMatchID
JOIN odds o ON gm.GlobalMatchID = o.global_match_id
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode;

CREATE OR REPLACE VIEW Bettors_On_WorldCup_View AS
SELECT
    u.full_name AS Bettor_Name, b.bet_amount, b.predicted_result,
    m.MatchDate, ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam
FROM users u
JOIN bets b ON u.user_id = b.user_id
JOIN GLOBAL_MATCH gm ON b.global_match_id = gm.GlobalMatchID
JOIN MATCH m ON gm.WCMatchID = m.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode;

-- ====================================================================
-- 7. STAGE 4 — FUNCTIONS
-- ====================================================================
CREATE OR REPLACE FUNCTION Calculate_Potential_Payout(p_bet_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_bet_record bets%ROWTYPE;
    v_odds_record odds%ROWTYPE;
    v_expected_payout NUMERIC := 0;
BEGIN
    SELECT * INTO STRICT v_bet_record FROM bets WHERE bet_id = p_bet_id;
    SELECT * INTO STRICT v_odds_record FROM odds WHERE global_match_id = v_bet_record.global_match_id;
    IF v_bet_record.predicted_result = 'Home' THEN
        v_expected_payout := v_bet_record.bet_amount * v_odds_record.home_win_odd;
    ELSIF v_bet_record.predicted_result = 'Away' THEN
        v_expected_payout := v_bet_record.bet_amount * v_odds_record.away_win_odd;
    ELSIF v_bet_record.predicted_result = 'Draw' THEN
        v_expected_payout := v_bet_record.bet_amount * v_odds_record.draw_odd;
    ELSE
        RAISE EXCEPTION 'Invalid predicted result format.';
    END IF;
    RETURN v_expected_payout;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE NOTICE 'Exception Caught: Bet ID % was not found.', p_bet_id;
        RETURN -1;
    WHEN OTHERS THEN
        RAISE NOTICE 'An unexpected error occurred: %', SQLERRM;
        RETURN -1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Get_Match_Bettors_RefCursor(p_global_match_id INT)
RETURNS refcursor AS $$
DECLARE
    v_ref_cur refcursor;
BEGIN
    OPEN v_ref_cur FOR
        SELECT u.full_name, b.bet_amount, b.predicted_result, b.bet_status
        FROM bets b
        JOIN users u ON b.user_id = u.user_id
        WHERE b.global_match_id = p_global_match_id;
    RETURN v_ref_cur;
END;
$$ LANGUAGE plpgsql;

-- ====================================================================
-- 8. STAGE 4 — PROCEDURES
-- ====================================================================
CREATE OR REPLACE PROCEDURE create_user(
    p_full_name VARCHAR, p_email VARCHAR, p_initial_balance NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_new_user_id INT;
BEGIN
    IF p_full_name IS NULL OR length(trim(p_full_name)) = 0 THEN
        RAISE EXCEPTION 'Registration Failed: User name cannot be empty.';
    END IF;
    SELECT COALESCE(MAX(user_id), 0) + 1 INTO v_new_user_id FROM users;
    INSERT INTO users (user_id, full_name, email, balance, registration_date, account_status)
    VALUES (v_new_user_id, p_full_name, p_email, p_initial_balance, CURRENT_DATE, 'Active');
    RAISE NOTICE 'System: User "%" registered successfully with ID %, Date: %, Status: Active.', p_full_name, v_new_user_id, CURRENT_DATE;
END;
$$;

CREATE OR REPLACE PROCEDURE create_odd(
    p_global_match_id INT, p_home_odd NUMERIC, p_draw_odd NUMERIC, p_away_odd NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_new_odd_id INT;
BEGIN
    IF EXISTS (SELECT 1 FROM odds WHERE global_match_id = p_global_match_id) THEN
        RAISE EXCEPTION 'Data Error: Odds already exist for match %', p_global_match_id;
    END IF;
    IF p_home_odd <= 1.0 OR p_draw_odd <= 1.0 OR p_away_odd <= 1.0 THEN
        RAISE EXCEPTION 'Logic Error: Betting odds must be greater than 1.0';
    END IF;
    SELECT COALESCE(MAX(odd_id), 0) + 1 INTO v_new_odd_id FROM odds;
    INSERT INTO odds (global_match_id, home_win_odd, draw_odd, away_win_odd, update_date, odd_id)
    VALUES (p_global_match_id, p_home_odd, p_draw_odd, p_away_odd, CURRENT_DATE, v_new_odd_id);
END;
$$;

CREATE OR REPLACE PROCEDURE create_bet(
    p_user_id INT, p_global_match_id INT, p_amount NUMERIC, p_prediction VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_match_exists BOOLEAN;
    v_new_bet_id INT;
BEGIN
    IF p_prediction NOT IN ('Home', 'Draw', 'Away') THEN
        RAISE EXCEPTION 'Betting Failed: Invalid prediction syntax. Must be ''Home'', ''Draw'', or ''Away''. Received: "%"', p_prediction;
    END IF;
    SELECT EXISTS(SELECT 1 FROM GLOBAL_MATCH WHERE GlobalMatchID = p_global_match_id) INTO v_match_exists;
    IF NOT v_match_exists THEN
        RAISE EXCEPTION 'Betting Failed: Match ID % does not exist.', p_global_match_id;
    END IF;
    SELECT COALESCE(MAX(bet_id), 0) + 1 INTO v_new_bet_id FROM bets;
    UPDATE users SET balance = balance - p_amount WHERE user_id = p_user_id;
    INSERT INTO bets (bet_id, user_id, global_match_id, bet_amount, predicted_result, bet_status, bet_date)
    VALUES (v_new_bet_id, p_user_id, p_global_match_id, p_amount, p_prediction, 'Pending', CURRENT_DATE);
    RAISE NOTICE 'System: Bet ID % placed successfully for user % on match % on %.', v_new_bet_id, p_user_id, p_global_match_id, CURRENT_DATE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Transaction Aborted: %', SQLERRM;
        ROLLBACK;
END;
$$;

CREATE OR REPLACE PROCEDURE Mass_Update_Stage_Odds(p_stage VARCHAR, p_boost_factor NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
    v_match_id INT;
    v_counter INT := 0;
    v_match_cursor CURSOR FOR
        SELECT gm.GlobalMatchID
        FROM GLOBAL_MATCH gm
        JOIN MATCH m ON gm.WCMatchID = m.MatchID
        WHERE LOWER(m.Stage) = LOWER(p_stage) AND gm.MatchSource = 'WorldCup';
BEGIN
    OPEN v_match_cursor;
    LOOP
        FETCH v_match_cursor INTO v_match_id;
        EXIT WHEN NOT FOUND;
        UPDATE odds
        SET home_win_odd = home_win_odd * p_boost_factor,
            away_win_odd = away_win_odd * p_boost_factor,
            draw_odd = draw_odd * p_boost_factor
        WHERE global_match_id = v_match_id;
        v_counter := v_counter + 1;
    END LOOP;
    CLOSE v_match_cursor;
    RAISE NOTICE 'Successfully boosted odds for % matches in stage %', v_counter, p_stage;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error encountered during mass update: %', SQLERRM;
        ROLLBACK;
END;
$$;

-- ====================================================================
-- 9. STAGE 4 — TRIGGERS
-- ====================================================================
CREATE OR REPLACE FUNCTION trg_func_payout_on_win()
RETURNS TRIGGER AS $$
DECLARE
    v_odd NUMERIC;
    v_payout NUMERIC;
BEGIN
    IF NEW.bet_status = 'Won' AND (OLD.bet_status IS DISTINCT FROM 'Won') THEN
        IF NEW.predicted_result = 'Home' THEN
            SELECT home_win_odd INTO v_odd FROM odds WHERE global_match_id = NEW.global_match_id;
        ELSIF NEW.predicted_result = 'Away' THEN
            SELECT away_win_odd INTO v_odd FROM odds WHERE global_match_id = NEW.global_match_id;
        ELSIF NEW.predicted_result = 'Draw' THEN
            SELECT draw_odd INTO v_odd FROM odds WHERE global_match_id = NEW.global_match_id;
        END IF;
        v_payout := NEW.bet_amount * v_odd;
        UPDATE users SET balance = balance + v_payout WHERE user_id = NEW.user_id;
        RAISE NOTICE 'Trigger Executed: User % won bet %. Added % to balance.', NEW.user_id, NEW.bet_id, v_payout;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_payout_on_win
AFTER UPDATE OF bet_status ON bets
FOR EACH ROW EXECUTE FUNCTION trg_func_payout_on_win();

CREATE OR REPLACE FUNCTION trg_func_prevent_negative_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.balance < 0 THEN
        RAISE EXCEPTION 'Transaction Denied: User % does not have enough funds. Balance cannot drop below 0 (Attempted balance: %)', NEW.user_id, NEW.balance;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_negative_balance
BEFORE UPDATE OF balance ON users
FOR EACH ROW EXECUTE FUNCTION trg_func_prevent_negative_balance();

-- ====================================================================
-- 10. STAGE 5 — VIEWS (complex queries only, 17 files)
-- ====================================================================
CREATE OR REPLACE VIEW vw_teams_list AS
SELECT t.TeamCode, t.CountryName, t.ConfederationName,
    (SELECT COUNT(*) FROM MATCH m WHERE m.HomeTeamCode = t.TeamCode OR m.GuestTeamCode = t.TeamCode) AS MatchCount
FROM TEAM t ORDER BY t.CountryName;

CREATE OR REPLACE VIEW vw_team_players AS
SELECT pl.ID, p.GivenName, p.FamilyName, pl.DateOfBirth, pl.TeamCode
FROM PLAYER pl JOIN PERSON p ON pl.ID = p.ID ORDER BY p.FamilyName;

CREATE OR REPLACE VIEW vw_team_matches AS
SELECT m.MatchID, m.MatchDate, m.Stage, m.Tournament,
    ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
    s.Name AS Stadium
FROM MATCH m
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
JOIN STADIUM s ON m.StadiumID = s.StadiumID;

CREATE OR REPLACE VIEW vw_players_list AS
SELECT pl.ID, p.GivenName, p.FamilyName, pl.DateOfBirth, pl.TeamCode,
    t.CountryName AS TeamName,
    (SELECT COUNT(*) FROM MATCH_EVENT me WHERE me.ID = pl.ID) AS EventCount
FROM PLAYER pl
JOIN PERSON p ON pl.ID = p.ID
LEFT JOIN TEAM t ON pl.TeamCode = t.TeamCode
ORDER BY p.FamilyName;

CREATE OR REPLACE VIEW vw_player_detail AS
SELECT pl.ID, p.GivenName, p.FamilyName, p.WikipediaPage, pl.DateOfBirth,
    pl.TeamCode, t.CountryName AS TeamName
FROM PLAYER pl
JOIN PERSON p ON pl.ID = p.ID
LEFT JOIN TEAM t ON pl.TeamCode = t.TeamCode;

CREATE OR REPLACE VIEW vw_player_events AS
SELECT me.MatchEventID, me.MatchID, me.Minute, me.EventType,
    m.MatchDate, m.Stage, m.Tournament, me.ID AS PlayerID
FROM MATCH_EVENT me
JOIN MATCH m ON me.MatchID = m.MatchID
ORDER BY me.MatchEventID;

CREATE OR REPLACE VIEW vw_player_match_stats AS
SELECT pms.MatchID, pms.PlayerID, pms.Position, pms.ShirtNumber,
    m.MatchDate, m.Stage, m.Tournament
FROM PLAYER_MATCH_STATS pms
JOIN MATCH m ON pms.MatchID = m.MatchID;

CREATE OR REPLACE VIEW vw_matches_list AS
SELECT m.MatchID, m.MatchDate, m.Stage, m.Tournament, m.MatchTime,
    ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
    s.Name AS Stadium, r.ID AS RefereeID,
    (SELECT COUNT(*) FROM MATCH_EVENT me WHERE me.MatchID = m.MatchID) AS EventCount
FROM MATCH m
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
JOIN STADIUM s ON m.StadiumID = s.StadiumID
JOIN REFEREE r ON m.RefereeID = r.ID
ORDER BY m.MatchDate DESC;

CREATE OR REPLACE VIEW vw_match_detail AS
SELECT m.MatchID, m.MatchDate, m.Stage, m.Tournament, m.MatchTime,
    ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
    s.Name AS Stadium, s.City, s.Country,
    CONCAT(per.GivenName, ' ', per.FamilyName) AS RefereeName
FROM MATCH m
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
JOIN STADIUM s ON m.StadiumID = s.StadiumID
JOIN REFEREE r ON m.RefereeID = r.ID
JOIN PERSON per ON r.ID = per.ID;

CREATE OR REPLACE VIEW vw_match_events AS
SELECT me.MatchEventID, me.MatchID, me.Minute, me.EventType,
    p.GivenName, p.FamilyName, me.ID AS PlayerID
FROM MATCH_EVENT me
JOIN PERSON p ON me.ID = p.ID
ORDER BY regexp_replace(me.Minute::text, '[+''''].*$', '')::int;

CREATE OR REPLACE VIEW vw_match_player_stats AS
SELECT pms.MatchID, pms.PlayerID, pms.Position, pms.ShirtNumber,
    p.GivenName, p.FamilyName
FROM PLAYER_MATCH_STATS pms
JOIN PERSON p ON pms.PlayerID = p.ID;

CREATE OR REPLACE VIEW vw_stadiums_list AS
SELECT s.StadiumID, s.Name, s.City, s.Country, s.Capacity,
    (SELECT COUNT(*) FROM MATCH m WHERE m.StadiumID = s.StadiumID) AS MatchCount
FROM STADIUM s ORDER BY s.Name;

CREATE OR REPLACE VIEW vw_referees_list AS
SELECT r.ID, per.GivenName, per.FamilyName, r.Country, r.ConfederationCode,
    r.ConfederationName,
    (SELECT COUNT(*) FROM MATCH m WHERE m.RefereeID = r.ID) AS MatchCount
FROM REFEREE r JOIN PERSON per ON r.ID = per.ID ORDER BY per.FamilyName;

CREATE OR REPLACE VIEW vw_events_list AS
SELECT me.MatchEventID, me.MatchID, me.Minute, me.EventType,
    p.GivenName, p.FamilyName, me.ID AS PlayerID,
    m.MatchDate, ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam
FROM MATCH_EVENT me
JOIN PERSON p ON me.ID = p.ID
JOIN MATCH m ON me.MatchID = m.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
ORDER BY me.MatchEventID;

-- Report views (3)
CREATE OR REPLACE VIEW vw_high_scoring_matches AS
SELECT m.MatchID, m.MatchDate, m.Stage, m.Tournament,
    ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
    COUNT(me.MatchEventID) AS TotalGoals
FROM MATCH m
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
JOIN MATCH_EVENT me ON me.MatchID = m.MatchID
WHERE me.EventType ILIKE '%goal%'
GROUP BY m.MatchID, m.MatchDate, m.Stage, m.Tournament, ht.CountryName, gt.CountryName
ORDER BY TotalGoals DESC;

CREATE OR REPLACE VIEW vw_big_stadiums_red_cards AS
SELECT s.Name AS StadiumName, s.City, s.Country, s.Capacity,
    COUNT(DISTINCT me.MatchEventID) AS RedCardEvents
FROM STADIUM s
JOIN MATCH m ON s.StadiumID = m.StadiumID
JOIN MATCH_EVENT me ON me.MatchID = m.MatchID AND me.EventType ILIKE '%red%'
GROUP BY s.StadiumID, s.Name, s.City, s.Country, s.Capacity
HAVING COUNT(DISTINCT me.MatchEventID) > 0
ORDER BY s.Capacity DESC;

CREATE OR REPLACE VIEW vw_team_goals_analysis AS
SELECT t.TeamCode, t.CountryName,
    COUNT(DISTINCT m.MatchID) AS MatchesPlayed,
    COUNT(DISTINCT me.MatchEventID) AS TotalGoalsScored,
    ROUND(COUNT(DISTINCT me.MatchEventID)::NUMERIC / NULLIF(COUNT(DISTINCT m.MatchID), 0), 2) AS GoalsPerMatch
FROM TEAM t
JOIN MATCH m ON t.TeamCode IN (m.HomeTeamCode, m.GuestTeamCode)
JOIN MATCH_EVENT me ON me.MatchID = m.MatchID
    AND me.ID IN (SELECT p.ID FROM PLAYER p WHERE p.TeamCode = t.TeamCode)
    AND me.EventType ILIKE '%goal%'
GROUP BY t.TeamCode, t.CountryName
ORDER BY TotalGoalsScored DESC;

-- ====================================================================
-- 11. STAGE 5 — ADDITIONAL FUNCTION
-- ====================================================================
DROP FUNCTION IF EXISTS Get_Match_Bettors(INT);
CREATE OR REPLACE FUNCTION Get_Match_Bettors(p_global_match_id INT)
RETURNS TABLE(full_name VARCHAR, bet_amount NUMERIC, predicted_result VARCHAR, bet_status VARCHAR) AS $$
DECLARE
    v_ref refcursor;
    v_row RECORD;
BEGIN
    v_ref := Get_Match_Bettors_RefCursor(p_global_match_id);
    LOOP
        FETCH v_ref INTO v_row;
        EXIT WHEN NOT FOUND;
        full_name := v_row.full_name;
        bet_amount := v_row.bet_amount;
        predicted_result := v_row.predicted_result;
        bet_status := v_row.bet_status;
        RETURN NEXT;
    END LOOP;
    CLOSE v_ref;
END;
$$ LANGUAGE plpgsql;

-- ====================================================================
-- 12. STAGE 5 — CRUD PROCEDURES
-- ====================================================================
-- TEAM
CREATE OR REPLACE PROCEDURE sp_team_insert(p_code VARCHAR, p_country TEXT, p_conf_name TEXT, p_conf_code VARCHAR, p_wiki TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO TEAM (TeamCode, CountryName, ConfederationName, ConfederationCode, WikipediaPage)
    VALUES (p_code, p_country, p_conf_name, p_conf_code, p_wiki);
    RAISE NOTICE 'Team % inserted successfully.', p_code;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_team_update(p_code VARCHAR, p_country TEXT, p_conf_name TEXT, p_conf_code VARCHAR, p_wiki TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE TEAM SET CountryName = p_country, ConfederationName = p_conf_name,
        ConfederationCode = p_conf_code, WikipediaPage = p_wiki
    WHERE TeamCode = p_code;
    RAISE NOTICE 'Team % updated successfully.', p_code;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_team_delete(p_code VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM TEAM WHERE TeamCode = p_code;
    RAISE NOTICE 'Team % deleted successfully.', p_code;
END;
$$;

-- PLAYER
CREATE OR REPLACE PROCEDURE sp_player_insert(p_id VARCHAR, p_given TEXT, p_family TEXT, p_wiki TEXT, p_dob DATE, p_team VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO PERSON (ID, GivenName, FamilyName, WikipediaPage) VALUES (p_id, p_given, p_family, p_wiki);
    INSERT INTO PLAYER (ID, DateOfBirth, TeamCode) VALUES (p_id, p_dob, p_team);
    RAISE NOTICE 'Player % inserted successfully.', p_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_player_update(p_id VARCHAR, p_dob DATE, p_team_code VARCHAR, p_given_name TEXT, p_family_name TEXT, p_wiki TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE PERSON SET GivenName = p_given_name, FamilyName = p_family_name, WikipediaPage = p_wiki WHERE ID = p_id;
    UPDATE PLAYER SET DateOfBirth = p_dob, TeamCode = p_team_code WHERE ID = p_id;
    RAISE NOTICE 'Player % updated successfully.', p_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_player_delete(p_id VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM PLAYER WHERE ID = p_id;
    DELETE FROM PERSON WHERE ID = p_id;
    RAISE NOTICE 'Player % deleted successfully.', p_id;
END;
$$;

-- MATCH
CREATE OR REPLACE PROCEDURE sp_match_insert(p_mid VARCHAR, p_mdate DATE, p_stage TEXT, p_tournament TEXT, p_time TIME, p_stadium VARCHAR, p_home VARCHAR, p_guest VARCHAR, p_referee VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO MATCH (MatchID, MatchDate, Stage, Tournament, MatchTime, StadiumID, HomeTeamCode, GuestTeamCode, RefereeID)
    VALUES (p_mid, p_mdate, p_stage, p_tournament, p_time, p_stadium, p_home, p_guest, p_referee);
    RAISE NOTICE 'Match % inserted successfully.', p_mid;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_match_update(p_mid VARCHAR, p_mdate DATE, p_stage TEXT, p_tournament TEXT, p_time TIME, p_stadium VARCHAR, p_home VARCHAR, p_guest VARCHAR, p_referee VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE MATCH SET MatchDate = p_mdate, Stage = p_stage, Tournament = p_tournament,
        MatchTime = p_time, StadiumID = p_stadium, HomeTeamCode = p_home,
        GuestTeamCode = p_guest, RefereeID = p_referee
    WHERE MatchID = p_mid;
    RAISE NOTICE 'Match % updated successfully.', p_mid;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_match_delete(p_mid VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM MATCH_EVENT WHERE MatchID = p_mid;
    DELETE FROM PLAYER_MATCH_STATS WHERE MatchID = p_mid;
    DELETE FROM MATCH WHERE MatchID = p_mid;
    RAISE NOTICE 'Match % and related events deleted successfully.', p_mid;
END;
$$;

-- STADIUM
CREATE OR REPLACE PROCEDURE sp_stadium_insert(p_sid VARCHAR, p_name TEXT, p_city TEXT, p_capacity INT, p_country TEXT, p_wiki TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO STADIUM (StadiumID, Name, City, Capacity, Country, WikipediaPage)
    VALUES (p_sid, p_name, p_city, p_capacity, p_country, p_wiki);
    RAISE NOTICE 'Stadium % inserted successfully.', p_sid;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_stadium_update(p_sid VARCHAR, p_name TEXT, p_city TEXT, p_capacity INT, p_country TEXT, p_wiki TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE STADIUM SET Name = p_name, City = p_city, Capacity = p_capacity,
        Country = p_country, WikipediaPage = p_wiki
    WHERE StadiumID = p_sid;
    RAISE NOTICE 'Stadium % updated successfully.', p_sid;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_stadium_delete(p_sid VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM STADIUM WHERE StadiumID = p_sid;
    RAISE NOTICE 'Stadium % deleted successfully.', p_sid;
END;
$$;

-- REFEREE
CREATE OR REPLACE PROCEDURE sp_referee_insert(p_rid VARCHAR, p_country TEXT, p_conf_code VARCHAR, p_conf_name TEXT, p_given TEXT, p_family TEXT, p_wiki TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO PERSON (ID, GivenName, FamilyName, WikipediaPage) VALUES (p_rid, p_given, p_family, p_wiki);
    INSERT INTO REFEREE (ID, Country, ConfederationCode, ConfederationName) VALUES (p_rid, p_country, p_conf_code, p_conf_name);
    RAISE NOTICE 'Referee % inserted successfully.', p_rid;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_referee_update(p_rid VARCHAR, p_country TEXT, p_conf_code VARCHAR, p_conf_name TEXT, p_given TEXT, p_family TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE PERSON SET GivenName = p_given, FamilyName = p_family WHERE ID = p_rid;
    UPDATE REFEREE SET Country = p_country, ConfederationCode = p_conf_code, ConfederationName = p_conf_name WHERE ID = p_rid;
    RAISE NOTICE 'Referee % updated successfully.', p_rid;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_referee_delete(p_rid VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM REFEREE WHERE ID = p_rid;
    DELETE FROM PERSON WHERE ID = p_rid;
    RAISE NOTICE 'Referee % deleted successfully.', p_rid;
END;
$$;

-- EVENT
CREATE OR REPLACE PROCEDURE sp_event_insert(p_eid VARCHAR, p_minute INT, p_etype TEXT, p_match_id VARCHAR, p_player_id VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO MATCH_EVENT (MatchEventID, Minute, EventType, MatchID, ID)
    VALUES (p_eid, p_minute, p_etype, p_match_id, p_player_id);
    RAISE NOTICE 'Event % inserted successfully.', p_eid;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_event_delete(p_eid VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM MATCH_EVENT WHERE MatchEventID = p_eid;
    RAISE NOTICE 'Event % deleted successfully.', p_eid;
END;
$$;

-- ====================================================================
-- 13. STAGE 4 — ANONYMOUS BLOCKS (create_bet_print_payout, crowd_wisdom)
-- Note: these should be run AFTER data is loaded
-- ====================================================================

-- Data population helpers (to run after importing data):
-- CALL create_user('John Doe', 'john@example.com', 1000);
-- CALL create_odd(global_match_id, 2.5, 3.0, 2.8);
-- CALL create_bet(user_id, global_match_id, 100, 'Home');
-- CALL Mass_Update_Stage_Odds('Group Stage', 1.2);
