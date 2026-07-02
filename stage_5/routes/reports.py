from flask import render_template, request, jsonify
from db_connection import execute_query


REPORT_VIEWS = {
    1: "vw_high_scoring_matches",
    2: "vw_big_stadiums_red_cards",
    3: "vw_team_goals_analysis",
}


def init_routes(app):
    @app.route("/reports")
    def reports():
        return render_template("reports.html")

    @app.route("/api/report/<int:report_id>", methods=["POST"])
    def api_report(report_id):
        view = REPORT_VIEWS.get(report_id)
        if not view:
            return jsonify({"success": False, "error": "Invalid report ID."})
        try:
            cols, rows, notices = execute_query(f"SELECT * FROM {view}")
            return jsonify({"success": True, "columns": cols, "rows": [[str(c) if c is not None else "" for c in r] for r in rows], "notices": notices})
        except Exception as e:
            return jsonify({"success": False, "error": str(e)})
