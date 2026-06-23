from flask import render_template, request, redirect, url_for, flash
from db_connection import execute_query
from . import admin_required


def init_routes(app):
    @app.route("/players")
    def players():
        q = request.args.get("q", "")
        where = "WHERE (per.GivenName ILIKE %s OR per.FamilyName ILIKE %s)" if q else ""
        params = [f"%{q}%", f"%{q}%"] if q else []
        _, rows, _ = execute_query(f"""
            SELECT p.ID, per.GivenName, per.FamilyName, p.DateOfBirth,
                   t.CountryName AS Team, COUNT(me.MatchEventID) AS Events
            FROM PLAYER p
            JOIN PERSON per ON p.ID = per.ID
            JOIN TEAM t ON p.TeamCode = t.TeamCode
            LEFT JOIN MATCH_EVENT me ON p.ID = me.ID
            {where}
            GROUP BY p.ID, per.GivenName, per.FamilyName, p.DateOfBirth, t.CountryName
            ORDER BY per.FamilyName
            LIMIT 200
        """, params)
        _, teams, _ = execute_query("SELECT TeamCode, CountryName FROM TEAM ORDER BY CountryName")
        return render_template("players.html", players=rows, teams=teams, q=q)

    @app.route("/players/<pid>")
    def player_detail(pid):
        cols, rows, _ = execute_query("""
            SELECT p.ID, per.GivenName, per.FamilyName, per.WikipediaPage,
                   p.DateOfBirth, t.CountryName AS Team, t.TeamCode
            FROM PLAYER p
            JOIN PERSON per ON p.ID = per.ID
            JOIN TEAM t ON p.TeamCode = t.TeamCode
            WHERE p.ID = %s
        """, [pid])
        if not rows:
            flash("Player not found.", "error")
            return redirect(url_for("players"))
        player = dict(zip([c.lower() for c in cols], rows[0]))

        _, events, _ = execute_query("""
            SELECT me.MatchEventID, me.Minute, me.EventType,
                   m.MatchDate, m.Stage,
                   ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam
            FROM MATCH_EVENT me
            JOIN MATCH m ON me.MatchID = m.MatchID
            JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
            JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
            WHERE me.ID = %s ORDER BY m.MatchDate DESC
        """, [pid])

        _, stats, _ = execute_query("""
            SELECT m.MatchDate, ht.CountryName AS Home, gt.CountryName AS Away,
                   pms.Position, pms.ShirtNumber
            FROM PLAYER_MATCH_STATS pms
            JOIN MATCH m ON pms.MatchID = m.MatchID
            JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
            JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
            WHERE pms.PlayerID = %s ORDER BY m.MatchDate DESC
        """, [pid])

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
            execute_query("UPDATE PLAYER SET DateOfBirth=%s, TeamCode=%s WHERE ID=%s",
                          [dob, team_code, pid], fetch=False)
            execute_query("UPDATE PERSON SET GivenName=%s, FamilyName=%s, WikipediaPage=%s WHERE ID=%s",
                          [given_name, family_name, wiki, pid], fetch=False)
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
                "INSERT INTO PERSON (ID, GivenName, FamilyName, WikipediaPage) VALUES (%s,%s,%s,%s)",
                [pid, given, family, wiki], fetch=False
            )
            execute_query(
                "INSERT INTO PLAYER (ID, DateOfBirth, TeamCode) VALUES (%s,%s,%s)",
                [pid, dob, team], fetch=False
            )
            flash("Player added successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("players"))

    @app.route("/players/<pid>/delete", methods=["POST"])
    @admin_required
    def player_delete(pid):
        try:
            execute_query("DELETE FROM MATCH_EVENT WHERE ID = %s", [pid], fetch=False)
            execute_query("DELETE FROM PLAYER_MATCH_STATS WHERE PlayerID = %s", [pid], fetch=False)
            execute_query("DELETE FROM PLAYER WHERE ID = %s", [pid], fetch=False)
            execute_query("DELETE FROM PERSON WHERE ID = %s", [pid], fetch=False)
            flash("Player deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("players"))
