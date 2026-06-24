from flask import render_template, request, redirect, url_for, flash
from db_connection import (
    get_teams_list, get_team_detail, get_team_players, get_team_matches,
    create_team, update_team, delete_team
)
from . import admin_required


def init_routes(app):
    @app.route("/teams")
    def teams():
        q = request.args.get("q", "")
        rows = get_teams_list(search=q or None)
        return render_template("teams.html", teams=rows, q=q)

    @app.route("/teams/<code>")
    def team_detail(code):
        team = get_team_detail(code)
        if not team:
            flash("Team not found.", "error")
            return redirect(url_for("teams"))
        players = get_team_players(code)
        matches = get_team_matches(code)
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
                update_team(code, country, conf_name, conf_code, wiki)
                flash("Team updated successfully!", "success")
                return redirect(url_for("team_detail", code=code))
            except Exception as e:
                flash(f"Error: {str(e)}", "error")
        team = get_team_detail(code)
        if not team:
            flash("Team not found.", "error")
            return redirect(url_for("teams"))
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
                create_team(code, country, conf_name, conf_code, wiki)
                flash("Team added successfully!", "success")
                return redirect(url_for("teams"))
            except Exception as e:
                flash(f"Error: {str(e)}", "error")
        return render_template("team_edit.html", team=None)

    @app.route("/teams/<code>/delete", methods=["POST"])
    @admin_required
    def team_delete(code):
        try:
            delete_team(code)
            flash("Team deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("teams"))
