CREATE OR REPLACE VIEW vw_stadiums_list AS
SELECT s.StadiumID, s.Name, s.City, s.Capacity, s.Country,
       COUNT(DISTINCT m.MatchID) AS MatchesHosted
FROM STADIUM s LEFT JOIN MATCH m ON s.StadiumID = m.StadiumID
GROUP BY s.StadiumID, s.Name, s.City, s.Capacity, s.Country
ORDER BY s.Capacity DESC;

CREATE OR REPLACE VIEW vw_stadiums_short AS
SELECT StadiumID, Name
FROM STADIUM
ORDER BY Name;

CREATE OR REPLACE PROCEDURE sp_stadium_insert(
  p_sid INT, p_name VARCHAR, p_city VARCHAR, p_capacity INT, p_country VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO STADIUM (StadiumID, Name, City, Capacity, Country, WikipediaPage)
  VALUES (p_sid, p_name, p_city, p_capacity, p_country, p_wiki);
END $$;

CREATE OR REPLACE PROCEDURE sp_stadium_update(
  p_sid INT, p_name VARCHAR, p_city VARCHAR, p_capacity INT, p_country VARCHAR, p_wiki VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
  UPDATE STADIUM SET Name=p_name, City=p_city, Capacity=p_capacity, Country=p_country, WikipediaPage=p_wiki
  WHERE StadiumID=p_sid;
END $$;

CREATE OR REPLACE PROCEDURE sp_stadium_delete(p_sid INT) LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM STADIUM WHERE StadiumID = p_sid;
END $$;
