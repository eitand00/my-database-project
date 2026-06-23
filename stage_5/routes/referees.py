from flask import render_template, request, redirect, url_for, flash
from db_connection import execute_query
from . import admin_required


def init_routes(app):
    @app.route("/referees")
    def referees():
        q = request.args.get("q", "")
        where = "WHERE (givenname ILIKE %s OR familyname ILIKE %s)" if q else ""
        params = [f"%{q}%", f"%{q}%"] if q else []
        _, rows, _ = execute_query(
            f"SELECT * FROM vw_referees_list {where}", params
        )
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
            execute_query(
                "CALL sp_referee_insert(%s,%s,%s,%s,%s,%s,%s)",
                [rid, country, conf_code, conf_name, given, family, wiki], fetch=False
            )
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
            execute_query(
                "CALL sp_referee_update(%s,%s,%s,%s,%s,%s)",
                [rid, country, conf_code, conf_name, given, family], fetch=False
            )
            flash("Referee updated successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("referees"))

    @app.route("/referees/<rid>/delete", methods=["POST"])
    @admin_required
    def referee_delete(rid):
        try:
            execute_query("CALL sp_referee_delete(%s)", [rid], fetch=False)
            flash("Referee deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("referees"))
