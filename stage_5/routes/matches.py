from flask import render_template, request, redirect, url_for, flash
from db_connection import execute_query
from . import admin_required


def init_routes(app):
    @app.route("/matches")
    def matches():
        tournament = request.args.get("tournament", "")
        where = "WHERE m.Tournament = %s" if tournament else ""
        params = [tournament] if tournament else []
        _, rows, _ = execute_query(f"""
            SELECT m.MatchID, m.MatchDate, m.Stage, m.Tournament,
                   ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
                   s.Name AS Stadium,
                   (SELECT COUNT(*) FROM MATCH_EVENT me WHERE me.MatchID = m.MatchID AND me.EventType = 'Goal') AS Goals
            FROM MATCH m
            JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
            JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
            JOIN STADIUM s ON m.StadiumID = s.StadiumID
            {where}
            ORDER BY m.MatchDate DESC
            LIMIT 200
        """, params)
        _, tournaments, _ = execute_query("SELECT DISTINCT Tournament FROM MATCH ORDER BY Tournament")
        return render_template("matches.html", matches=rows, tournaments=tournaments, selected_tournament=tournament)

    @app.route("/matches/<mid>")
    def match_detail(mid):
        cols, rows, _ = execute_query("""
            SELECT m.*, s.Name AS StadiumName,
                   ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
                   per.GivenName || ' ' || per.FamilyName AS RefereeName
            FROM MATCH m
            JOIN STADIUM s ON m.StadiumID = s.StadiumID
            JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
            JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
            JOIN REFEREE r ON m.RefereeID = r.ID
            JOIN PERSON per ON r.ID = per.ID
            WHERE m.MatchID = %s
        """, [mid])
        if not rows:
            flash("Match not found.", "error")
            return redirect(url_for("matches"))
        match = dict(zip([c.lower() for c in cols], rows[0]))

        _, events, _ = execute_query("""
            SELECT me.MatchEventID, me.Minute, me.EventType,
                   per.GivenName || ' ' || per.FamilyName AS PlayerName
            FROM MATCH_EVENT me
            JOIN PLAYER pl ON me.ID = pl.ID
            JOIN PERSON per ON pl.ID = per.ID
            WHERE me.MatchID = %s ORDER BY regexp_replace(me.Minute, '[+''].*$', '')::int ASC
        """, [mid])

        _, stats, _ = execute_query("""
            SELECT per.GivenName || ' ' || per.FamilyName AS PlayerName,
                   pms.Position, pms.ShirtNumber
            FROM PLAYER_MATCH_STATS pms
            JOIN PLAYER pl ON pms.PlayerID = pl.ID
            JOIN PERSON per ON pl.ID = per.ID
            WHERE pms.MatchID = %s ORDER BY pms.ShirtNumber
        """, [mid])

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
                    "INSERT INTO MATCH (MatchID, MatchDate, Stage, Tournament, MatchTime, StadiumID, HomeTeamCode, GuestTeamCode, RefereeID) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)",
                    [mid, mdate, stage, tournament, time, stadium, home, guest, referee], fetch=False
                )
                flash("Match added successfully!", "success")
                return redirect(url_for("matches"))
            except Exception as e:
                flash(f"Error: {str(e)}", "error")

        _, teams, _ = execute_query("SELECT TeamCode, CountryName FROM TEAM ORDER BY CountryName")
        _, stadiums, _ = execute_query("SELECT StadiumID, Name FROM STADIUM ORDER BY Name")
        _, referees, _ = execute_query("""
            SELECT r.ID, per.GivenName || ' ' || per.FamilyName AS Name
            FROM REFEREE r JOIN PERSON per ON r.ID = per.ID ORDER BY per.FamilyName
        """)
        return render_template("match_form.html", match=None, teams=teams, stadiums=stadiums, referees=referees)

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
                    "UPDATE MATCH SET MatchDate=%s, Stage=%s, Tournament=%s, MatchTime=%s, StadiumID=%s, HomeTeamCode=%s, GuestTeamCode=%s, RefereeID=%s WHERE MatchID=%s",
                    [mdate, stage, tournament, time, stadium, home, guest, referee, mid], fetch=False
                )
                flash("Match updated successfully!", "success")
                return redirect(url_for("match_detail", mid=mid))
            except Exception as e:
                flash(f"Error: {str(e)}", "error")

        cols, rows, _ = execute_query("SELECT * FROM MATCH WHERE MatchID = %s", [mid])
        if not rows:
            flash("Match not found.", "error")
            return redirect(url_for("matches"))
        match = dict(zip([c.lower() for c in cols], rows[0]))
        _, teams, _ = execute_query("SELECT TeamCode, CountryName FROM TEAM ORDER BY CountryName")
        _, stadiums, _ = execute_query("SELECT StadiumID, Name FROM STADIUM ORDER BY Name")
        _, referees, _ = execute_query("""
            SELECT r.ID, per.GivenName || ' ' || per.FamilyName AS Name
            FROM REFEREE r JOIN PERSON per ON r.ID = per.ID ORDER BY per.FamilyName
        """)
        return render_template("match_form.html", match=match, teams=teams, stadiums=stadiums, referees=referees)

    @app.route("/matches/<mid>/delete", methods=["POST"])
    @admin_required
    def match_delete(mid):
        try:
            execute_query("DELETE FROM MATCH_EVENT WHERE MatchID = %s", [mid], fetch=False)
            execute_query("DELETE FROM PLAYER_MATCH_STATS WHERE MatchID = %s", [mid], fetch=False)
            execute_query("DELETE FROM MATCH WHERE MatchID = %s", [mid], fetch=False)
            flash("Match deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("matches"))
