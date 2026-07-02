from flask import render_template, request, redirect, url_for, flash
from db_connection import (
    get_referees_list, create_referee, update_referee, delete_referee
)
from . import admin_required


def init_routes(app):
    @app.route("/referees")
    def referees():
        q = request.args.get("q", "")
        rows = get_referees_list(search=q or None)
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
            create_referee(rid, country, conf_code, conf_name, given, family, wiki)
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
            update_referee(rid, country, conf_code, conf_name, given, family)
            flash("Referee updated successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("referees"))

    @app.route("/referees/<rid>/delete", methods=["POST"])
    @admin_required
    def referee_delete(rid):
        try:
            delete_referee(rid)
            flash("Referee deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("referees"))
