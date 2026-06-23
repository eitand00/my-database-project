CREATE OR REPLACE VIEW vw_stadiums_list AS
SELECT s.StadiumID, s.Name, s.City, s.Capacity, s.Country,
       COUNT(DISTINCT m.MatchID) AS MatchesHosted
FROM STADIUM s LEFT JOIN MATCH m ON s.StadiumID = m.StadiumID
GROUP BY s.StadiumID, s.Name, s.City, s.Capacity, s.Country
ORDER BY s.Capacity DESC;
