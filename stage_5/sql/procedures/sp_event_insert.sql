CREATE OR REPLACE PROCEDURE sp_event_insert(
  p_eid INT, p_minute VARCHAR, p_etype VARCHAR, p_match_id INT, p_player_id INT
) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO MATCH_EVENT (MatchEventID, Minute, EventType, MatchID, ID)
  VALUES (p_eid, p_minute, p_etype, p_match_id, p_player_id);
END $$;
