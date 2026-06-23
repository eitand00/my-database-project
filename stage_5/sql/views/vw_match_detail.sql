CREATE OR REPLACE VIEW vw_match_detail AS
SELECT m.*, s.Name AS StadiumName,
       ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
       per.GivenName || ' ' || per.FamilyName AS RefereeName
FROM MATCH m
JOIN STADIUM s ON m.StadiumID = s.StadiumID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
JOIN REFEREE r ON m.RefereeID = r.ID
JOIN PERSON per ON r.ID = per.ID;
