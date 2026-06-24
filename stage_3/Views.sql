-- ====================================================================
-- ׳§׳•׳‘׳¥ ׳׳‘׳˜׳™׳ ׳•׳©׳׳™׳׳×׳•׳×: Views.sql
-- ====================================================================

-- ---------------------------------------------------------
-- ׳׳‘׳˜ 1: ׳׳ ׳§׳•׳“׳× ׳”׳׳‘׳˜ ׳©׳ ׳׳¢׳¨׳›׳× ׳”׳׳•׳ ׳“׳™׳׳
-- ׳׳˜׳¨׳”: ׳”׳¦׳’׳× ׳׳©׳—׳§׳™ ׳”׳׳•׳ ׳“׳™׳׳ ׳©׳׳ ׳• ׳™׳—׳“ ׳¢׳ ׳™׳—׳¡׳™ ׳”׳–׳›׳™׳™׳” ׳©׳”׳•׳×׳׳׳• ׳׳”׳ ׳׳”׳׳¢׳¨׳›׳× ׳”׳©׳ ׳™׳™׳”.
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW WorldCup_Odds_View AS
SELECT 
    m.MatchDate,
    m.Stage,
    ht.CountryName AS HomeTeam,
    gt.CountryName AS GuestTeam,
    o.home_win_odd,
    o.draw_odd,
    o.away_win_odd
FROM MATCH m
JOIN GLOBAL_MATCH gm ON m.MatchID = gm.WCMatchID
JOIN odds o ON gm.GlobalMatchID = o.global_match_id
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode;

-- ---------------------------------------------------------
-- מבט 2: מבט המבט על מידע ההמרות
-- מטרה: מעקב אחר המשתמשים מהמשחקים השנייה שהימרו בסה"כ על משחקי המונדיאל שלנו.
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW Bettors_On_WorldCup_View AS
SELECT 
    u.full_name AS Bettor_Name,
    b.bet_amount,
    b.predicted_result,
    m.MatchDate,
    ht.CountryName AS HomeTeam,
    gt.CountryName AS GuestTeam
FROM users u
JOIN bets b ON u.user_id = b.user_id
JOIN GLOBAL_MATCH gm ON b.global_match_id = gm.GlobalMatchID
JOIN MATCH m ON gm.WCMatchID = m.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode;