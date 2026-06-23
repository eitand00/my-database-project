CREATE OR REPLACE VIEW vw_dashboard_counts AS
SELECT
  (SELECT COUNT(*) FROM MATCH) AS match_count,
  (SELECT COUNT(*) FROM TEAM) AS team_count,
  (SELECT COUNT(*) FROM PLAYER) AS player_count,
  (SELECT COUNT(*) FROM STADIUM) AS stadium_count,
  (SELECT COUNT(*) FROM MATCH_EVENT) AS event_count;
