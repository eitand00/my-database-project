CREATE OR REPLACE PROCEDURE sp_referee_update(
  p_rid INT, p_country VARCHAR, p_conf_code VARCHAR, p_conf_name VARCHAR,
  p_given VARCHAR, p_family VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  UPDATE PERSON SET GivenName=p_given, FamilyName=p_family WHERE ID=p_rid;
  UPDATE REFEREE SET Country=p_country, ConfederationCode=p_conf_code, ConfederationName=p_conf_name WHERE ID=p_rid;
END $$;
