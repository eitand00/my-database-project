CREATE OR REPLACE VIEW vw_high_scoring_matches AS
SELECT m.MatchID,
  EXTRACT(DAY FROM m.MatchDate) || '/' || EXTRACT(MONTH FROM m.MatchDate) AS MatchDate,
  EXTRACT(YEAR FROM m.MatchDate) AS MatchYear, m.Stage,
  ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam, gc.TotalGoals
FROM MATCH m
JOIN (SELECT MatchID, COUNT(MatchEventID) AS TotalGoals
  FROM MATCH_EVENT WHERE EventType = 'Goal'
  GROUP BY MatchID HAVING COUNT(MatchEventID) > 3) gc ON m.MatchID = gc.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
WHERE EXTRACT(YEAR FROM m.MatchDate) = 2018
ORDER BY gc.TotalGoals DESC;

CREATE OR REPLACE VIEW vw_big_stadiums_red_cards AS
SELECT DISTINCT s.Name AS StadiumName, s.City AS StadiumCity,
  s.Capacity, m.MatchDate, m.Stage, m.Tournament
FROM STADIUM s JOIN MATCH m ON s.StadiumID = m.StadiumID
WHERE s.Capacity >= 60000
AND EXISTS (SELECT 1 FROM MATCH_EVENT me
  WHERE me.MatchID = m.MatchID AND me.EventType = 'Red Card');

CREATE OR REPLACE VIEW vw_team_goals_analysis AS
SELECT t.CountryName AS Team, COUNT(me.MatchEventID) AS TotalGoals,
  MIN(me.Minute) AS FastestGoal, MAX(me.Minute) AS LatestGoal
FROM TEAM t JOIN PLAYER pl ON t.TeamCode = pl.TeamCode
JOIN MATCH_EVENT me ON pl.ID = me.ID
WHERE LOWER(me.EventType) = 'goal'
GROUP BY t.TeamCode, t.CountryName
HAVING COUNT(me.MatchEventID) > 2
ORDER BY TotalGoals DESC;
