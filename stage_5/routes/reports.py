from flask import render_template, request, jsonify
from db_connection import execute_query


PREDEFINED_QUERIES = {
    1: """SELECT m.MatchID,
  EXTRACT(DAY FROM m.MatchDate) || '/' || EXTRACT(MONTH FROM m.MatchDate) AS MatchDate,
  EXTRACT(YEAR FROM m.MatchDate) AS MatchYear, m.Stage,
  ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam, gc.TotalGoals
FROM MATCH m
JOIN (SELECT MatchID, COUNT(MatchEventID) AS TotalGoals
  FROM MATCH_EVENT WHERE EventType = 'Goal'
  GROUP BY MatchID HAVING COUNT(MatchEventID) > 3) gc ON m.MatchID = gc.MatchID
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
WHERE EXTRACT(YEAR FROM m.MatchDate) = 2018
ORDER BY gc.TotalGoals DESC""",

    2: """SELECT DISTINCT s.Name AS StadiumName, s.City AS StadiumCity,
  s.Capacity, m.MatchDate, m.Stage, m.Tournament
FROM STADIUM s JOIN MATCH m ON s.StadiumID = m.StadiumID
WHERE s.Capacity >= 60000
AND EXISTS (SELECT 1 FROM MATCH_EVENT me
  WHERE me.MatchID = m.MatchID AND me.EventType = 'Red Card')""",

    3: """SELECT t.CountryName AS Team, COUNT(me.MatchEventID) AS TotalGoals,
  MIN(me.Minute) AS FastestGoal, MAX(me.Minute) AS LatestGoal
FROM TEAM t JOIN PLAYER pl ON t.TeamCode = pl.TeamCode
JOIN MATCH_EVENT me ON pl.ID = me.ID
WHERE LOWER(me.EventType) = 'goal'
GROUP BY t.TeamCode, t.CountryName
HAVING COUNT(me.MatchEventID) > 2
ORDER BY TotalGoals DESC"""
}


def init_routes(app):
    @app.route("/reports")
    def reports():
        return render_template("reports.html")

    @app.route("/api/report/<int:report_id>", methods=["POST"])
    def api_report(report_id):
        if report_id not in PREDEFINED_QUERIES:
            return jsonify({"success": False, "error": "Invalid report ID."})
        try:
            cols, rows, notices = execute_query(PREDEFINED_QUERIES[report_id])
            return jsonify({"success": True, "columns": cols, "rows": [[str(c) if c is not None else "" for c in r] for r in rows], "notices": notices})
        except Exception as e:
            return jsonify({"success": False, "error": str(e)})
