CREATE OR REPLACE VIEW vw_player_match_stats AS
SELECT m.MatchDate, ht.CountryName AS Home, gt.CountryName AS Away,
       pms.Position, pms.ShirtNumber, pms.PlayerID
FROM PLAYER_MATCH_STATS pms
JOIN MATCH m ON pms.MatchID = m.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
ORDER BY m.MatchDate DESC;
