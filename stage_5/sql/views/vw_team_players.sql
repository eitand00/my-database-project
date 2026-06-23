CREATE OR REPLACE VIEW vw_team_players AS
SELECT p.ID, per.GivenName || ' ' || per.FamilyName AS FullName,
       p.DateOfBirth, p.TeamCode
FROM PLAYER p JOIN PERSON per ON p.ID = per.ID
ORDER BY per.FamilyName;
