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
