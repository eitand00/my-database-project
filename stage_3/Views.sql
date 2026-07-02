-- ====================================================================
-- קובץ מבטים: Views.sql
-- תיאור: שני מבטים מורכבים המשלבים מספר טבלאות לטובת ניתוח נתונים מעמיק
-- ====================================================================

-- =================================================================
-- מבט 1: מנקודת המבט של המונדיאל - ניתוח ביצועי הנבחרות בשלבי הטורניר
-- =================================================================
-- 
-- הסבר:
-- מבט זה משלב 5 טבלאות (TEAM, MATCH, PLAYER_MATCH_STATS, MATCH_EVENT, STADIUM) 
-- ובוחן את ביצועי הנבחרת בכל שלב של הטורניר - אילו שחקנים שיחקו, כמה משחקים לכל שחקן,
-- שערים לפי שלב בטורניר (במונדיאל אין משחקי "בית וחוץ" כמו בליגה).
--
-- מה המבט עושה:
-- - סופר את מספר המשחקים של כל נבחרת בכל שלב בטורניר
-- - מזהה שחקני מפתח (אלו שהופיעו במספר רב של משחקים)
-- - מחשב את סך השערים וסטטיסטיקות נוספות לפי שלב
-- - מציג את האצטדיונים בהם הנבחרת שיחקה
-- - מחשב את התפלגות השחקנים לפי עמדות (שוערים, שחקני הגנה, קשרים, חלוצים)
--
-- תועלת המבט: מציג את מבנה הנבחרת והדינמיקה שלה בכל שלב בטורניר
-- 
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

-- --- דוגמאות לשאילתות בטוחות להרצה בנפרד ---

-- דוגמה 1.1: הנבחרות המובילות בטורניר עם סטטיסטיקות שחקנים
SELECT 
    Team_Name, 
    Confederation,
    Total_Tournament_Matches,
    Total_Goals_Scored,
    ROUND(Total_Goals_Scored::NUMERIC / NULLIF(Total_Tournament_Matches, 0), 2) AS Goals_Per_Match,
    Different_Goal_Scorers,
    Total_Different_Players_Used,
    Goalkeepers_Used || ' שוערים, ' || Defenders_Used || ' שחקני הגנה, ' || 
    Midfielders_Used || ' קשרים, ' || Forwards_Used || ' חלוצים' AS Player_Distribution
FROM WorldCup_Team_Performance_View
WHERE Total_Tournament_Matches > 0
ORDER BY Total_Goals_Scored DESC;

-- דוגמה 1.2: ניתוח רוטציית שחקנים ושימוש באצטדיונים
SELECT 
    Team_Name,
    Tournament_Stages_Reached,
    Total_Different_Players_Used,
    ROUND(Total_Different_Players_Used::NUMERIC / NULLIF(Total_Tournament_Matches, 0), 2) AS Players_Per_Match,
    Average_Stadium_Capacity,
    Stadiums_Played_In
FROM WorldCup_Team_Performance_View
WHERE Total_Tournament_Matches > 0
ORDER BY Total_Different_Players_Used DESC;


-- =================================================================
-- מבט 2: ניתוח משחקים ויחסי זכייה בלי שימוש ב-user_id
-- =================================================================
--
-- מבט זה משלב את MATCH, GLOBAL_MATCH, odds, TEAM, STADIUM ו-MATCH_EVENT כדי לבחון
-- את התוצאה האמיתית מול תחזיות ה-odds ללא תלות במזהה משתמש.
--
-- מה המבט עושה:
-- - מציג את המשחק עם תאריך, שלב, אצטדיון ויחסי odds
-- - מחשב את מספר השערים בית וחוץ לפי קבוצות
-- - קובע מי המועדף של הספרים ומי ניצח בפועל
-- - מסמן upset או outcome צפוי
--
-- תועלת המבט: מאפשר ניתוח של דיוק תחזיות odds על רמת המשחקים בטורניר
-- 
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

-- --- דוגמאות לשאילתות חדשים עבור Match_Odds_Analysis_View
-- דוגמה 2.1: כל המשחקים עם upset לפי Odds
SELECT
    MatchID,
    MatchDate,
    Stage,
    Home_Team,
    Away_Team,
    Stadium,
    Bookmaker_Favorite,
    Actual_Result,
    Favorite_Result,
    Home_Goals,
    Away_Goals,
    Total_Goals
FROM Match_Odds_Analysis_View
WHERE Favorite_Result = 'Upset / Draw'
ORDER BY MatchDate DESC;

-- דוגמה 2.2: משחקים שבהם תחזיות ה-odds התאימו לתוצאה
SELECT
    MatchID,
    MatchDate,
    Stage,
    Home_Team,
    Away_Team,
    Stadium,
    Bookmaker_Favorite,
    Actual_Result,
    Favorite_Result,
    Home_Goals,
    Away_Goals,
    Total_Goals
FROM Match_Odds_Analysis_View
WHERE Favorite_Result = 'Favorite Won'
ORDER BY MatchDate DESC;
