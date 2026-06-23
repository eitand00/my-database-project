CREATE OR REPLACE VIEW vw_team_goals_analysis AS
SELECT t.CountryName AS Team, COUNT(me.MatchEventID) AS TotalGoals,
  MIN(me.Minute) AS FastestGoal, MAX(me.Minute) AS LatestGoal
FROM TEAM t JOIN PLAYER pl ON t.TeamCode = pl.TeamCode
JOIN MATCH_EVENT me ON pl.ID = me.ID
WHERE LOWER(me.EventType) = 'goal'
GROUP BY t.TeamCode, t.CountryName
HAVING COUNT(me.MatchEventID) > 2
ORDER BY TotalGoals DESC;
