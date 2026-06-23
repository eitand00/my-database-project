CREATE OR REPLACE PROCEDURE sp_team_insert(
  p_code VARCHAR, p_country VARCHAR, p_conf_name VARCHAR,
  p_conf_code VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO TEAM (TeamCode, CountryName, ConfederationName, ConfederationCode, WikipediaPage)
  VALUES (p_code, p_country, p_conf_name, p_conf_code, p_wiki);
END $$;
