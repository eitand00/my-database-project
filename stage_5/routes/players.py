from flask import render_template, request, redirect, url_for, flash
from db_helpers import (
    get_players_list, get_player_detail, get_player_events, get_player_stats,
    get_teams_short, create_player, update_player, delete_player
)
from . import admin_required


def init_routes(app):
    @app.route("/players")
    def players():
        q = request.args.get("q", "")
        rows = get_players_list(search=q or None)
        teams = get_teams_short()
        return render_template("players.html", players=rows, teams=teams, q=q)

    @app.route("/players/<pid>")
    def player_detail(pid):
        player = get_player_detail(pid)
        if not player:
            flash("Player not found.", "error")
            return redirect(url_for("players"))
        events = get_player_events(pid)
        stats = get_player_stats(pid)
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
            update_player(pid, dob, team_code, given_name, family_name, wiki)
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
            create_player(pid, given, family, wiki, dob, team)
            flash("Player added successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("players"))

    @app.route("/players/<pid>/delete", methods=["POST"])
    @admin_required
    def player_delete(pid):
        try:
            delete_player(pid)
            flash("Player deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("players"))
