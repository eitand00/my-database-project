CREATE OR REPLACE VIEW vw_player_events AS
SELECT me.MatchEventID, me.Minute, me.EventType,
       m.MatchDate, m.Stage,
       ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
       me.ID AS PlayerID
FROM MATCH_EVENT me
JOIN MATCH m ON me.MatchID = m.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
ORDER BY m.MatchDate DESC;
