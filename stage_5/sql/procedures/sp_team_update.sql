CREATE OR REPLACE PROCEDURE sp_team_update(
  p_code VARCHAR, p_country VARCHAR, p_conf_name VARCHAR,
  p_conf_code VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  UPDATE TEAM SET CountryName=p_country, ConfederationName=p_conf_name,
                  ConfederationCode=p_conf_code, WikipediaPage=p_wiki
  WHERE TeamCode=p_code;
END $$;
