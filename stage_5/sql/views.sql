CREATE OR REPLACE VIEW WorldCup_Team_Performance_View AS
SELECT 
    t.TeamCode,
    t.CountryName AS Team_Name,
    t.ConfederationName AS Confederation,
    COUNT(DISTINCT m.MatchID) AS Total_Tournament_Matches,
    STRING_AGG(DISTINCT m.Stage, ', ') AS Tournament_Stages_Reached,
    COUNT(DISTINCT CASE WHEN me.EventType = 'Goal' AND me.ID IN 
        (SELECT ID FROM PLAYER WHERE TeamCode = t.TeamCode) 
        THEN me.MatchEventID END) AS Total_Goals_Scored,
    COUNT(DISTINCT CASE WHEN me.EventType = 'Goal' AND me.ID IN 
        (SELECT ID FROM PLAYER WHERE TeamCode = t.TeamCode) 
        THEN me.ID END) AS Different_Goal_Scorers,
    COUNT(DISTINCT pms.PlayerID) AS Total_Different_Players_Used,
    COUNT(DISTINCT CASE WHEN pms.Position = 'Goalkeeper' THEN pms.PlayerID END) AS Goalkeepers_Used,
    COUNT(DISTINCT CASE WHEN pms.Position = 'Defender' THEN pms.PlayerID END) AS Defenders_Used,
    COUNT(DISTINCT CASE WHEN pms.Position = 'Midfielder' THEN pms.PlayerID END) AS Midfielders_Used,
    COUNT(DISTINCT CASE WHEN pms.Position = 'Forward' THEN pms.PlayerID END) AS Forwards_Used,
    STRING_AGG(DISTINCT s.Name, ' | ') AS Stadiums_Played_In,
    ROUND(AVG(s.Capacity)::NUMERIC, 0) AS Average_Stadium_Capacity
FROM TEAM t
LEFT JOIN MATCH m ON (t.TeamCode = m.HomeTeamCode OR t.TeamCode = m.GuestTeamCode)
LEFT JOIN PLAYER_MATCH_STATS pms ON m.MatchID = pms.MatchID 
    AND pms.PlayerID IN (SELECT ID FROM PLAYER WHERE TeamCode = t.TeamCode)
LEFT JOIN MATCH_EVENT me ON m.MatchID = me.MatchID AND me.EventType = 'Goal'
LEFT JOIN STADIUM s ON m.StadiumID = s.StadiumID
GROUP BY t.TeamCode, t.CountryName, t.ConfederationName
ORDER BY Total_Tournament_Matches DESC, Total_Goals_Scored DESC;


CREATE OR REPLACE VIEW Match_Odds_Analysis_View AS
SELECT
    m.MatchID,
    m.MatchDate,
    m.Stage,
    ht.CountryName AS Home_Team,
    gt.CountryName AS Away_Team,
    s.Name AS Stadium,
    s.Capacity AS Stadium_Capacity,
    o.home_win_odd,
    o.draw_odd,
    o.away_win_odd,
    SUM(CASE WHEN me.EventType = 'Goal' AND me.ID IN 
        (SELECT ID FROM PLAYER WHERE TeamCode = m.HomeTeamCode) THEN 1 ELSE 0 END) AS Home_Goals,
    SUM(CASE WHEN me.EventType = 'Goal' AND me.ID IN 
        (SELECT ID FROM PLAYER WHERE TeamCode = m.GuestTeamCode) THEN 1 ELSE 0 END) AS Away_Goals,
    SUM(CASE WHEN me.EventType = 'Goal' THEN 1 ELSE 0 END) AS Total_Goals,
    CASE 
        WHEN o.home_win_odd < o.draw_odd AND o.home_win_odd < o.away_win_odd THEN 'Home'
        WHEN o.draw_odd < o.home_win_odd AND o.draw_odd < o.away_win_odd THEN 'Draw'
        ELSE 'Away'
    END AS Bookmaker_Favorite,
    CASE 
        WHEN SUM(CASE WHEN me.EventType = 'Goal' AND me.ID IN 
            (SELECT ID FROM PLAYER WHERE TeamCode = m.HomeTeamCode) THEN 1 ELSE 0 END) > 
             SUM(CASE WHEN me.EventType = 'Goal' AND me.ID IN 
            (SELECT ID FROM PLAYER WHERE TeamCode = m.GuestTeamCode) THEN 1 ELSE 0 END)
        THEN 'Home'
        WHEN SUM(CASE WHEN me.EventType = 'Goal' AND me.ID IN 
            (SELECT ID FROM PLAYER WHERE TeamCode = m.HomeTeamCode) THEN 1 ELSE 0 END) = 
             SUM(CASE WHEN me.EventType = 'Goal' AND me.ID IN 
            (SELECT ID FROM PLAYER WHERE TeamCode = m.GuestTeamCode) THEN 1 ELSE 0 END)
        THEN 'Draw'
        ELSE 'Away'
    END AS Actual_Result,
    CASE 
        WHEN o.home_win_odd < o.draw_odd AND o.home_win_odd < o.away_win_odd AND 
             SUM(CASE WHEN me.EventType = 'Goal' AND me.ID IN 
            (SELECT ID FROM PLAYER WHERE TeamCode = m.HomeTeamCode) THEN 1 ELSE 0 END) > 
             SUM(CASE WHEN me.EventType = 'Goal' AND me.ID IN 
            (SELECT ID FROM PLAYER WHERE TeamCode = m.GuestTeamCode) THEN 1 ELSE 0 END)
        THEN 'Favorite Won'
        WHEN o.draw_odd < o.home_win_odd AND o.draw_odd < o.away_win_odd AND 
             SUM(CASE WHEN me.EventType = 'Goal' AND me.ID IN 
            (SELECT ID FROM PLAYER WHERE TeamCode = m.HomeTeamCode) THEN 1 ELSE 0 END) = 
             SUM(CASE WHEN me.EventType = 'Goal' AND me.ID IN 
            (SELECT ID FROM PLAYER WHERE TeamCode = m.GuestTeamCode) THEN 1 ELSE 0 END)
        THEN 'Favorite Won'
        WHEN o.away_win_odd < o.home_win_odd AND o.away_win_odd < o.draw_odd AND 
             SUM(CASE WHEN me.EventType = 'Goal' AND me.ID IN 
            (SELECT ID FROM PLAYER WHERE TeamCode = m.GuestTeamCode) THEN 1 ELSE 0 END) > 
             SUM(CASE WHEN me.EventType = 'Goal' AND me.ID IN 
            (SELECT ID FROM PLAYER WHERE TeamCode = m.HomeTeamCode) THEN 1 ELSE 0 END)
        THEN 'Favorite Won'
        ELSE 'Upset / Draw'
    END AS Favorite_Result
FROM MATCH m
JOIN GLOBAL_MATCH gm ON gm.WCMatchID = m.MatchID
JOIN odds o ON gm.GlobalMatchID = o.global_match_id
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
LEFT JOIN STADIUM s ON m.StadiumID = s.StadiumID
LEFT JOIN MATCH_EVENT me ON m.MatchID = me.MatchID AND me.EventType = 'Goal'
GROUP BY m.MatchID, m.MatchDate, m.Stage, ht.CountryName, gt.CountryName, 
         s.Name, s.Capacity, o.home_win_odd, o.draw_odd, o.away_win_odd;