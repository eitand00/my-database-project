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
