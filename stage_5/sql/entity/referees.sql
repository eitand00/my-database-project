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

CREATE OR REPLACE VIEW vw_referees_short AS
SELECT r.ID, per.GivenName || ' ' || per.FamilyName AS Name
FROM REFEREE r
JOIN PERSON per ON r.ID = per.ID
ORDER BY per.FamilyName;

CREATE OR REPLACE PROCEDURE sp_referee_insert(
  p_rid INT, p_country VARCHAR, p_conf_code VARCHAR, p_conf_name VARCHAR,
  p_given VARCHAR, p_family VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO PERSON (ID, GivenName, FamilyName, WikipediaPage)
  VALUES (p_rid, p_given, p_family, p_wiki);
  INSERT INTO REFEREE (ID, Country, ConfederationCode, ConfederationName)
  VALUES (p_rid, p_country, p_conf_code, p_conf_name);
END $$;

CREATE OR REPLACE PROCEDURE sp_referee_update(
  p_rid INT, p_country VARCHAR, p_conf_code VARCHAR, p_conf_name VARCHAR,
  p_given VARCHAR, p_family VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  UPDATE PERSON SET GivenName=p_given, FamilyName=p_family WHERE ID=p_rid;
  UPDATE REFEREE SET Country=p_country, ConfederationCode=p_conf_code, ConfederationName=p_conf_name WHERE ID=p_rid;
END $$;

CREATE OR REPLACE PROCEDURE sp_referee_delete(p_rid INT) LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM REFEREE WHERE ID = p_rid;
  DELETE FROM PERSON WHERE ID = p_rid;
END $$;
