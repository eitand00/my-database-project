from flask import Flask, render_template, session, flash
from dotenv import load_dotenv
import os

load_dotenv(os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env"))

app = Flask(__name__)
app.secret_key = os.urandom(24)


@app.context_processor
def inject_admin():
    return {"is_admin": session.get("is_admin", False)}


from db_helpers import get_dashboard_counts
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
        counts = get_dashboard_counts()
    except Exception as e:
        counts = {"match_count": 0, "team_count": 0, "player_count": 0,
                  "stadium_count": 0, "event_count": 0}
        flash(f"Database connection error: {str(e)}", "error")

    return render_template("index.html", **counts)


if __name__ == "__main__":
    print("=" * 60)
    print("  World Cup Database Manager - Web Interface")
    print("  Running at: http://localhost:5000")
    print("=" * 60)
    app.run(debug=True, host="0.0.0.0", port=5000)
