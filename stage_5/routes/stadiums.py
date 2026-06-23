from flask import render_template, request, redirect, url_for, flash
from db_connection import execute_query
from . import admin_required


def init_routes(app):
    @app.route("/stadiums")
    def stadiums():
        q = request.args.get("q", "")
        where = "WHERE name ILIKE %s" if q else ""
        params = [f"%{q}%"] if q else []
        _, rows, _ = execute_query(
            f"SELECT * FROM vw_stadiums_list {where}", params
        )
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
                "CALL sp_stadium_insert(%s,%s,%s,%s,%s,%s)",
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
                "CALL sp_stadium_update(%s,%s,%s,%s,%s,%s)",
                [sid, name, city, capacity, country, wiki], fetch=False
            )
            flash("Stadium updated successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("stadiums"))

    @app.route("/stadiums/<sid>/delete", methods=["POST"])
    @admin_required
    def stadium_delete(sid):
        try:
            execute_query("CALL sp_stadium_delete(%s)", [sid], fetch=False)
            flash("Stadium deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("stadiums"))
