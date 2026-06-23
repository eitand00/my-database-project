CREATE OR REPLACE VIEW vw_player_detail AS
SELECT p.ID, per.GivenName, per.FamilyName, per.WikipediaPage,
       p.DateOfBirth, t.CountryName AS Team, t.TeamCode
FROM PLAYER p
JOIN PERSON per ON p.ID = per.ID
JOIN TEAM t ON p.TeamCode = t.TeamCode;
