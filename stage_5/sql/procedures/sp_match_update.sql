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
