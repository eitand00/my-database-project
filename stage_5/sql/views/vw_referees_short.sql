CREATE OR REPLACE VIEW vw_referees_short AS
SELECT r.ID, per.GivenName || ' ' || per.FamilyName AS Name
FROM REFEREE r JOIN PERSON per ON r.ID = per.ID ORDER BY per.FamilyName;
