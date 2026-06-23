from flask import render_template, request, redirect, url_for, flash
from db_helpers import (
    get_matches_list, get_tournaments, get_match_detail,
    get_match_events, get_match_player_stats,
    get_teams_short, get_stadiums_short, get_referees_short,
    create_match, update_match, delete_match
)
from . import admin_required


def init_routes(app):
    @app.route("/matches")
    def matches():
        tournament = request.args.get("tournament", "")
        rows = get_matches_list(tournament=tournament or None)
        tournaments = get_tournaments()
        return render_template("matches.html", matches=rows, tournaments=tournaments,
                               selected_tournament=tournament)

    @app.route("/matches/<mid>")
    def match_detail(mid):
        match = get_match_detail(mid)
        if not match:
            flash("Match not found.", "error")
            return redirect(url_for("matches"))
        events = get_match_events(mid)
        stats = get_match_player_stats(mid)
        return render_template("match_detail.html", match=match, events=events, stats=stats)

    @app.route("/matches/add", methods=["GET", "POST"])
    @admin_required
    def match_add():
        if request.method == "POST":
            mid = request.form.get("matchid")
            mdate = request.form.get("matchdate")
            stage = request.form.get("stage")
            tournament = request.form.get("tournament")
            time = request.form.get("matchtime")
            stadium = request.form.get("stadium")
            home = request.form.get("home")
            guest = request.form.get("guest")
            referee = request.form.get("referee")
            try:
                create_match(mid, mdate, stage, tournament, time, stadium, home, guest, referee)
                flash("Match added successfully!", "success")
                return redirect(url_for("matches"))
            except Exception as e:
                flash(f"Error: {str(e)}", "error")
        teams = get_teams_short()
        stadiums = get_stadiums_short()
        referees = get_referees_short()
        return render_template("match_form.html", match=None, teams=teams,
                               stadiums=stadiums, referees=referees)

    @app.route("/matches/<mid>/edit", methods=["GET", "POST"])
    @admin_required
    def match_edit(mid):
        if request.method == "POST":
            mdate = request.form.get("matchdate")
            stage = request.form.get("stage")
            tournament = request.form.get("tournament")
            time = request.form.get("matchtime")
            stadium = request.form.get("stadium")
            home = request.form.get("home")
            guest = request.form.get("guest")
            referee = request.form.get("referee")
            try:
                update_match(mid, mdate, stage, tournament, time, stadium, home, guest, referee)
                flash("Match updated successfully!", "success")
                return redirect(url_for("match_detail", mid=mid))
            except Exception as e:
                flash(f"Error: {str(e)}", "error")
        match = get_match_detail(mid)
        if not match:
            flash("Match not found.", "error")
            return redirect(url_for("matches"))
        teams = get_teams_short()
        stadiums = get_stadiums_short()
        referees = get_referees_short()
        return render_template("match_form.html", match=match, teams=teams,
                               stadiums=stadiums, referees=referees)

    @app.route("/matches/<mid>/delete", methods=["POST"])
    @admin_required
    def match_delete(mid):
        try:
            delete_match(mid)
            flash("Match deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("matches"))
