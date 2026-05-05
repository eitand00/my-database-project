-- ============================================
-- VIEW MATCHES WITH REAL DATA (Events + Stats)
-- ============================================

-- Find a match that has both events AND player stats
SELECT 
  m.MatchID,
  m.MatchDate,
  m.Stage,
  ht.CountryName AS HomeTeam,
  at.CountryName AS AwayTeam,
  s.Name AS StadiumName,
  s.City,
  p.Name AS RefereeName,
  COUNT(DISTINCT me.MatchID) AS TotalGoals,
  COUNT(DISTINCT pms.PlayerID) AS PlayersInMatch
FROM MATCHES m
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM at ON m.AwayTeamCode = at.TeamCode
JOIN STADIUM s ON m.StadiumID = s.StadiumID
JOIN REFEREE r ON m.RefereeID = r.ID
JOIN PERSON p ON r.ID = p.ID
LEFT JOIN MATCH_EVENT me ON m.MatchID = me.MatchID
LEFT JOIN PLAYER_MATCH_STATS pms ON m.MatchID = pms.MatchID
GROUP BY m.MatchID, m.MatchDate, m.Stage, ht.CountryName, at.CountryName, 
         s.Name, s.City, p.Name, r.Years_of_experience
HAVING COUNT(DISTINCT me.MatchID) > 0  -- Only matches WITH goals
ORDER BY m.MatchID
LIMIT 5;

-- ============================================
-- VIEW GOALS FROM A SPECIFIC MATCH
-- (Change MatchID to see different match)
-- ============================================

SELECT 
  me.MatchID,
  me.Minute,
  me.EventType,
  p.Name AS GoalScorerName,
  t.CountryName AS ScorerTeam,
  pl.Position
FROM MATCH_EVENT me
JOIN PLAYER pl ON me.PlayerID = pl.ID
JOIN PERSON p ON pl.ID = p.ID
JOIN TEAM t ON pl.TeamCode = t.TeamCode
WHERE me.MatchID = 1
ORDER BY me.Minute;

-- ============================================
-- VIEW PLAYER STATS FROM A SPECIFIC MATCH
-- ============================================

SELECT 
  pms.MatchID,
  p.Name AS PlayerName,
  t.CountryName AS PlayerTeam,
  pl.Position,
  pms.MinutesPlayed,
  pms.DistanceCovered
FROM PLAYER_MATCH_STATS pms
JOIN PLAYER pl ON pms.PlayerID = pl.ID
JOIN PERSON p ON pl.ID = p.ID
JOIN TEAM t ON pl.TeamCode = t.TeamCode
WHERE pms.MatchID = 1
ORDER BY pms.MinutesPlayed DESC;
