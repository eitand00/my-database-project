CREATE OR REPLACE VIEW vw_teams_list AS
SELECT t.TeamCode, t.CountryName, t.ConfederationName,
       COUNT(DISTINCT p.ID) AS PlayerCount,
       COUNT(DISTINCT m.MatchID) AS MatchCount
FROM TEAM t LEFT JOIN PLAYER p ON t.TeamCode = p.TeamCode
LEFT JOIN MATCH m ON t.TeamCode IN (m.HomeTeamCode, m.GuestTeamCode)
GROUP BY t.TeamCode, t.CountryName, t.ConfederationName
ORDER BY t.CountryName;

CREATE OR REPLACE VIEW vw_team_players AS
SELECT p.ID, per.GivenName || ' ' || per.FamilyName AS FullName,
       p.DateOfBirth, p.TeamCode
FROM PLAYER p JOIN PERSON per ON p.ID = per.ID
ORDER BY per.FamilyName;

CREATE OR REPLACE VIEW vw_team_matches AS
SELECT m.MatchID, m.MatchDate, m.Stage,
       ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
       m.HomeTeamCode, m.GuestTeamCode
FROM MATCH m
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
ORDER BY m.MatchDate DESC LIMIT 20;

CREATE OR REPLACE VIEW vw_teams_short AS
SELECT TeamCode, CountryName
FROM TEAM
ORDER BY CountryName;

CREATE OR REPLACE VIEW vw_team_detail AS
SELECT TeamCode, CountryName, ConfederationName, ConfederationCode, WikipediaPage
FROM TEAM;

CREATE OR REPLACE PROCEDURE sp_team_insert(
  p_code VARCHAR, p_country VARCHAR, p_conf_name VARCHAR,
  p_conf_code VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO TEAM (TeamCode, CountryName, ConfederationName, ConfederationCode, WikipediaPage)
  VALUES (p_code, p_country, p_conf_name, p_conf_code, p_wiki);
END $$;

CREATE OR REPLACE PROCEDURE sp_team_update(
  p_code VARCHAR, p_country VARCHAR, p_conf_name VARCHAR,
  p_conf_code VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  UPDATE TEAM SET CountryName=p_country, ConfederationName=p_conf_name,
                  ConfederationCode=p_conf_code, WikipediaPage=p_wiki
  WHERE TeamCode=p_code;
END $$;

CREATE OR REPLACE PROCEDURE sp_team_delete(p_code VARCHAR) LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM TEAM WHERE TeamCode = p_code;
END $$;
