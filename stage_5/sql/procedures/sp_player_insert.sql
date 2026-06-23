CREATE OR REPLACE PROCEDURE sp_player_insert(
  p_id INT, p_given VARCHAR, p_family VARCHAR, p_wiki VARCHAR,
  p_dob DATE, p_team VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO PERSON (ID, GivenName, FamilyName, WikipediaPage)
  VALUES (p_id, p_given, p_family, p_wiki);
  INSERT INTO PLAYER (ID, DateOfBirth, TeamCode)
  VALUES (p_id, p_dob, p_team);
END $$;
