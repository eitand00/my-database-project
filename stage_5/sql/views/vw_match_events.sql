CREATE OR REPLACE VIEW vw_match_events AS
SELECT me.MatchEventID, me.Minute, me.EventType,
       per.GivenName || ' ' || per.FamilyName AS PlayerName,
       me.MatchID
FROM MATCH_EVENT me
JOIN PLAYER pl ON me.ID = pl.ID
JOIN PERSON per ON pl.ID = per.ID
ORDER BY me.Minute ASC;
