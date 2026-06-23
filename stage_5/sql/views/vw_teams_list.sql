CREATE OR REPLACE VIEW vw_teams_list AS
SELECT t.TeamCode, t.CountryName, t.ConfederationName,
       COUNT(DISTINCT p.ID) AS PlayerCount,
       COUNT(DISTINCT m.MatchID) AS MatchCount
FROM TEAM t LEFT JOIN PLAYER p ON t.TeamCode = p.TeamCode
LEFT JOIN MATCH m ON t.TeamCode IN (m.HomeTeamCode, m.GuestTeamCode)
GROUP BY t.TeamCode, t.CountryName, t.ConfederationName
ORDER BY t.CountryName;
