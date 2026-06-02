/* 
    This query retrieves detailed information about matches that had more than 3 goals scored in the year 2018. 
    It includes match details, team names, stadium information, and referee details.
*/

WITH GoalCounts AS (
    
    SELECT 
        MatchID, 
        COUNT(MatchEventID) AS TotalGoals
    FROM 
        MATCH_EVENT
    WHERE 
        EventType = 'Goal'
    GROUP BY 
        MatchID
    HAVING 
        COUNT(MatchEventID) > 3
)

SELECT 
    m.MatchID,
    m.MatchDate,
    m.MatchTime,
    m.Tournament,
    m.Stage,
    ht.CountryName AS HomeTeam,
    gt.CountryName AS GuestTeam,
    s.Name AS StadiumName,
    s.City AS StadiumCity,
    s.Country AS StadiumCountry,
    p.GivenName AS RefereeGivenName,
    p.FamilyName AS RefereeFamilyName,
    gc.TotalGoals
FROM 
    MATCH m
JOIN 
    GoalCounts gc ON m.MatchID = gc.MatchID
LEFT JOIN 
    TEAM ht ON m.HomeTeamCode = ht.TeamCode
LEFT JOIN 
    TEAM gt ON m.GuestTeamCode = gt.TeamCode
LEFT JOIN 
    STADIUM s ON m.StadiumID = s.StadiumID
LEFT JOIN 
    PERSON p ON m.RefereeID = p.ID
WHERE 
    m.MatchDate >= '2018-01-01' AND m.MatchDate <= '2018-12-31';




