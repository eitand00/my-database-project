CREATE OR REPLACE VIEW vw_referees_list AS
SELECT r.ID, per.GivenName || ' ' || per.FamilyName AS FullName,
       r.Country, r.ConfederationName,
       COUNT(DISTINCT m.MatchID) AS MatchesOfficiated,
       per.GivenName, per.FamilyName
FROM REFEREE r
JOIN PERSON per ON r.ID = per.ID
LEFT JOIN MATCH m ON r.ID = m.RefereeID
GROUP BY r.ID, per.GivenName, per.FamilyName, r.Country, r.ConfederationName
ORDER BY per.FamilyName;
