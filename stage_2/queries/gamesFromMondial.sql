/* 
    This query retrieves detailed information about matches that had more than 3 goals scored in the year 2018. 
    It includes match details, team names, stadium information, and referee details.
*/

-- query 1.1 : Retrieve matches with more than 3 goals in 2018 (more efficient)
WITH GoalCounts AS (
    SELECT 
        MatchID, 
        COUNT(MatchEventID) AS TotalGoals
    FROM MATCH_EVENT
    WHERE EventType = 'Goal'
    GROUP BY MatchID
    HAVING COUNT(MatchEventID) > 3
)
SELECT 
    m.MatchID,
    EXTRACT(DAY FROM m.MatchDate) || '/' || EXTRACT(MONTH FROM m.MatchDate) AS MatchDayAndMonth,
    EXTRACT(YEAR FROM m.MatchDate) AS MatchYear,
    m.Stage,
    ht.CountryName AS HomeTeam,
    gt.CountryName AS GuestTeam,
    gc.TotalGoals
FROM MATCH m
JOIN GoalCounts gc ON m.MatchID = gc.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
WHERE EXTRACT(YEAR FROM m.MatchDate) = 2018
ORDER BY gc.TotalGoals DESC;


-- query 1.2 : Retrieve matches with more than 3 goals in 2018 (less efficient)
SELECT 
    m.MatchID,
    EXTRACT(DAY FROM m.MatchDate) || '/' || EXTRACT(MONTH FROM m.MatchDate) AS MatchDayAndMonth,
    EXTRACT(YEAR FROM m.MatchDate) AS MatchYear,
    m.Stage,
    ht.CountryName AS HomeTeam,
    gt.CountryName AS GuestTeam,
    (SELECT COUNT(MatchEventID) FROM MATCH_EVENT me WHERE me.MatchID = m.MatchID AND me.EventType = 'Goal') AS TotalGoals
FROM MATCH m
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
WHERE EXTRACT(YEAR FROM m.MatchDate) = 2018
  AND (SELECT COUNT(MatchEventID) FROM MATCH_EVENT me WHERE me.MatchID = m.MatchID AND me.EventType = 'Goal') > 3
ORDER BY TotalGoals DESC;


-- query 2 : Retrieve stadiums with capacity >= 60000 that hosted matches with red cards
SELECT DISTINCT
    s.Name AS StadiumName,
    s.City AS StadiumCity,
    s.Capacity,
    m.MatchDate,
    m.Stage,
    m.Tournament
FROM STADIUM s
JOIN MATCH m ON s.StadiumID = m.StadiumID
WHERE s.Capacity >= 60000
  AND EXISTS (
      SELECT 1 
      FROM MATCH_EVENT me 
      WHERE me.MatchID = m.MatchID AND me.EventType = 'Red Card'
  );


-- query 2 : Retrieve stadiums with capacity >= 60000 that hosted matches with red cards (alternative using IN)
SELECT DISTINCT
    s.Name AS StadiumName,
    s.City AS StadiumCity,
    s.Capacity,
    m.MatchDate,
    m.Stage,
    m.Tournament
FROM STADIUM s
JOIN MATCH m ON s.StadiumID = m.StadiumID
WHERE s.Capacity >= 60000
  AND m.MatchID IN (
      SELECT MatchID 
      FROM MATCH_EVENT 
      WHERE EventType = 'Red Card'
  );


-- query 3 : Retrieve referees who gave more than 4 yellow cards in matches during the 2018 tournament
  SELECT 
    p.GivenName || ' ' || p.FamilyName AS RefereeName,
    r.Country AS RefereeCountry,
    m.Stage,
    EXTRACT(YEAR FROM m.MatchDate) AS TournamentYear,
    COUNT(me.MatchEventID) AS YellowCardsGiven
FROM PERSON p
JOIN REFEREE r ON p.ID = r.ID
JOIN MATCH m ON r.ID = m.RefereeID
JOIN MATCH_EVENT me ON m.MatchID = me.MatchID
WHERE me.EventType = 'Yellow Card' 
  AND EXTRACT(YEAR FROM m.MatchDate) = 2018
GROUP BY p.ID, p.GivenName, p.FamilyName, r.Country, m.MatchID, m.Stage, m.MatchDate
HAVING COUNT(me.MatchEventID) > 4
ORDER BY YellowCardsGiven DESC;


-- query 3 : Retrieve referees who gave more than 4 yellow cards in matches during the 2018 tournament (alternative using subquery)
SELECT 
    p.GivenName || ' ' || p.FamilyName AS RefereeName,
    r.Country AS RefereeCountry,
    m.Stage,
    EXTRACT(YEAR FROM m.MatchDate) AS TournamentYear,
    (SELECT COUNT(MatchEventID) FROM MATCH_EVENT me WHERE me.MatchID = m.MatchID AND me.EventType = 'Yellow Card') AS YellowCardsGiven
FROM PERSON p
JOIN REFEREE r ON p.ID = r.ID
JOIN MATCH m ON r.ID = m.RefereeID
WHERE EXTRACT(YEAR FROM m.MatchDate) = 2018
  AND (SELECT COUNT(MatchEventID) FROM MATCH_EVENT me WHERE me.MatchID = m.MatchID AND me.EventType = 'Yellow Card') > 4
ORDER BY YellowCardsGiven DESC;


-- query 4 : Retrieve players who scored goals and received cards in the same match during the 2018 tournament
SELECT 
    p.GivenName || ' ' || p.FamilyName AS PlayerName,
    t.CountryName AS NationalTeam,
    ht.CountryName || ' vs ' || gt.CountryName AS MatchUp,
    m.Stage AS MatchStage,
    MIN(me_goal.Minute) AS GoalMinute,
    MAX(me_card.Minute) AS CardMinute
FROM PERSON p
JOIN PLAYER pl ON p.ID = pl.ID
JOIN TEAM t ON pl.TeamCode = t.TeamCode
JOIN MATCH_EVENT me_goal ON pl.ID = me_goal.ID 
JOIN MATCH_EVENT me_card ON pl.ID = me_card.ID AND me_goal.MatchID = me_card.MatchID
JOIN MATCH m ON me_goal.MatchID = m.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
WHERE me_goal.EventType = 'Goal' 
  AND me_card.EventType IN ('Yellow Card', 'Red Card')
  AND EXTRACT(YEAR FROM m.MatchDate) = 2018
GROUP BY p.ID, p.GivenName, p.FamilyName, t.CountryName, ht.CountryName, gt.CountryName, m.Stage
ORDER BY GoalMinute ASC;


-- query 4 : Retrieve players who scored goals and received cards in the same match during the 2018 tournament (alternative using EXISTS)
SELECT DISTINCT
    p.GivenName || ' ' || p.FamilyName AS PlayerName,
    t.CountryName AS NationalTeam,
    ht.CountryName || ' vs ' || gt.CountryName AS MatchUp,
    m.Stage AS MatchStage,
    
    (SELECT MIN(Minute) FROM MATCH_EVENT me2 WHERE me2.ID = p.ID AND me2.MatchID = m.MatchID AND me2.EventType = 'Goal') AS GoalMinute,
    (SELECT MAX(Minute) FROM MATCH_EVENT me3 WHERE me3.ID = p.ID AND me3.MatchID = m.MatchID AND me3.EventType IN ('Yellow Card', 'Red Card')) AS CardMinute
    
FROM PERSON p
JOIN PLAYER pl ON p.ID = pl.ID
JOIN TEAM t ON pl.TeamCode = t.TeamCode
JOIN MATCH_EVENT me ON p.ID = me.ID
JOIN MATCH m ON me.MatchID = m.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
WHERE EXTRACT(YEAR FROM m.MatchDate) = 2018
  AND (SELECT COUNT(MatchEventID) FROM MATCH_EVENT me4 WHERE me4.ID = p.ID AND me4.MatchID = m.MatchID AND me4.EventType = 'Goal') > 0
  AND (SELECT COUNT(MatchEventID) FROM MATCH_EVENT me5 WHERE me5.ID = p.ID AND me5.MatchID = m.MatchID AND me5.EventType IN ('Yellow Card', 'Red Card')) > 0
ORDER BY GoalMinute ASC;


-- query 5 : Retrieve players born in 1990 who scored goals in the tournament, along with their birth date and national team
SELECT 
    p.GivenName || ' ' || p.FamilyName AS PlayerName,
    EXTRACT(DAY FROM pl.DateOfBirth) || '/' || EXTRACT(MONTH FROM pl.DateOfBirth) || '/' || EXTRACT(YEAR FROM pl.DateOfBirth) AS BirthDate,
    t.CountryName AS NationalTeam,
    m.Stage,
    me.Minute AS GoalMinute,
    m.Tournament
FROM PERSON p
JOIN PLAYER pl ON p.ID = pl.ID
JOIN TEAM t ON pl.TeamCode = t.TeamCode
JOIN MATCH_EVENT me ON pl.ID = me.ID
JOIN MATCH m ON me.MatchID = m.MatchID
WHERE me.EventType = 'Goal'
  AND EXTRACT(YEAR FROM pl.DateOfBirth) = 1990
ORDER BY pl.DateOfBirth ASC;


-- query 6 : retrieve matches where the guest team won in the knockout stages, along with the final score and match details
WITH match_scores AS (
    SELECT 
        m.matchid,
        SUM(CASE WHEN pl.teamcode = m.hometeamcode THEN 1 ELSE 0 END) AS home_goals,
        SUM(CASE WHEN pl.teamcode = m.guestteamcode THEN 1 ELSE 0 END) AS guest_goals
    FROM match m
    JOIN match_event me ON m.matchid = me.matchid
    JOIN player pl ON me.id = pl.id
    WHERE LOWER(me.eventtype) = 'goal'
    GROUP BY m.matchid
)
SELECT 
    m.matchdate,
    m.stage,
    ht.countryname AS home_team,
    gt.countryname AS guest_team,
    ms.home_goals || ' - ' || ms.guest_goals AS final_score
FROM match m
JOIN match_scores ms ON m.matchid = ms.matchid
JOIN team ht ON m.hometeamcode = ht.teamcode
JOIN team gt ON m.guestteamcode = gt.teamcode
WHERE ms.guest_goals > ms.home_goals
  AND LOWER(m.stage) IN ('semi-final', 'quarter-final', 'round of 16', 'final', 'semi-finals', 'quarter-finals')
ORDER BY m.matchdate DESC;


-- query 7 : Retrieve players who received a card in a match, along with the type of card, match date, and referee details
SELECT 
    p_player.givenname || ' ' || p_player.familyname AS player_name,
    t.countryname AS player_team,
    me.eventtype AS card_type,
    EXTRACT(DAY FROM m.matchdate) || '/' || EXTRACT(MONTH FROM m.matchdate) || '/' || EXTRACT(YEAR FROM m.matchdate) AS match_date,
    p_ref.givenname || ' ' || p_ref.familyname AS referee_name
FROM match_event me
JOIN player pl ON me.id = pl.id
JOIN person p_player ON pl.id = p_player.id
JOIN team t ON pl.teamcode = t.teamcode
JOIN match m ON me.matchid = m.matchid
JOIN referee r ON m.refereeid = r.id
JOIN person p_ref ON r.id = p_ref.id
WHERE LOWER(me.eventtype) LIKE '%card%'
ORDER BY m.matchdate DESC;


-- query 8 : Retrieve teams that scored more than 2 goals in the tournament, along with the total goals scored and the minutes of the first and last goals
SELECT 
    t.teamcode AS team_code,
    t.countryname AS country_name,
    COUNT(me.matcheventid) AS total_goals_scored,
    MIN(me.minute) AS fastest_goal_minute,
    MAX(me.minute) AS latest_goal_minute
FROM team t
JOIN player pl ON t.teamcode = pl.teamcode
JOIN match_event me ON pl.id = me.id
WHERE LOWER(me.eventtype) = 'goal'
GROUP BY t.teamcode, t.countryname
HAVING COUNT(me.matcheventid) > 2
ORDER BY total_goals_scored DESC;


-- query 1 delete : Delete match events for matches that were friendlies before 2014    
DELETE FROM match_event
WHERE matchid IN (
    SELECT matchid 
    FROM match 
    WHERE LOWER(stage) = 'friendly' AND EXTRACT(YEAR FROM matchdate) < 2014
);


-- query 2 delete : Delete player match stats for players who played as 'Unknown' or NULL position
DELETE FROM player_match_stats
WHERE position IS NULL OR LOWER(position) = 'unknown';



-- query 3 delete : Delete matches that were played in stadiums with a capacity less than 10000 and that do not have any match events recorded
DELETE FROM stadium
WHERE capacity < 10000 
  AND stadiumid NOT IN (SELECT DISTINCT stadiumid FROM match);


-- query 1 update : Update the capacity of stadiums in rio by increasing it by 10%
UPDATE stadium
SET capacity = capacity * 1.10
WHERE LOWER(city) = 'rio de janeiro';


-- query 2 update : Update the stage of matches that were played to be in lowercase
UPDATE match
SET stage = LOWER(stage);


-- query 3 update : update capacity of stadiums with more than 50000 seats by adding 500 to their capacity
UPDATE stadium
SET capacity = capacity + 500
WHERE capacity > 50000;