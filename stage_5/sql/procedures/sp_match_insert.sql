CREATE OR REPLACE PROCEDURE sp_match_insert(
  p_mid INT, p_date DATE, p_stage VARCHAR, p_tournament VARCHAR,
  p_time TIME, p_stadium INT, p_home VARCHAR, p_guest VARCHAR, p_referee INT
) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO MATCH (MatchID, MatchDate, Stage, Tournament, MatchTime, StadiumID, HomeTeamCode, GuestTeamCode, RefereeID)
  VALUES (p_mid, p_date, p_stage, p_tournament, p_time, p_stadium, p_home, p_guest, p_referee);
END $$;
