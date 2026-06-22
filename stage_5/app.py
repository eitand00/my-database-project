from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from db_connection import execute_query, execute_procedure_call
import os

app = Flask(__name__)
app.secret_key = os.urandom(24)


@app.route("/")
def index():
    try:
        _, match_count = execute_query("SELECT COUNT(*) FROM MATCH")
        _, team_count = execute_query("SELECT COUNT(*) FROM TEAM")
        _, player_count = execute_query("SELECT COUNT(*) FROM PLAYER")
        _, stadium_count = execute_query("SELECT COUNT(*) FROM STADIUM")
        _, event_count = execute_query("SELECT COUNT(*) FROM MATCH_EVENT")

        mc = match_count[0][0] if match_count else 0
        tc = team_count[0][0] if team_count else 0
        pc = player_count[0][0] if player_count else 0
        sc = stadium_count[0][0] if stadium_count else 0
        ec = event_count[0][0] if event_count else 0
    except Exception as e:
        mc = tc = pc = sc = ec = 0
        flash(f"Database connection error: {str(e)}", "error")

    return render_template("index.html", match_count=mc, team_count=tc,
                           player_count=pc, stadium_count=sc, event_count=ec)


@app.route("/teams")
def teams():
    _, rows = execute_query("""
        SELECT t.TeamCode, t.CountryName, t.ConfederationName,
               COUNT(DISTINCT p.ID) AS PlayerCount,
               COUNT(DISTINCT m.MatchID) AS MatchCount
        FROM TEAM t
        LEFT JOIN PLAYER p ON t.TeamCode = p.TeamCode
        LEFT JOIN MATCH m ON t.TeamCode IN (m.HomeTeamCode, m.GuestTeamCode)
        GROUP BY t.TeamCode, t.CountryName, t.ConfederationName
        ORDER BY t.CountryName
    """)
    return render_template("teams.html", teams=rows)


@app.route("/teams/<code>")
def team_detail(code):
    if request.method == "GET":
        cols, rows = execute_query("SELECT * FROM TEAM WHERE TeamCode = %s", [code])
        if not rows:
            flash("Team not found.", "error")
            return redirect(url_for("teams"))
        team = dict(zip([c.lower() for c in cols], rows[0]))

        _, players = execute_query("""
            SELECT p.ID, per.GivenName || ' ' || per.FamilyName AS FullName,
                   p.DateOfBirth
            FROM PLAYER p JOIN PERSON per ON p.ID = per.ID
            WHERE p.TeamCode = %s ORDER BY per.FamilyName
        """, [code])

        _, matches = execute_query("""
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
    cols, rows = execute_query("SELECT * FROM TEAM WHERE TeamCode = %s", [code])
    if not rows:
        flash("Team not found.", "error")
        return redirect(url_for("teams"))
    team = dict(zip([c.lower() for c in cols], rows[0]))
    return render_template("team_edit.html", team=team)


@app.route("/teams/add", methods=["GET", "POST"])
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
def team_delete(code):
    try:
        execute_query("DELETE FROM TEAM WHERE TeamCode = %s", [code], fetch=False)
        flash("Team deleted successfully!", "success")
    except Exception as e:
        flash(f"Error: {str(e)}", "error")
    return redirect(url_for("teams"))


@app.route("/players")
def players():
    _, rows = execute_query("""
        SELECT p.ID, per.GivenName, per.FamilyName, p.DateOfBirth,
               t.CountryName AS Team, COUNT(me.MatchEventID) AS Events
        FROM PLAYER p
        JOIN PERSON per ON p.ID = per.ID
        JOIN TEAM t ON p.TeamCode = t.TeamCode
        LEFT JOIN MATCH_EVENT me ON p.ID = me.ID
        GROUP BY p.ID, per.GivenName, per.FamilyName, p.DateOfBirth, t.CountryName
        ORDER BY per.FamilyName
        LIMIT 200
    """)
    _, teams = execute_query("SELECT TeamCode, CountryName FROM TEAM ORDER BY CountryName")
    return render_template("players.html", players=rows, teams=teams)


@app.route("/players/<pid>")
def player_detail(pid):
    cols, rows = execute_query("""
        SELECT p.ID, per.GivenName, per.FamilyName, per.WikipediaPage,
               p.DateOfBirth, t.CountryName AS Team, t.TeamCode
        FROM PLAYER p
        JOIN PERSON per ON p.ID = per.ID
        JOIN TEAM t ON p.TeamCode = t.TeamCode
        WHERE p.ID = %s
    """, [pid])
    if not rows:
        flash("Player not found.", "error")
        return redirect(url_for("players"))
    player = dict(zip([c.lower() for c in cols], rows[0]))

    _, events = execute_query("""
        SELECT me.MatchEventID, me.Minute, me.EventType,
               m.MatchDate, m.Stage,
               ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam
        FROM MATCH_EVENT me
        JOIN MATCH m ON me.MatchID = m.MatchID
        JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
        JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
        WHERE me.ID = %s ORDER BY m.MatchDate DESC
    """, [pid])

    _, stats = execute_query("""
        SELECT m.MatchDate, ht.CountryName AS Home, gt.CountryName AS Away,
               pms.Position, pms.ShirtNumber
        FROM PLAYER_MATCH_STATS pms
        JOIN MATCH m ON pms.MatchID = m.MatchID
        JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
        JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
        WHERE pms.PlayerID = %s ORDER BY m.MatchDate DESC
    """, [pid])

    return render_template("player_detail.html", player=player, events=events, stats=stats)


@app.route("/players/<pid>/edit", methods=["POST"])
def player_edit(pid):
    dob = request.form.get("dateofbirth")
    team_code = request.form.get("team_code")
    given_name = request.form.get("given_name")
    family_name = request.form.get("family_name")
    wiki = request.form.get("wiki")
    try:
        execute_query("UPDATE PLAYER SET DateOfBirth=%s, TeamCode=%s WHERE ID=%s",
                      [dob, team_code, pid], fetch=False)
        execute_query("UPDATE PERSON SET GivenName=%s, FamilyName=%s, WikipediaPage=%s WHERE ID=%s",
                      [given_name, family_name, wiki, pid], fetch=False)
        flash("Player updated successfully!", "success")
    except Exception as e:
        flash(f"Error: {str(e)}", "error")
    return redirect(url_for("player_detail", pid=pid))


@app.route("/players/add", methods=["POST"])
def player_add():
    pid = request.form.get("pid")
    given = request.form.get("given_name")
    family = request.form.get("family_name")
    wiki = request.form.get("wiki")
    dob = request.form.get("dateofbirth")
    team = request.form.get("team_code")
    try:
        execute_query(
            "INSERT INTO PERSON (ID, GivenName, FamilyName, WikipediaPage) VALUES (%s,%s,%s,%s)",
            [pid, given, family, wiki], fetch=False
        )
        execute_query(
            "INSERT INTO PLAYER (ID, DateOfBirth, TeamCode) VALUES (%s,%s,%s)",
            [pid, dob, team], fetch=False
        )
        flash("Player added successfully!", "success")
    except Exception as e:
        flash(f"Error: {str(e)}", "error")
    return redirect(url_for("players"))


@app.route("/players/<pid>/delete", methods=["POST"])
def player_delete(pid):
    try:
        execute_query("DELETE FROM MATCH_EVENT WHERE ID = %s", [pid], fetch=False)
        execute_query("DELETE FROM PLAYER_MATCH_STATS WHERE PlayerID = %s", [pid], fetch=False)
        execute_query("DELETE FROM PLAYER WHERE ID = %s", [pid], fetch=False)
        execute_query("DELETE FROM PERSON WHERE ID = %s", [pid], fetch=False)
        flash("Player deleted successfully!", "success")
    except Exception as e:
        flash(f"Error: {str(e)}", "error")
    return redirect(url_for("players"))


@app.route("/matches")
def matches():
    _, rows = execute_query("""
        SELECT m.MatchID, m.MatchDate, m.Stage, m.Tournament,
               ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
               s.Name AS Stadium,
               (SELECT COUNT(*) FROM MATCH_EVENT me WHERE me.MatchID = m.MatchID AND me.EventType = 'Goal') AS Goals
        FROM MATCH m
        JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
        JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
        JOIN STADIUM s ON m.StadiumID = s.StadiumID
        ORDER BY m.MatchDate DESC
        LIMIT 200
    """)
    return render_template("matches.html", matches=rows)


@app.route("/matches/<mid>")
def match_detail(mid):
    cols, rows = execute_query("""
        SELECT m.*, s.Name AS StadiumName,
               ht.CountryName AS HomeTeam, gt.CountryName AS GuestTeam,
               per.GivenName || ' ' || per.FamilyName AS RefereeName
        FROM MATCH m
        JOIN STADIUM s ON m.StadiumID = s.StadiumID
        JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
        JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
        JOIN REFEREE r ON m.RefereeID = r.ID
        JOIN PERSON per ON r.ID = per.ID
        WHERE m.MatchID = %s
    """, [mid])
    if not rows:
        flash("Match not found.", "error")
        return redirect(url_for("matches"))
    match = dict(zip([c.lower() for c in cols], rows[0]))

    _, events = execute_query("""
        SELECT me.MatchEventID, me.Minute, me.EventType,
               per.GivenName || ' ' || per.FamilyName AS PlayerName
        FROM MATCH_EVENT me
        JOIN PLAYER pl ON me.ID = pl.ID
        JOIN PERSON per ON pl.ID = per.ID
        WHERE me.MatchID = %s ORDER BY me.Minute::int ASC
    """, [mid])

    _, stats = execute_query("""
        SELECT per.GivenName || ' ' || per.FamilyName AS PlayerName,
               pms.Position, pms.ShirtNumber
        FROM PLAYER_MATCH_STATS pms
        JOIN PLAYER pl ON pms.PlayerID = pl.ID
        JOIN PERSON per ON pl.ID = per.ID
        WHERE pms.MatchID = %s ORDER BY pms.ShirtNumber
    """, [mid])

    return render_template("match_detail.html", match=match, events=events, stats=stats)


@app.route("/matches/add", methods=["GET", "POST"])
def match_add():
    if request.method == "POST":
        mid = request.form.get("matchid")
        mdate = request.form.get("matchdate")
        stage = request.form.get("stage")
        tournament = request.form.get("tournament")
        time = request.form.get("matchtime")
        stadium = request.form.get("stadium")
        home = request.form.get("home")
        guest = request.form.get("guest")
        referee = request.form.get("referee")
        try:
            execute_query(
                "INSERT INTO MATCH (MatchID, MatchDate, Stage, Tournament, MatchTime, StadiumID, HomeTeamCode, GuestTeamCode, RefereeID) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)",
                [mid, mdate, stage, tournament, time, stadium, home, guest, referee], fetch=False
            )
            flash("Match added successfully!", "success")
            return redirect(url_for("matches"))
        except Exception as e:
            flash(f"Error: {str(e)}", "error")

    _, teams = execute_query("SELECT TeamCode, CountryName FROM TEAM ORDER BY CountryName")
    _, stadiums = execute_query("SELECT StadiumID, Name FROM STADIUM ORDER BY Name")
    _, referees = execute_query("""
        SELECT r.ID, per.GivenName || ' ' || per.FamilyName AS Name
        FROM REFEREE r JOIN PERSON per ON r.ID = per.ID ORDER BY per.FamilyName
    """)
    return render_template("match_form.html", match=None, teams=teams, stadiums=stadiums, referees=referees)


@app.route("/matches/<mid>/edit", methods=["GET", "POST"])
def match_edit(mid):
    if request.method == "POST":
        mdate = request.form.get("matchdate")
        stage = request.form.get("stage")
        tournament = request.form.get("tournament")
        time = request.form.get("matchtime")
        stadium = request.form.get("stadium")
        home = request.form.get("home")
        guest = request.form.get("guest")
        referee = request.form.get("referee")
        try:
            execute_query(
                "UPDATE MATCH SET MatchDate=%s, Stage=%s, Tournament=%s, MatchTime=%s, StadiumID=%s, HomeTeamCode=%s, GuestTeamCode=%s, RefereeID=%s WHERE MatchID=%s",
                [mdate, stage, tournament, time, stadium, home, guest, referee, mid], fetch=False
            )
            flash("Match updated successfully!", "success")
            return redirect(url_for("match_detail", mid=mid))
        except Exception as e:
            flash(f"Error: {str(e)}", "error")

    cols, rows = execute_query("SELECT * FROM MATCH WHERE MatchID = %s", [mid])
    if not rows:
        flash("Match not found.", "error")
        return redirect(url_for("matches"))
    match = dict(zip([c.lower() for c in cols], rows[0]))
    _, teams = execute_query("SELECT TeamCode, CountryName FROM TEAM ORDER BY CountryName")
    _, stadiums = execute_query("SELECT StadiumID, Name FROM STADIUM ORDER BY Name")
    _, referees = execute_query("""
        SELECT r.ID, per.GivenName || ' ' || per.FamilyName AS Name
        FROM REFEREE r JOIN PERSON per ON r.ID = per.ID ORDER BY per.FamilyName
    """)
    return render_template("match_form.html", match=match, teams=teams, stadiums=stadiums, referees=referees)


@app.route("/matches/<mid>/delete", methods=["POST"])
def match_delete(mid):
    try:
        execute_query("DELETE FROM MATCH_EVENT WHERE MatchID = %s", [mid], fetch=False)
        execute_query("DELETE FROM PLAYER_MATCH_STATS WHERE MatchID = %s", [mid], fetch=False)
        execute_query("DELETE FROM MATCH WHERE MatchID = %s", [mid], fetch=False)
        flash("Match deleted successfully!", "success")
    except Exception as e:
        flash(f"Error: {str(e)}", "error")
    return redirect(url_for("matches"))


@app.route("/stadiums")
def stadiums():
    _, rows = execute_query("""
        SELECT s.StadiumID, s.Name, s.City, s.Capacity, s.Country,
               COUNT(DISTINCT m.MatchID) AS MatchesHosted
        FROM STADIUM s LEFT JOIN MATCH m ON s.StadiumID = m.StadiumID
        GROUP BY s.StadiumID, s.Name, s.City, s.Capacity, s.Country
        ORDER BY s.Capacity DESC
    """)
    return render_template("stadiums.html", stadiums=rows)


@app.route("/stadiums/add", methods=["POST"])
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
def stadium_delete(sid):
    try:
        execute_query("DELETE FROM STADIUM WHERE StadiumID = %s", [sid], fetch=False)
        flash("Stadium deleted successfully!", "success")
    except Exception as e:
        flash(f"Error: {str(e)}", "error")
    return redirect(url_for("stadiums"))


@app.route("/referees")
def referees():
    _, rows = execute_query("""
        SELECT r.ID, per.GivenName || ' ' || per.FamilyName AS FullName,
               r.Country, r.ConfederationName,
               COUNT(DISTINCT m.MatchID) AS MatchesOfficiated
        FROM REFEREE r
        JOIN PERSON per ON r.ID = per.ID
        LEFT JOIN MATCH m ON r.ID = m.RefereeID
        GROUP BY r.ID, per.GivenName, per.FamilyName, r.Country, r.ConfederationName
        ORDER BY per.FamilyName
    """)
    return render_template("referees.html", referees=rows)


@app.route("/referees/add", methods=["POST"])
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
def referee_delete(rid):
    try:
        execute_query("DELETE FROM REFEREE WHERE ID = %s", [rid], fetch=False)
        execute_query("DELETE FROM PERSON WHERE ID = %s", [rid], fetch=False)
        flash("Referee deleted successfully!", "success")
    except Exception as e:
        flash(f"Error: {str(e)}", "error")
    return redirect(url_for("referees"))


@app.route("/events")
def events():
    _, rows = execute_query("""
        SELECT me.MatchEventID, me.Minute, me.EventType,
               ht.CountryName || ' vs ' || gt.CountryName AS MatchName,
               per.GivenName || ' ' || per.FamilyName AS PlayerName
        FROM MATCH_EVENT me
        JOIN MATCH m ON me.MatchID = m.MatchID
        JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
        JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
        JOIN PLAYER pl ON me.ID = pl.ID
        JOIN PERSON per ON pl.ID = per.ID
        ORDER BY me.MatchEventID
        LIMIT 200
    """)
    return render_template("events.html", events=rows)


@app.route("/events/add", methods=["POST"])
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
def event_delete(eid):
    try:
        execute_query("DELETE FROM MATCH_EVENT WHERE MatchEventID = %s", [eid], fetch=False)
        flash("Event deleted successfully!", "success")
    except Exception as e:
        flash(f"Error: {str(e)}", "error")
    return redirect(url_for("events"))


@app.route("/queries")
def queries():
    return render_template("queries.html")


@app.route("/api/query", methods=["POST"])
def api_query():
    sql = request.json.get("sql")
    try:
        cols, rows = execute_query(sql)
        return jsonify({"success": True, "columns": cols, "rows": [[str(c) if c is not None else "" for c in r] for r in rows]})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})


@app.route("/api/execute", methods=["POST"])
def api_execute():
    sql = request.json.get("sql")
    params = request.json.get("params", [])
    try:
        cols, rows = execute_query(sql, params)
        if cols:
            return jsonify({"success": True, "columns": cols, "rows": [[str(c) if c is not None else "" for c in r] for r in rows]})
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})


@app.route("/procedures")
def procedures():
    return render_template("procedures.html")


if __name__ == "__main__":
    print("=" * 60)
    print("  World Cup Database Manager - Web Interface")
    print("  Running at: http://localhost:5000")
    print("=" * 60)
    app.run(debug=True, host="0.0.0.0", port=5000)
