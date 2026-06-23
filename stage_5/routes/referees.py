from flask import render_template, request, redirect, url_for, flash
from db_connection import execute_query
from . import admin_required


def init_routes(app):
    @app.route("/referees")
    def referees():
        q = request.args.get("q", "")
        where = "WHERE (per.GivenName ILIKE %s OR per.FamilyName ILIKE %s)" if q else ""
        params = [f"%{q}%", f"%{q}%"] if q else []
        _, rows, _ = execute_query(f"""
            SELECT r.ID, per.GivenName || ' ' || per.FamilyName AS FullName,
                   r.Country, r.ConfederationName,
                   COUNT(DISTINCT m.MatchID) AS MatchesOfficiated
            FROM REFEREE r
            JOIN PERSON per ON r.ID = per.ID
            LEFT JOIN MATCH m ON r.ID = m.RefereeID
            {where}
            GROUP BY r.ID, per.GivenName, per.FamilyName, r.Country, r.ConfederationName
            ORDER BY per.FamilyName
        """, params)
        return render_template("referees.html", referees=rows, q=q)

    @app.route("/referees/add", methods=["POST"])
    @admin_required
    def referee_add():
        rid = request.form.get("rid")
        country = request.form.get("country")
        conf_code = request.form.get("conf_code")
        conf_name = request.form.get("conf_name")
        given = request.form.get("given_name")
        family = request.form.get("family_name")
        wiki = request.form.get("wiki")
        try:
            execute_query("INSERT INTO PERSON (ID, GivenName, FamilyName, WikipediaPage) VALUES (%s,%s,%s,%s)",
                          [rid, given, family, wiki], fetch=False)
            execute_query("INSERT INTO REFEREE (ID, Country, ConfederationCode, ConfederationName) VALUES (%s,%s,%s,%s)",
                          [rid, country, conf_code, conf_name], fetch=False)
            flash("Referee added successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("referees"))

    @app.route("/referees/<rid>/edit", methods=["POST"])
    @admin_required
    def referee_edit(rid):
        country = request.form.get("country")
        conf_code = request.form.get("conf_code")
        conf_name = request.form.get("conf_name")
        given = request.form.get("given_name")
        family = request.form.get("family_name")
        try:
            execute_query("UPDATE PERSON SET GivenName=%s, FamilyName=%s WHERE ID=%s",
                          [given, family, rid], fetch=False)
            execute_query("UPDATE REFEREE SET Country=%s, ConfederationCode=%s, ConfederationName=%s WHERE ID=%s",
                          [country, conf_code, conf_name, rid], fetch=False)
            flash("Referee updated successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("referees"))

    @app.route("/referees/<rid>/delete", methods=["POST"])
    @admin_required
    def referee_delete(rid):
        try:
            execute_query("DELETE FROM REFEREE WHERE ID = %s", [rid], fetch=False)
            execute_query("DELETE FROM PERSON WHERE ID = %s", [rid], fetch=False)
            flash("Referee deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("referees"))
