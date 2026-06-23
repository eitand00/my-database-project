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
