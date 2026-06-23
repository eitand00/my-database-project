from flask import render_template, request, redirect, url_for, flash
from db_connection import execute_query
from . import admin_required


def init_routes(app):
    @app.route("/teams")
    def teams():
        q = request.args.get("q", "")
        where = "WHERE t.CountryName ILIKE %s" if q else ""
        params = [f"%{q}%"] if q else []
        _, rows, _ = execute_query(f"""
            SELECT t.TeamCode, t.CountryName, t.ConfederationName,
                   COUNT(DISTINCT p.ID) AS PlayerCount,
                   COUNT(DISTINCT m.MatchID) AS MatchCount
            FROM TEAM t
            LEFT JOIN PLAYER p ON t.TeamCode = p.TeamCode
            LEFT JOIN MATCH m ON t.TeamCode IN (m.HomeTeamCode, m.GuestTeamCode)
            {where}
            GROUP BY t.TeamCode, t.CountryName, t.ConfederationName
            ORDER BY t.CountryName
        """, params)
        return render_template("teams.html", teams=rows, q=q)

    @app.route("/teams/<code>")
    def team_detail(code):
        cols, rows, _ = execute_query("SELECT * FROM TEAM WHERE TeamCode = %s", [code])
        if not rows:
            flash("Team not found.", "error")
            return redirect(url_for("teams"))
        team = dict(zip([c.lower() for c in cols], rows[0]))

        _, players, _ = execute_query("""
            SELECT p.ID, per.GivenName || ' ' || per.FamilyName AS FullName,
                   p.DateOfBirth
            FROM PLAYER p JOIN PERSON per ON p.ID = per.ID
            WHERE p.TeamCode = %s ORDER BY per.FamilyName
        """, [code])

        _, matches, _ = execute_query("""
            SELECT m.MatchID, m.MatchDate, m.Stage,
                   ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam
            FROM MATCH m
            JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
            JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
            WHERE m.HomeTeamCode = %s OR m.GuestTeamCode = %s
            ORDER BY m.MatchDate DESC LIMIT 20
        """, [code, code])

        return render_template("team_detail.html", team=team, players=players, matches=matches)

    @app.route("/teams/<code>/edit", methods=["GET", "POST"])
    @admin_required
    def team_edit(code):
        if request.method == "POST":
            country = request.form.get("country")
            conf_name = request.form.get("conf_name")
            conf_code = request.form.get("conf_code")
            wiki = request.form.get("wiki")
            execute_query(
                "UPDATE TEAM SET CountryName=%s, ConfederationName=%s, ConfederationCode=%s, WikipediaPage=%s WHERE TeamCode=%s",
                [country, conf_name, conf_code, wiki, code], fetch=False
            )
            flash("Team updated successfully!", "success")
            return redirect(url_for("team_detail", code=code))
        cols, rows, _ = execute_query("SELECT * FROM TEAM WHERE TeamCode = %s", [code])
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
                    "INSERT INTO TEAM (TeamCode, CountryName, ConfederationName, ConfederationCode, WikipediaPage) VALUES (%s,%s,%s,%s,%s)",
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
            execute_query("DELETE FROM TEAM WHERE TeamCode = %s", [code], fetch=False)
            flash("Team deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("teams"))
