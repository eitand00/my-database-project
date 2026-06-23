from flask import Flask, render_template, session, flash
from dotenv import load_dotenv
import os

load_dotenv(os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env"))

app = Flask(__name__)
app.secret_key = os.urandom(24)


@app.context_processor
def inject_admin():
    return {"is_admin": session.get("is_admin", False)}


from db_connection import execute_query
from routes import admin_required
from routes.teams import init_routes as init_teams
from routes.players import init_routes as init_players
from routes.matches import init_routes as init_matches
from routes.stadiums import init_routes as init_stadiums
from routes.referees import init_routes as init_referees
from routes.events import init_routes as init_events
from routes.procs import init_routes as init_procs
from routes.reports import init_routes as init_reports
from routes.auth import init_routes as init_auth

init_teams(app)
init_players(app)
init_matches(app)
init_stadiums(app)
init_referees(app)
init_events(app)
init_procs(app)
init_reports(app)
init_auth(app)


@app.route("/")
def index():
    try:
        _, match_count, _ = execute_query("SELECT COUNT(*) FROM MATCH")
        _, team_count, _ = execute_query("SELECT COUNT(*) FROM TEAM")
        _, player_count, _ = execute_query("SELECT COUNT(*) FROM PLAYER")
        _, stadium_count, _ = execute_query("SELECT COUNT(*) FROM STADIUM")
        _, event_count, _ = execute_query("SELECT COUNT(*) FROM MATCH_EVENT")

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


if __name__ == "__main__":
    print("=" * 60)
    print("  World Cup Database Manager - Web Interface")
    print("  Running at: http://localhost:5000")
    print("=" * 60)
    app.run(debug=True, host="0.0.0.0", port=5000)
