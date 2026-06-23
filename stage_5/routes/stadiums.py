from flask import render_template, request, redirect, url_for, flash
from db_connection import execute_query
from . import admin_required


def init_routes(app):
    @app.route("/stadiums")
    def stadiums():
        q = request.args.get("q", "")
        where = "WHERE s.Name ILIKE %s" if q else ""
        params = [f"%{q}%"] if q else []
        _, rows, _ = execute_query(f"""
            SELECT s.StadiumID, s.Name, s.City, s.Capacity, s.Country,
                   COUNT(DISTINCT m.MatchID) AS MatchesHosted
            FROM STADIUM s LEFT JOIN MATCH m ON s.StadiumID = m.StadiumID
            {where}
            GROUP BY s.StadiumID, s.Name, s.City, s.Capacity, s.Country
            ORDER BY s.Capacity DESC
        """, params)
        return render_template("stadiums.html", stadiums=rows, q=q)

    @app.route("/stadiums/add", methods=["POST"])
    @admin_required
    def stadium_add():
        sid = request.form.get("sid")
        name = request.form.get("name")
        city = request.form.get("city")
        capacity = request.form.get("capacity")
        country = request.form.get("country")
        wiki = request.form.get("wiki")
        try:
            execute_query(
                "INSERT INTO STADIUM (StadiumID, Name, City, Capacity, Country, WikipediaPage) VALUES (%s,%s,%s,%s,%s,%s)",
                [sid, name, city, capacity, country, wiki], fetch=False
            )
            flash("Stadium added successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("stadiums"))

    @app.route("/stadiums/<sid>/edit", methods=["POST"])
    @admin_required
    def stadium_edit(sid):
        name = request.form.get("name")
        city = request.form.get("city")
        capacity = request.form.get("capacity")
        country = request.form.get("country")
        wiki = request.form.get("wiki")
        try:
            execute_query(
                "UPDATE STADIUM SET Name=%s, City=%s, Capacity=%s, Country=%s, WikipediaPage=%s WHERE StadiumID=%s",
                [name, city, capacity, country, wiki, sid], fetch=False
            )
            flash("Stadium updated successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("stadiums"))

    @app.route("/stadiums/<sid>/delete", methods=["POST"])
    @admin_required
    def stadium_delete(sid):
        try:
            execute_query("DELETE FROM STADIUM WHERE StadiumID = %s", [sid], fetch=False)
            flash("Stadium deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("stadiums"))
