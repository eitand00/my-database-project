CREATE OR REPLACE PROCEDURE sp_player_update(
  p_id INT, p_dob DATE, p_team VARCHAR,
  p_given VARCHAR, p_family VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  UPDATE PLAYER SET DateOfBirth=p_dob, TeamCode=p_team WHERE ID=p_id;
  UPDATE PERSON SET GivenName=p_given, FamilyName=p_family, WikipediaPage=p_wiki WHERE ID=p_id;
END $$;
