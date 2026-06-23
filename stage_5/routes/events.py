from flask import render_template, request, redirect, url_for, flash
from db_connection import execute_query
from . import admin_required


def init_routes(app):
    @app.route("/events")
    def events():
        q = request.args.get("q", "")
        where = "WHERE (per.GivenName ILIKE %s OR per.FamilyName ILIKE %s)" if q else ""
        params = [f"%{q}%", f"%{q}%"] if q else []
        _, rows, _ = execute_query(f"""
            SELECT me.MatchEventID, me.Minute, me.EventType,
                   ht.CountryName || ' vs ' || gt.CountryName AS MatchName,
                   per.GivenName || ' ' || per.FamilyName AS PlayerName
            FROM MATCH_EVENT me
            JOIN MATCH m ON me.MatchID = m.MatchID
            JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
            JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
            JOIN PLAYER pl ON me.ID = pl.ID
            JOIN PERSON per ON pl.ID = per.ID
            {where}
            ORDER BY me.MatchEventID
            LIMIT 200
        """, params)
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
                "INSERT INTO MATCH_EVENT (MatchEventID, Minute, EventType, MatchID, ID) VALUES (%s,%s,%s,%s,%s)",
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
            execute_query("DELETE FROM MATCH_EVENT WHERE MatchEventID = %s", [eid], fetch=False)
            flash("Event deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "error")
        return redirect(url_for("events"))
