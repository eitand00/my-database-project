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

CREATE OR REPLACE VIEW vw_player_detail AS
SELECT p.ID, per.GivenName, per.FamilyName, per.WikipediaPage,
       p.DateOfBirth, t.CountryName AS Team, t.TeamCode
FROM PLAYER p
JOIN PERSON per ON p.ID = per.ID
JOIN TEAM t ON p.TeamCode = t.TeamCode;

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

CREATE OR REPLACE VIEW vw_player_match_stats AS
SELECT m.MatchDate, ht.CountryName AS Home, gt.CountryName AS Away,
       pms.Position, pms.ShirtNumber, pms.PlayerID
FROM PLAYER_MATCH_STATS pms
JOIN MATCH m ON pms.MatchID = m.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
ORDER BY m.MatchDate DESC;

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
