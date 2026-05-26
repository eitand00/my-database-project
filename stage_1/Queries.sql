-- Query 1.1: Retrieve all players with more than 3 goals in 2018
SELECT 
    p.Name AS PlayerName,
    t.CountryName AS NationalTeam,
    EXTRACT(YEAR FROM m.MatchDate) AS TournamentYear,
    COUNT(me.Minute) AS TotalGoals
FROM PERSON p
JOIN PLAYER pl ON p.ID = pl.ID
JOIN TEAM t ON pl.TeamCode = t.TeamCode
JOIN MATCH_EVENT me ON pl.ID = me.PlayerID
JOIN MATCHES m ON me.MatchID = m.MatchID
WHERE me.EventType = 'Goal' 
  AND EXTRACT(YEAR FROM m.MatchDate) = 2018
GROUP BY p.ID, p.Name, t.CountryName, EXTRACT(YEAR FROM m.MatchDate)
HAVING COUNT(me.Minute) >= 3 
ORDER BY TotalGoals DESC;

--query 1.2: Retrieve all players with more than 3 goals in 2018 less efficient
SELECT 
    p.Name AS PlayerName,
    t.CountryName AS NationalTeam,
    2018 AS TournamentYear,
    (SELECT COUNT(*) FROM MATCH_EVENT me JOIN MATCHES m ON me.MatchID = m.MatchID WHERE me.PlayerID = p.ID AND me.EventType = 'Goal' AND EXTRACT(YEAR FROM m.MatchDate) = 2018) AS TotalGoals
FROM PERSON p
JOIN PLAYER pl ON p.ID = pl.ID
JOIN TEAM t ON pl.TeamCode = t.TeamCode
WHERE (SELECT COUNT(*) FROM MATCH_EVENT me JOIN MATCHES m ON me.MatchID = m.MatchID WHERE me.PlayerID = p.ID AND me.EventType = 'Goal' AND EXTRACT(YEAR FROM m.MatchDate) = 2018) >= 3
ORDER BY TotalGoals DESC;

-- Query 2.1: Retrieve all matches in the knockout stage of the 2010 World Cup with more than 5 cards issued less efficient
SELECT 
    TO_CHAR(m.MatchDate, 'DD/MM/YYYY') AS ExactDate,
    EXTRACT(MONTH FROM m.MatchDate) AS MatchMonth,
    t_home.CountryName || ' vs ' || t_away.CountryName AS MatchUp,
    m.Stage,
    COUNT(me.Minute) AS TotalCards
FROM MATCHES m
JOIN TEAM t_home ON m.HomeTeamCode = t_home.TeamCode
JOIN TEAM t_away ON m.AwayTeamCode = t_away.TeamCode
JOIN MATCH_EVENT me ON m.MatchID = me.MatchID
WHERE me.EventType IN ('Yellow Card', 'Red Card', 'Second Yellow Card')
  AND EXTRACT(YEAR FROM m.MatchDate) = 2010
GROUP BY m.MatchID, m.MatchDate, t_home.CountryName, t_away.CountryName, m.Stage
HAVING COUNT(me.Minute) > 5
ORDER BY TotalCards DESC;

-- Query 2.2: Retrieve all matches in the knockout stage of the 2010 World Cup with more than 5 cards issued less efficient
SELECT 
    TO_CHAR(m.MatchDate, 'DD/MM/YYYY') AS ExactDate,
    EXTRACT(MONTH FROM m.MatchDate) AS MatchMonth,
    t_home.CountryName || ' vs ' || t_away.CountryName AS MatchUp,
    m.Stage,
    (SELECT COUNT(*) 
     FROM MATCH_EVENT me 
     WHERE me.MatchID = m.MatchID 
       AND me.EventType IN ('Yellow Card', 'Red Card', 'Second Yellow Card')) AS TotalCards
FROM MATCHES m
JOIN TEAM t_home ON m.HomeTeamCode = t_home.TeamCode
JOIN TEAM t_away ON m.AwayTeamCode = t_away.TeamCode
WHERE EXTRACT(YEAR FROM m.MatchDate) = 2018
  AND (SELECT COUNT(*) 
       FROM MATCH_EVENT me 
       WHERE me.MatchID = m.MatchID 
         AND me.EventType IN ('Yellow Card', 'Red Card', 'Second Yellow Card')) >= 6
ORDER BY TotalCards DESC;

-- Query 3.1: Retrieve all defenders and midfielders who scored at least 2 goals in the 2014 World Cup
SELECT 
    p.Name AS PlayerName,
    pl.Position,
    t.CountryName,
    COUNT(me.Minute) AS GoalsScored
FROM PERSON p
JOIN PLAYER pl ON p.ID = pl.ID
JOIN TEAM t ON pl.TeamCode = t.TeamCode
JOIN MATCH_EVENT me ON pl.ID = me.PlayerID
JOIN MATCHES m ON me.MatchID = m.MatchID
WHERE me.EventType = 'Goal' 
  AND pl.Position IN ('defender', 'midfielder')
  AND EXTRACT(YEAR FROM m.MatchDate) = 2014
GROUP BY p.ID, p.Name, pl.Position, t.CountryName
HAVING COUNT(me.Minute) >= 2
ORDER BY GoalsScored DESC;

-- Query 3.2: Retrieve all defenders and midfielders who scored at least 2 goals in the 2014 World Cup less efficient
SELECT p.Name AS PlayerName, pl.Position, t.CountryName, COUNT(me.Minute) AS GoalsScored
FROM PERSON p
JOIN PLAYER pl ON p.ID = pl.ID
JOIN TEAM t ON pl.TeamCode = t.TeamCode
JOIN MATCH_EVENT me ON pl.ID = me.PlayerID
JOIN MATCHES m ON me.MatchID = m.MatchID
WHERE pl.ID IN (
    SELECT PlayerID FROM MATCH_EVENT me2 JOIN MATCHES m2 ON me2.MatchID = m2.MatchID WHERE me2.EventType = 'Goal' AND EXTRACT(YEAR FROM m2.MatchDate) = 2018 GROUP BY PlayerID HAVING COUNT(*) >= 2
    INTERSECT
    SELECT ID FROM PLAYER WHERE Position IN ('defender', 'midfielder')
)
GROUP BY p.ID, p.Name, pl.Position, t.CountryName
ORDER BY GoalsScored DESC;

--