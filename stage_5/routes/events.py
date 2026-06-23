from flask import render_template, request, redirect, url_for, flash
from db_helpers import (
    get_events_list, create_event, delete_event
)
from . import admin_required


def init_routes(app):
    @app.route("/events")
    def events():
        q = request.args.get("q", "")
        rows = get_events_list(search=q or None)
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
            create_event(eid, minute, etype, match_id, player_id)
            flash("Event added successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("events"))

    @app.route("/events/<eid>/delete", methods=["POST"])
    @admin_required
    def event_delete(eid):
        try:
            delete_event(eid)
            flash("Event deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("events"))
