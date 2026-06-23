from flask import render_template, request, redirect, url_for, flash
from db_connection import execute_query
from . import admin_required


def init_routes(app):
    @app.route("/events")
    def events():
        q = request.args.get("q", "")
        where = "WHERE (givenname ILIKE %s OR familyname ILIKE %s)" if q else ""
        params = [f"%{q}%", f"%{q}%"] if q else []
        _, rows, _ = execute_query(
            f"SELECT * FROM vw_events_list {where}", params
        )
        return render_template("events.html", events=rows, q=q)

    @app.route("/events/add", methods=["POST"])
    @admin_required
    def event_add():
        eid = request.form.get("eid")
        minute = request.form.get("minute")
        etype = request.form.get("etype")
        match_id = request.form.get("match_id")
        player_id = request.form.get("player_id")
        try:
            execute_query(
                "CALL sp_event_insert(%s,%s,%s,%s,%s)",
                [eid, minute, etype, match_id, player_id], fetch=False
            )
            flash("Event added successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("events"))

    @app.route("/events/<eid>/delete", methods=["POST"])
    @admin_required
    def event_delete(eid):
        try:
            execute_query("CALL sp_event_delete(%s)", [eid], fetch=False)
            flash("Event deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("events"))
