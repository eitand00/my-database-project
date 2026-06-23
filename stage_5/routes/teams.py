from flask import render_template, request, redirect, url_for, flash
from db_connection import execute_query
from . import admin_required


def init_routes(app):
    @app.route("/teams")
    def teams():
        q = request.args.get("q", "")
        where = "WHERE countryname ILIKE %s" if q else ""
        params = [f"%{q}%"] if q else []
        _, rows, _ = execute_query(
            f"SELECT * FROM vw_teams_list {where}", params
        )
        return render_template("teams.html", teams=rows, q=q)

    @app.route("/teams/<code>")
    def team_detail(code):
        cols, rows, _ = execute_query(
            "SELECT * FROM vw_team_detail WHERE TeamCode = %s", [code]
        )
        if not rows:
            flash("Team not found.", "error")
            return redirect(url_for("teams"))
        team = dict(zip([c.lower() for c in cols], rows[0]))
        _, players, _ = execute_query(
            "SELECT * FROM vw_team_players WHERE TeamCode = %s", [code]
        )
        _, matches, _ = execute_query(
            "SELECT * FROM vw_team_matches WHERE HomeTeamCode = %s OR GuestTeamCode = %s",
            [code, code]
        )
        return render_template("team_detail.html", team=team, players=players, matches=matches)

    @app.route("/teams/<code>/edit", methods=["GET", "POST"])
    @admin_required
    def team_edit(code):
        if request.method == "POST":
            country = request.form.get("country")
            conf_name = request.form.get("conf_name")
            conf_code = request.form.get("conf_code")
            wiki = request.form.get("wiki")
            try:
                execute_query(
                    "CALL sp_team_update(%s,%s,%s,%s,%s)",
                    [code, country, conf_name, conf_code, wiki], fetch=False
                )
                flash("Team updated successfully!", "success")
                return redirect(url_for("team_detail", code=code))
            except Exception as e:
                flash(f"Error: {str(e)}", "error")
        cols, rows, _ = execute_query(
            "SELECT * FROM vw_team_detail WHERE TeamCode = %s", [code]
        )
        if not rows:
            flash("Team not found.", "error")
            return redirect(url_for("teams"))
        team = dict(zip([c.lower() for c in cols], rows[0]))
        return render_template("team_edit.html", team=team)

    @app.route("/teams/add", methods=["GET", "POST"])
    @admin_required
    def team_add():
        if request.method == "POST":
            code = request.form.get("code")
            country = request.form.get("country")
            conf_name = request.form.get("conf_name")
            conf_code = request.form.get("conf_code")
            wiki = request.form.get("wiki")
            try:
                execute_query(
                    "CALL sp_team_insert(%s,%s,%s,%s,%s)",
                    [code, country, conf_name, conf_code, wiki], fetch=False
                )
                flash("Team added successfully!", "success")
                return redirect(url_for("teams"))
            except Exception as e:
                flash(f"Error: {str(e)}", "error")
        return render_template("team_edit.html", team=None)

    @app.route("/teams/<code>/delete", methods=["POST"])
    @admin_required
    def team_delete(code):
        try:
            execute_query("CALL sp_team_delete(%s)", [code], fetch=False)
            flash("Team deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("teams"))
