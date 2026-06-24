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

-- --- ׳©׳׳™׳׳×׳•׳× ׳¢׳ ׳׳‘׳˜ 1 (׳׳”׳¨׳¦׳” ׳‘׳ ׳₪׳¨׳“ ׳׳¦׳•׳¨׳ ׳¦׳™׳׳•׳׳™ ׳׳¡׳) ---

-- ׳©׳׳™׳׳×׳” 1.1: ׳©׳׳™׳₪׳× ׳”׳׳©׳—׳§׳™׳ ׳©׳‘׳”׳ ׳”׳§׳‘׳•׳¦׳” ׳”׳‘׳™׳×׳™׳× ׳”׳™׳™׳×׳” ׳₪׳™׳™׳‘׳•׳¨׳™׳˜׳™׳× ׳׳ ׳™׳¦׳—׳•׳
SELECT HomeTeam, GuestTeam, Stage, home_win_odd 
FROM WorldCup_Odds_View 
WHERE home_win_odd < 3.0
ORDER BY home_win_odd ASC;

-- ׳©׳׳™׳׳×׳” 1.2: ׳©׳׳™׳₪׳× 5 ׳”׳׳©׳—׳§׳™׳ ׳¢׳ ׳™׳—׳¡ ׳”׳–׳›׳™׳™׳” ׳”׳’׳‘׳•׳” ׳‘׳™׳•׳×׳¨ ׳׳×׳™׳§׳•
SELECT MatchDate, HomeTeam, GuestTeam, draw_odd 
FROM WorldCup_Odds_View 
ORDER BY draw_odd DESC 
LIMIT 5;


-- ---------------------------------------------------------
-- ׳׳‘׳˜ 2: ׳׳ ׳§׳•׳“׳× ׳”׳׳‘׳˜ ׳©׳ ׳׳¢׳¨׳›׳× ׳”׳”׳™׳׳•׳¨׳™׳
-- ׳׳˜׳¨׳”: ׳׳¢׳§׳‘ ׳׳—׳¨ ׳”׳׳©׳×׳׳©׳™׳ ׳׳”׳׳¢׳¨׳›׳× ׳”׳©׳ ׳™׳™׳” ׳©׳”׳™׳׳¨׳• ׳‘׳₪׳•׳¢׳ ׳¢׳ ׳׳©׳—׳§׳™ ׳”׳׳•׳ ׳“׳™׳׳ ׳©׳׳ ׳•.
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

-- --- ׳©׳׳™׳׳×׳•׳× ׳¢׳ ׳׳‘׳˜ 2 (׳׳”׳¨׳¦׳” ׳‘׳ ׳₪׳¨׳“ ׳׳¦׳•׳¨׳ ׳¦׳™׳׳•׳׳™ ׳׳¡׳) ---

-- ׳©׳׳™׳׳×׳” 2.1: ׳©׳׳™׳₪׳× "׳”׳׳”׳׳¨׳™׳ ׳”׳›׳‘׳“׳™׳" (׳׳¢׳ 50 ׳“׳•׳׳¨/׳©׳§׳׳™׳) ׳¢׳ ׳׳©׳—׳§׳™ ׳”׳׳•׳ ׳“׳™׳׳
SELECT Bettor_Name, bet_amount, predicted_result, HomeTeam, GuestTeam 
FROM Bettors_On_WorldCup_View 
WHERE bet_amount > 50
ORDER BY bet_amount DESC;

-- ׳©׳׳™׳׳×׳” 2.2: ׳¡׳™׳›׳•׳ ׳׳—׳–׳•׳¨ ׳”׳›׳¡׳₪׳™׳ (׳¡׳ ׳”׳”׳™׳׳•׳¨׳™׳) ׳©׳”׳•׳©׳§׳¢ ׳‘׳›׳ ׳׳©׳—׳§ ׳׳•׳ ׳“׳™׳׳
SELECT MatchDate, HomeTeam, GuestTeam, SUM(bet_amount) AS Total_Money_Placed
FROM Bettors_On_WorldCup_View
GROUP BY MatchDate, HomeTeam, GuestTeam
ORDER BY Total_Money_Placed DESC;