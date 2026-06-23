CREATE OR REPLACE VIEW vw_team_matches AS
SELECT m.MatchID, m.MatchDate, m.Stage,
       ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
       m.HomeTeamCode, m.GuestTeamCode
FROM MATCH m
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
ORDER BY m.MatchDate DESC LIMIT 20;
