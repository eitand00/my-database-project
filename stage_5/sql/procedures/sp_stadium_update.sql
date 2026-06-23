CREATE OR REPLACE PROCEDURE sp_stadium_update(
  p_sid INT, p_name VARCHAR, p_city VARCHAR, p_capacity INT, p_country VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  UPDATE STADIUM SET Name=p_name, City=p_city, Capacity=p_capacity, Country=p_country, WikipediaPage=p_wiki
  WHERE StadiumID=p_sid;
END $$;
