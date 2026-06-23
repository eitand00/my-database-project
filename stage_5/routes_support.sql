-- ================================================================
-- Views & Stored Procedures for Route Layer
-- Replaces hardcoded SQL in Python route modules
-- ================================================================

-- ============================
-- VIEWS for reading data
-- ============================

DROP VIEW IF EXISTS vw_dashboard_counts, vw_teams_list, vw_team_detail, vw_team_players,
    vw_team_matches, vw_players_list, vw_player_detail, vw_player_events,
    vw_player_match_stats, vw_matches_list, vw_match_detail, vw_match_events,
    vw_match_player_stats, vw_stadiums_list, vw_referees_list, vw_events_list,
    vw_teams_short, vw_stadiums_short, vw_referees_short, vw_tournaments CASCADE;

-- Dashboard counts
CREATE OR REPLACE VIEW vw_dashboard_counts AS
SELECT
  (SELECT COUNT(*) FROM MATCH) AS match_count,
  (SELECT COUNT(*) FROM TEAM) AS team_count,
  (SELECT COUNT(*) FROM PLAYER) AS player_count,
  (SELECT COUNT(*) FROM STADIUM) AS stadium_count,
  (SELECT COUNT(*) FROM MATCH_EVENT) AS event_count;

-- Teams list (with player/match counts)
CREATE OR REPLACE VIEW vw_teams_list AS
SELECT t.TeamCode, t.CountryName, t.ConfederationName,
       COUNT(DISTINCT p.ID) AS PlayerCount,
       COUNT(DISTINCT m.MatchID) AS MatchCount
FROM TEAM t LEFT JOIN PLAYER p ON t.TeamCode = p.TeamCode
LEFT JOIN MATCH m ON t.TeamCode IN (m.HomeTeamCode, m.GuestTeamCode)
GROUP BY t.TeamCode, t.CountryName, t.ConfederationName
ORDER BY t.CountryName;

-- Team detail (full row, same columns as TEAM table)
CREATE OR REPLACE VIEW vw_team_detail AS
SELECT * FROM TEAM;

-- Players by team
CREATE OR REPLACE VIEW vw_team_players AS
SELECT p.ID, per.GivenName || ' ' || per.FamilyName AS FullName,
       p.DateOfBirth, p.TeamCode
FROM PLAYER p JOIN PERSON per ON p.ID = per.ID
ORDER BY per.FamilyName;

-- Matches by team
CREATE OR REPLACE VIEW vw_team_matches AS
SELECT m.MatchID, m.MatchDate, m.Stage,
       ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
       m.HomeTeamCode, m.GuestTeamCode
FROM MATCH m
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
ORDER BY m.MatchDate DESC LIMIT 20;

-- Players list
CREATE OR REPLACE VIEW vw_players_list AS
SELECT p.ID, per.GivenName, per.FamilyName, p.DateOfBirth,
       t.CountryName AS Team, COUNT(me.MatchEventID) AS Events
FROM PLAYER p
JOIN PERSON per ON p.ID = per.ID
JOIN TEAM t ON p.TeamCode = t.TeamCode
LEFT JOIN MATCH_EVENT me ON p.ID = me.ID
GROUP BY p.ID, per.GivenName, per.FamilyName, p.DateOfBirth, t.CountryName
ORDER BY per.FamilyName
LIMIT 200;

-- Player detail
CREATE OR REPLACE VIEW vw_player_detail AS
SELECT p.ID, per.GivenName, per.FamilyName, per.WikipediaPage,
       p.DateOfBirth, t.CountryName AS Team, t.TeamCode
FROM PLAYER p
JOIN PERSON per ON p.ID = per.ID
JOIN TEAM t ON p.TeamCode = t.TeamCode;

-- Player events
CREATE OR REPLACE VIEW vw_player_events AS
SELECT me.MatchEventID, me.Minute, me.EventType,
       m.MatchDate, m.Stage,
       ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
       me.ID AS PlayerID
FROM MATCH_EVENT me
JOIN MATCH m ON me.MatchID = m.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
ORDER BY m.MatchDate DESC;

-- Player match stats
CREATE OR REPLACE VIEW vw_player_match_stats AS
SELECT m.MatchDate, ht.CountryName AS Home, gt.CountryName AS Away,
       pms.Position, pms.ShirtNumber, pms.PlayerID
FROM PLAYER_MATCH_STATS pms
JOIN MATCH m ON pms.MatchID = m.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
ORDER BY m.MatchDate DESC;

-- Matches list
CREATE OR REPLACE VIEW vw_matches_list AS
SELECT m.MatchID, m.MatchDate, m.Stage, m.Tournament,
       ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
       s.Name AS Stadium,
       (SELECT COUNT(*) FROM MATCH_EVENT me WHERE me.MatchID = m.MatchID AND me.EventType = 'Goal') AS Goals
FROM MATCH m
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
JOIN STADIUM s ON m.StadiumID = s.StadiumID
ORDER BY m.MatchDate DESC
LIMIT 200;

-- Match detail (includes all m.* + joined names)
CREATE OR REPLACE VIEW vw_match_detail AS
SELECT m.*, s.Name AS StadiumName,
       ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
       per.GivenName || ' ' || per.FamilyName AS RefereeName
FROM MATCH m
JOIN STADIUM s ON m.StadiumID = s.StadiumID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
JOIN REFEREE r ON m.RefereeID = r.ID
JOIN PERSON per ON r.ID = per.ID;

-- Match events
CREATE OR REPLACE VIEW vw_match_events AS
SELECT me.MatchEventID, me.Minute, me.EventType,
       per.GivenName || ' ' || per.FamilyName AS PlayerName,
       me.MatchID
FROM MATCH_EVENT me
JOIN PLAYER pl ON me.ID = pl.ID
JOIN PERSON per ON pl.ID = per.ID
ORDER BY regexp_replace(me.Minute, '[+''].*$', '')::int ASC;

-- Match player stats
CREATE OR REPLACE VIEW vw_match_player_stats AS
SELECT per.GivenName || ' ' || per.FamilyName AS PlayerName,
       pms.Position, pms.ShirtNumber, pms.MatchID
FROM PLAYER_MATCH_STATS pms
JOIN PLAYER pl ON pms.PlayerID = pl.ID
JOIN PERSON per ON pl.ID = per.ID
ORDER BY pms.ShirtNumber;

-- Stadiums list
CREATE OR REPLACE VIEW vw_stadiums_list AS
SELECT s.StadiumID, s.Name, s.City, s.Capacity, s.Country,
       COUNT(DISTINCT m.MatchID) AS MatchesHosted
FROM STADIUM s LEFT JOIN MATCH m ON s.StadiumID = m.StadiumID
GROUP BY s.StadiumID, s.Name, s.City, s.Capacity, s.Country
ORDER BY s.Capacity DESC;

-- Referees list
CREATE OR REPLACE VIEW vw_referees_list AS
SELECT r.ID, per.GivenName || ' ' || per.FamilyName AS FullName,
       r.Country, r.ConfederationName,
       COUNT(DISTINCT m.MatchID) AS MatchesOfficiated,
       per.GivenName, per.FamilyName
FROM REFEREE r
JOIN PERSON per ON r.ID = per.ID
LEFT JOIN MATCH m ON r.ID = m.RefereeID
GROUP BY r.ID, per.GivenName, per.FamilyName, r.Country, r.ConfederationName
ORDER BY per.FamilyName;

-- Events list
CREATE OR REPLACE VIEW vw_events_list AS
SELECT me.MatchEventID, me.Minute, me.EventType,
       ht.CountryName || ' vs ' || gt.CountryName AS MatchName,
       per.GivenName || ' ' || per.FamilyName AS PlayerName,
       per.GivenName, per.FamilyName
FROM MATCH_EVENT me
JOIN MATCH m ON me.MatchID = m.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
JOIN PLAYER pl ON me.ID = pl.ID
JOIN PERSON per ON pl.ID = per.ID
ORDER BY me.MatchEventID
LIMIT 200;

-- Dropdown helpers
CREATE OR REPLACE VIEW vw_teams_short AS
SELECT TeamCode, CountryName FROM TEAM ORDER BY CountryName;

CREATE OR REPLACE VIEW vw_stadiums_short AS
SELECT StadiumID, Name FROM STADIUM ORDER BY Name;

CREATE OR REPLACE VIEW vw_referees_short AS
SELECT r.ID, per.GivenName || ' ' || per.FamilyName AS Name
FROM REFEREE r JOIN PERSON per ON r.ID = per.ID ORDER BY per.FamilyName;

CREATE OR REPLACE VIEW vw_tournaments AS
SELECT DISTINCT Tournament FROM MATCH ORDER BY Tournament;


-- ============================
-- PROCEDURES for CRUD operations
-- ============================

-- TEAM
CREATE OR REPLACE PROCEDURE sp_team_insert(
  p_code VARCHAR, p_country VARCHAR, p_conf_name VARCHAR,
  p_conf_code VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO TEAM (TeamCode, CountryName, ConfederationName, ConfederationCode, WikipediaPage)
  VALUES (p_code, p_country, p_conf_name, p_conf_code, p_wiki);
END $$;

CREATE OR REPLACE PROCEDURE sp_team_update(
  p_code VARCHAR, p_country VARCHAR, p_conf_name VARCHAR,
  p_conf_code VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  UPDATE TEAM SET CountryName=p_country, ConfederationName=p_conf_name,
                  ConfederationCode=p_conf_code, WikipediaPage=p_wiki
  WHERE TeamCode=p_code;
END $$;

CREATE OR REPLACE PROCEDURE sp_team_delete(p_code VARCHAR) LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM TEAM WHERE TeamCode = p_code;
END $$;

-- PLAYER (with PERSON)
CREATE OR REPLACE PROCEDURE sp_player_insert(
  p_id INT, p_given VARCHAR, p_family VARCHAR, p_wiki VARCHAR,
  p_dob DATE, p_team VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO PERSON (ID, GivenName, FamilyName, WikipediaPage)
  VALUES (p_id, p_given, p_family, p_wiki);
  INSERT INTO PLAYER (ID, DateOfBirth, TeamCode)
  VALUES (p_id, p_dob, p_team);
END $$;

CREATE OR REPLACE PROCEDURE sp_player_update(
  p_id INT, p_dob DATE, p_team VARCHAR,
  p_given VARCHAR, p_family VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  UPDATE PLAYER SET DateOfBirth=p_dob, TeamCode=p_team WHERE ID=p_id;
  UPDATE PERSON SET GivenName=p_given, FamilyName=p_family, WikipediaPage=p_wiki WHERE ID=p_id;
END $$;

CREATE OR REPLACE PROCEDURE sp_player_delete(p_id INT) LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM MATCH_EVENT WHERE ID = p_id;
  DELETE FROM PLAYER_MATCH_STATS WHERE PlayerID = p_id;
  DELETE FROM PLAYER WHERE ID = p_id;
  DELETE FROM PERSON WHERE ID = p_id;
END $$;

-- MATCH
CREATE OR REPLACE PROCEDURE sp_match_insert(
  p_mid INT, p_date DATE, p_stage VARCHAR, p_tournament VARCHAR,
  p_time TIME, p_stadium INT, p_home VARCHAR, p_guest VARCHAR, p_referee INT
) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO MATCH (MatchID, MatchDate, Stage, Tournament, MatchTime, StadiumID, HomeTeamCode, GuestTeamCode, RefereeID)
  VALUES (p_mid, p_date, p_stage, p_tournament, p_time, p_stadium, p_home, p_guest, p_referee);
END $$;

CREATE OR REPLACE PROCEDURE sp_match_update(
  p_mid INT, p_date DATE, p_stage VARCHAR, p_tournament VARCHAR,
  p_time TIME, p_stadium INT, p_home VARCHAR, p_guest VARCHAR, p_referee INT
) LANGUAGE plpgsql AS $$
BEGIN
  UPDATE MATCH SET MatchDate=p_date, Stage=p_stage, Tournament=p_tournament,
                   MatchTime=p_time, StadiumID=p_stadium, HomeTeamCode=p_home,
                   GuestTeamCode=p_guest, RefereeID=p_referee
  WHERE MatchID=p_mid;
END $$;

CREATE OR REPLACE PROCEDURE sp_match_delete(p_mid INT) LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM MATCH_EVENT WHERE MatchID = p_mid;
  DELETE FROM PLAYER_MATCH_STATS WHERE MatchID = p_mid;
  DELETE FROM MATCH WHERE MatchID = p_mid;
END $$;

-- STADIUM
CREATE OR REPLACE PROCEDURE sp_stadium_insert(
  p_sid INT, p_name VARCHAR, p_city VARCHAR, p_capacity INT, p_country VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO STADIUM (StadiumID, Name, City, Capacity, Country, WikipediaPage)
  VALUES (p_sid, p_name, p_city, p_capacity, p_country, p_wiki);
END $$;

CREATE OR REPLACE PROCEDURE sp_stadium_update(
  p_sid INT, p_name VARCHAR, p_city VARCHAR, p_capacity INT, p_country VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  UPDATE STADIUM SET Name=p_name, City=p_city, Capacity=p_capacity, Country=p_country, WikipediaPage=p_wiki
  WHERE StadiumID=p_sid;
END $$;

CREATE OR REPLACE PROCEDURE sp_stadium_delete(p_sid INT) LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM STADIUM WHERE StadiumID = p_sid;
END $$;

-- REFEREE (with PERSON)
CREATE OR REPLACE PROCEDURE sp_referee_insert(
  p_rid INT, p_country VARCHAR, p_conf_code VARCHAR, p_conf_name VARCHAR,
  p_given VARCHAR, p_family VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO PERSON (ID, GivenName, FamilyName, WikipediaPage)
  VALUES (p_rid, p_given, p_family, p_wiki);
  INSERT INTO REFEREE (ID, Country, ConfederationCode, ConfederationName)
  VALUES (p_rid, p_country, p_conf_code, p_conf_name);
END $$;

CREATE OR REPLACE PROCEDURE sp_referee_update(
  p_rid INT, p_country VARCHAR, p_conf_code VARCHAR, p_conf_name VARCHAR,
  p_given VARCHAR, p_family VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  UPDATE PERSON SET GivenName=p_given, FamilyName=p_family WHERE ID=p_rid;
  UPDATE REFEREE SET Country=p_country, ConfederationCode=p_conf_code, ConfederationName=p_conf_name WHERE ID=p_rid;
END $$;

CREATE OR REPLACE PROCEDURE sp_referee_delete(p_rid INT) LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM REFEREE WHERE ID = p_rid;
  DELETE FROM PERSON WHERE ID = p_rid;
END $$;

-- EVENT
CREATE OR REPLACE PROCEDURE sp_event_insert(
  p_eid INT, p_minute VARCHAR, p_etype VARCHAR, p_match_id INT, p_player_id INT
) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO MATCH_EVENT (MatchEventID, Minute, EventType, MatchID, ID)
  VALUES (p_eid, p_minute, p_etype, p_match_id, p_player_id);
END $$;

CREATE OR REPLACE PROCEDURE sp_event_delete(p_eid INT) LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM MATCH_EVENT WHERE MatchEventID = p_eid;
END $$;
