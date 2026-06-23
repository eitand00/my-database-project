CREATE OR REPLACE VIEW vw_big_stadiums_red_cards AS
SELECT DISTINCT s.Name AS StadiumName, s.City AS StadiumCity,
  s.Capacity, m.MatchDate, m.Stage, m.Tournament
FROM STADIUM s JOIN MATCH m ON s.StadiumID = m.StadiumID
WHERE s.Capacity >= 60000
AND EXISTS (SELECT 1 FROM MATCH_EVENT me
  WHERE me.MatchID = m.MatchID AND me.EventType = 'Red Card');
