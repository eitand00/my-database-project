CREATE OR REPLACE VIEW vw_teams_short AS
SELECT TeamCode, CountryName FROM TEAM ORDER BY CountryName;
