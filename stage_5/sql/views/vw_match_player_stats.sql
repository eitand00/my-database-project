CREATE OR REPLACE VIEW vw_match_player_stats AS
SELECT per.GivenName || ' ' || per.FamilyName AS PlayerName,
       pms.Position, pms.ShirtNumber, pms.MatchID
FROM PLAYER_MATCH_STATS pms
JOIN PLAYER pl ON pms.PlayerID = pl.ID
JOIN PERSON per ON pl.ID = per.ID
ORDER BY pms.ShirtNumber;
