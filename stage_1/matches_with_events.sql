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
  p.GivenName || ' ' || p.FamilyName AS RefereeName,
  COUNT(DISTINCT me.MatchID) AS TotalGoals,
  COUNT(DISTINCT pms.PlayerID) AS PlayersInMatch
FROM MATCH m
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM at ON m.AwayTeamCode = at.TeamCode
JOIN STADIUM s ON m.StadiumID = s.StadiumID
JOIN REFEREE r ON m.RefereeID = r.ID
JOIN PERSON p ON r.ID = p.ID
LEFT JOIN MATCH_EVENT me ON m.MatchID = me.MatchID
LEFT JOIN PLAYER_MATCH_STATS pms ON m.MatchID = pms.MatchID
GROUP BY m.MatchID, m.MatchDate, m.Stage, ht.CountryName, at.CountryName, 
         s.Name, s.City, p.Name, r.Country
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
  p.GivenName || ' ' || p.FamilyName AS GoalScorerName,
  t.CountryName AS ScorerTeam,
  pms.Position
FROM MATCH_EVENT me
JOIN PLAYER pl ON me.PlayerID = pl.ID
JOIN PERSON p ON pl.ID = p.ID
JOIN TEAM t ON pl.TeamCode = t.TeamCode
JOIN PLAYER_MATCH_STATS pms ON me.MatchID = pms.MatchID AND me.PlayerID = pms.PlayerID
WHERE me.MatchID = 'M-1970-01'
ORDER BY me.Minute;

-- ============================================
-- VIEW PLAYER STATS FROM A SPECIFIC MATCH
-- ============================================

SELECT 
  pms.MatchID,
  p.GivenName || ' ' || p.FamilyName AS PlayerName,
  t.CountryName AS PlayerTeam,
  pms.Position,
  pms.ShirtNumber
FROM PLAYER_MATCH_STATS pms
JOIN PLAYER pl ON pms.PlayerID = pl.ID
JOIN PERSON p ON pl.ID = p.ID
JOIN TEAM t ON pl.TeamCode = t.TeamCode
WHERE pms.MatchID = 'M-1970-01'
ORDER BY pms.ShirtNumber;
