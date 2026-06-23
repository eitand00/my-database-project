CREATE OR REPLACE VIEW vw_events_list AS
SELECT me.MatchEventID, me.Minute, me.EventType,
       ht.CountryName || ' vs ' || gt.CountryName AS MatchName,
       per.GivenName || ' ' || per.FamilyName AS PlayerName,
       per.GivenName, per.FamilyName
FROM MATCH_EVENT me
JOIN MATCH m ON me.MatchID = m.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
JOIN PLAYER pl ON me.ID = pl.ID
JOIN PERSON per ON pl.ID = per.ID
ORDER BY me.MatchEventID
LIMIT 200;
