from flask import render_template, request, redirect, url_for, flash
from db_connection import execute_query
from . import admin_required


def init_routes(app):
    @app.route("/matches")
    def matches():
        tournament = request.args.get("tournament", "")
        where = "WHERE tournament = %s" if tournament else ""
        params = [tournament] if tournament else []
        _, rows, _ = execute_query(
            f"SELECT * FROM vw_matches_list {where}", params
        )
        _, tournaments, _ = execute_query("SELECT * FROM vw_tournaments")
        return render_template("matches.html", matches=rows, tournaments=tournaments,
                               selected_tournament=tournament)

    @app.route("/matches/<mid>")
    def match_detail(mid):
        cols, rows, _ = execute_query(
            "SELECT * FROM vw_match_detail WHERE MatchID = %s", [mid]
        )
        if not rows:
            flash("Match not found.", "error")
            return redirect(url_for("matches"))
        match = dict(zip([c.lower() for c in cols], rows[0]))
        _, events, _ = execute_query(
            "SELECT * FROM vw_match_events WHERE MatchID = %s", [mid]
        )
        _, stats, _ = execute_query(
            "SELECT * FROM vw_match_player_stats WHERE MatchID = %s", [mid]
        )
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
                execute_query(
                    "CALL sp_match_insert(%s,%s,%s,%s,%s,%s,%s,%s,%s)",
                    [mid, mdate, stage, tournament, time, stadium, home, guest, referee],
                    fetch=False
                )
                flash("Match added successfully!", "success")
                return redirect(url_for("matches"))
            except Exception as e:
                flash(f"Error: {str(e)}", "error")
        _, teams, _ = execute_query("SELECT * FROM vw_teams_short")
        _, stadiums, _ = execute_query("SELECT * FROM vw_stadiums_short")
        _, referees, _ = execute_query("SELECT * FROM vw_referees_short")
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
                execute_query(
                    "CALL sp_match_update(%s,%s,%s,%s,%s,%s,%s,%s,%s)",
                    [mid, mdate, stage, tournament, time, stadium, home, guest, referee],
                    fetch=False
                )
                flash("Match updated successfully!", "success")
                return redirect(url_for("match_detail", mid=mid))
            except Exception as e:
                flash(f"Error: {str(e)}", "error")
        cols, rows, _ = execute_query(
            "SELECT * FROM vw_match_detail WHERE MatchID = %s", [mid]
        )
        if not rows:
            flash("Match not found.", "error")
            return redirect(url_for("matches"))
        match = dict(zip([c.lower() for c in cols], rows[0]))
        _, teams, _ = execute_query("SELECT * FROM vw_teams_short")
        _, stadiums, _ = execute_query("SELECT * FROM vw_stadiums_short")
        _, referees, _ = execute_query("SELECT * FROM vw_referees_short")
        return render_template("match_form.html", match=match, teams=teams,
                               stadiums=stadiums, referees=referees)

    @app.route("/matches/<mid>/delete", methods=["POST"])
    @admin_required
    def match_delete(mid):
        try:
            execute_query("CALL sp_match_delete(%s)", [mid], fetch=False)
            flash("Match deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("matches"))
