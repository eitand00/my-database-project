CREATE OR REPLACE VIEW vw_players_list AS
SELECT p.ID, per.GivenName, per.FamilyName, p.DateOfBirth,
       t.CountryName AS Team, COUNT(me.MatchEventID) AS Events
FROM PLAYER p
JOIN PERSON per ON p.ID = per.ID
JOIN TEAM t ON p.TeamCode = t.TeamCode
LEFT JOIN MATCH_EVENT me ON p.ID = me.ID
GROUP BY p.ID, per.GivenName, per.FamilyName, p.DateOfBirth, t.CountryName
ORDER BY per.FamilyName
LIMIT 200;
