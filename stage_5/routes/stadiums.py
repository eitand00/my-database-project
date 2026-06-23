from flask import render_template, request, redirect, url_for, flash
from db_helpers import (
    get_stadiums_list, create_stadium, update_stadium, delete_stadium
)
from . import admin_required


def init_routes(app):
    @app.route("/stadiums")
    def stadiums():
        q = request.args.get("q", "")
        rows = get_stadiums_list(search=q or None)
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
            create_stadium(sid, name, city, capacity, country, wiki)
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
            update_stadium(sid, name, city, capacity, country, wiki)
            flash("Stadium updated successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("stadiums"))

    @app.route("/stadiums/<sid>/delete", methods=["POST"])
    @admin_required
    def stadium_delete(sid):
        try:
            delete_stadium(sid)
            flash("Stadium deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("stadiums"))
