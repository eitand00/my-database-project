CREATE OR REPLACE VIEW vw_matches_list AS
SELECT m.MatchID, m.MatchDate, m.Stage, m.Tournament,
       ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
       s.Name AS Stadium,
       (SELECT COUNT(*) FROM MATCH_EVENT me WHERE me.MatchID = m.MatchID AND me.EventType = 'Goal') AS Goals
FROM MATCH m
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
JOIN STADIUM s ON m.StadiumID = s.StadiumID
ORDER BY m.MatchDate DESC
LIMIT 200;
