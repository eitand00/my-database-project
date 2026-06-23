CREATE OR REPLACE PROCEDURE sp_stadium_insert(
  p_sid INT, p_name VARCHAR, p_city VARCHAR, p_capacity INT, p_country VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO STADIUM (StadiumID, Name, City, Capacity, Country, WikipediaPage)
  VALUES (p_sid, p_name, p_city, p_capacity, p_country, p_wiki);
END $$;
