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

CREATE OR REPLACE VIEW vw_match_events AS
SELECT me.MatchEventID, me.Minute, me.EventType,
       per.GivenName || ' ' || per.FamilyName AS PlayerName,
       me.MatchID
FROM MATCH_EVENT me
JOIN PLAYER pl ON me.ID = pl.ID
JOIN PERSON per ON pl.ID = per.ID
ORDER BY me.Minute ASC;

CREATE OR REPLACE VIEW vw_match_player_stats AS
SELECT per.GivenName || ' ' || per.FamilyName AS PlayerName,
       pms.Position, pms.ShirtNumber, pms.MatchID
FROM PLAYER_MATCH_STATS pms
JOIN PLAYER pl ON pms.PlayerID = pl.ID
JOIN PERSON per ON pl.ID = per.ID
ORDER BY pms.ShirtNumber;

CREATE OR REPLACE VIEW vw_tournaments AS
SELECT DISTINCT Tournament
FROM MATCH
ORDER BY Tournament;

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
