from flask import render_template, request, redirect, url_for, flash
from db_connection import execute_query
from . import admin_required


def init_routes(app):
    @app.route("/players")
    def players():
        q = request.args.get("q", "")
        where = "WHERE (givenname ILIKE %s OR familyname ILIKE %s)" if q else ""
        params = [f"%{q}%", f"%{q}%"] if q else []
        _, rows, _ = execute_query(
            f"SELECT * FROM vw_players_list {where}", params
        )
        _, teams, _ = execute_query("SELECT * FROM vw_teams_short")
        return render_template("players.html", players=rows, teams=teams, q=q)

    @app.route("/players/<pid>")
    def player_detail(pid):
        cols, rows, _ = execute_query(
            "SELECT * FROM vw_player_detail WHERE ID = %s", [pid]
        )
        if not rows:
            flash("Player not found.", "error")
            return redirect(url_for("players"))
        player = dict(zip([c.lower() for c in cols], rows[0]))
        _, events, _ = execute_query(
            "SELECT * FROM vw_player_events WHERE PlayerID = %s", [pid]
        )
        _, stats, _ = execute_query(
            "SELECT * FROM vw_player_match_stats WHERE PlayerID = %s", [pid]
        )
        return render_template("player_detail.html", player=player, events=events, stats=stats)

    @app.route("/players/<pid>/edit", methods=["POST"])
    @admin_required
    def player_edit(pid):
        dob = request.form.get("dateofbirth")
        team_code = request.form.get("team_code")
        given_name = request.form.get("given_name")
        family_name = request.form.get("family_name")
        wiki = request.form.get("wiki")
        try:
            execute_query(
                "CALL sp_player_update(%s,%s,%s,%s,%s,%s)",
                [pid, dob, team_code, given_name, family_name, wiki], fetch=False
            )
            flash("Player updated successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("player_detail", pid=pid))

    @app.route("/players/add", methods=["POST"])
    @admin_required
    def player_add():
        pid = request.form.get("pid")
        given = request.form.get("given_name")
        family = request.form.get("family_name")
        wiki = request.form.get("wiki")
        dob = request.form.get("dateofbirth")
        team = request.form.get("team_code")
        try:
            execute_query(
                "CALL sp_player_insert(%s,%s,%s,%s,%s,%s)",
                [pid, given, family, wiki, dob, team], fetch=False
            )
            flash("Player added successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("players"))

    @app.route("/players/<pid>/delete", methods=["POST"])
    @admin_required
    def player_delete(pid):
        try:
            execute_query("CALL sp_player_delete(%s)", [pid], fetch=False)
            flash("Player deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("players"))
