import psycopg2
import os
from pathlib import Path
from dotenv import load_dotenv

dotenv_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(dotenv_path)

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "dbname": os.getenv("DB_NAME_SECRET", "world_cup_db"),
    "user": os.getenv("DB_USER_SECRET", "user_db"),
    "password": os.getenv("DB_PASSWORD_SECRET", "password_db"),
}


def get_connection():
    return psycopg2.connect(**DB_CONFIG)


def execute_query(query, params=None, fetch=True):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(query, params)
            notices = [n.strip() for n in conn.notices]
            conn.notices.clear()
            if fetch and cur.description:
                columns = [desc[0] for desc in cur.description]
                rows = cur.fetchall()
                return columns, rows, notices
            conn.commit()
            return None, None, notices
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()


def execute_procedure_call(query, params=None):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(query, params)
            conn.commit()
            if cur.description:
                columns = [desc[0] for desc in cur.description]
                rows = cur.fetchall()
                return columns, rows
            return None, None
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()


def get_teams_list(search=None):
    if search:
        return execute_query(
            "SELECT * FROM vw_teams_list WHERE countryname ILIKE %s",
            [f"%{search}%"]
        )[1]
    return execute_query("SELECT * FROM vw_teams_list")[1]


def get_team_detail(code):
    cols, rows, _ = execute_query(
        "SELECT * FROM TEAM WHERE TeamCode = %s", [code]
    )
    if not rows:
        return None
    return dict(zip([c.lower() for c in cols], rows[0]))


def get_team_players(code):
    return execute_query(
        "SELECT * FROM vw_team_players WHERE TeamCode = %s", [code]
    )[1]


def get_team_matches(code):
    return execute_query(
        "SELECT * FROM vw_team_matches WHERE HomeTeamCode = %s OR GuestTeamCode = %s",
        [code, code]
    )[1]


def create_team(code, country, conf_name, conf_code, wiki):
    execute_query(
        "CALL sp_team_insert(%s,%s,%s,%s,%s)",
        [code, country, conf_name, conf_code, wiki], fetch=False
    )


def update_team(code, country, conf_name, conf_code, wiki):
    execute_query(
        "CALL sp_team_update(%s,%s,%s,%s,%s)",
        [code, country, conf_name, conf_code, wiki], fetch=False
    )


def delete_team(code):
    execute_query("CALL sp_team_delete(%s)", [code], fetch=False)


def get_players_list(search=None):
    if search:
        return execute_query(
            "SELECT * FROM vw_players_list WHERE (givenname ILIKE %s OR familyname ILIKE %s)",
            [f"%{search}%", f"%{search}%"]
        )[1]
    return execute_query("SELECT * FROM vw_players_list")[1]


def get_player_detail(pid):
    cols, rows, _ = execute_query(
        "SELECT * FROM vw_player_detail WHERE ID = %s", [pid]
    )
    if not rows:
        return None
    return dict(zip([c.lower() for c in cols], rows[0]))


def get_player_events(pid):
    return execute_query(
        "SELECT * FROM vw_player_events WHERE PlayerID = %s", [pid]
    )[1]


def get_player_stats(pid):
    return execute_query(
        "SELECT * FROM vw_player_match_stats WHERE PlayerID = %s", [pid]
    )[1]


def create_player(pid, given, family, wiki, dob, team):
    execute_query(
        "CALL sp_player_insert(%s,%s,%s,%s,%s,%s)",
        [pid, given, family, wiki, dob, team], fetch=False
    )


def update_player(pid, dob, team_code, given_name, family_name, wiki):
    execute_query(
        "CALL sp_player_update(%s,%s,%s,%s,%s,%s)",
        [pid, dob, team_code, given_name, family_name, wiki], fetch=False
    )


def delete_player(pid):
    execute_query("CALL sp_player_delete(%s)", [pid], fetch=False)


def get_matches_list(tournament=None):
    if tournament:
        return execute_query(
            "SELECT * FROM vw_matches_list WHERE tournament = %s", [tournament]
        )[1]
    return execute_query("SELECT * FROM vw_matches_list")[1]


def get_tournaments():
    return execute_query("SELECT DISTINCT Tournament FROM MATCH ORDER BY Tournament")[1]


def get_match_detail(mid):
    cols, rows, _ = execute_query(
        "SELECT * FROM vw_match_detail WHERE MatchID = %s", [mid]
    )
    if not rows:
        return None
    return dict(zip([c.lower() for c in cols], rows[0]))


def get_match_events(mid):
    return execute_query(
        "SELECT * FROM vw_match_events WHERE MatchID = %s", [mid]
    )[1]


def get_match_player_stats(mid):
    return execute_query(
        "SELECT * FROM vw_match_player_stats WHERE MatchID = %s", [mid]
    )[1]


def get_teams_short():
    return execute_query("SELECT TeamCode, CountryName FROM TEAM ORDER BY CountryName")[1]


def get_stadiums_short():
    return execute_query("SELECT StadiumID, Name FROM STADIUM ORDER BY Name")[1]


def get_referees_short():
    return execute_query(
        "SELECT r.ID, per.GivenName || ' ' || per.FamilyName AS Name FROM REFEREE r JOIN PERSON per ON r.ID = per.ID ORDER BY per.FamilyName"
    )[1]


def create_match(mid, mdate, stage, tournament, time, stadium, home, guest, referee):
    execute_query(
        "CALL sp_match_insert(%s,%s,%s,%s,%s,%s,%s,%s,%s)",
        [mid, mdate, stage, tournament, time, stadium, home, guest, referee],
        fetch=False
    )


def update_match(mid, mdate, stage, tournament, time, stadium, home, guest, referee):
    execute_query(
        "CALL sp_match_update(%s,%s,%s,%s,%s,%s,%s,%s,%s)",
        [mid, mdate, stage, tournament, time, stadium, home, guest, referee],
        fetch=False
    )


def delete_match(mid):
    execute_query("CALL sp_match_delete(%s)", [mid], fetch=False)


def get_stadiums_list(search=None):
    if search:
        return execute_query(
            "SELECT * FROM vw_stadiums_list WHERE name ILIKE %s",
            [f"%{search}%"]
        )[1]
    return execute_query("SELECT * FROM vw_stadiums_list")[1]


def create_stadium(sid, name, city, capacity, country, wiki):
    execute_query(
        "CALL sp_stadium_insert(%s,%s,%s,%s,%s,%s)",
        [sid, name, city, capacity, country, wiki], fetch=False
    )


def update_stadium(sid, name, city, capacity, country, wiki):
    execute_query(
        "CALL sp_stadium_update(%s,%s,%s,%s,%s,%s)",
        [sid, name, city, capacity, country, wiki], fetch=False
    )


def delete_stadium(sid):
    execute_query("CALL sp_stadium_delete(%s)", [sid], fetch=False)


def get_referees_list(search=None):
    if search:
        return execute_query(
            "SELECT * FROM vw_referees_list WHERE (givenname ILIKE %s OR familyname ILIKE %s)",
            [f"%{search}%", f"%{search}%"]
        )[1]
    return execute_query("SELECT * FROM vw_referees_list")[1]


def create_referee(rid, country, conf_code, conf_name, given, family, wiki):
    execute_query(
        "CALL sp_referee_insert(%s,%s,%s,%s,%s,%s,%s)",
        [rid, country, conf_code, conf_name, given, family, wiki], fetch=False
    )


def update_referee(rid, country, conf_code, conf_name, given, family):
    execute_query(
        "CALL sp_referee_update(%s,%s,%s,%s,%s,%s)",
        [rid, country, conf_code, conf_name, given, family], fetch=False
    )


def delete_referee(rid):
    execute_query("CALL sp_referee_delete(%s)", [rid], fetch=False)


def get_events_list(search=None):
    if search:
        return execute_query(
            "SELECT * FROM vw_events_list WHERE (givenname ILIKE %s OR familyname ILIKE %s)",
            [f"%{search}%", f"%{search}%"]
        )[1]
    return execute_query("SELECT * FROM vw_events_list")[1]


def create_event(eid, minute, etype, match_id, player_id):
    execute_query(
        "CALL sp_event_insert(%s,%s,%s,%s,%s)",
        [eid, minute, etype, match_id, player_id], fetch=False
    )


def delete_event(eid):
    execute_query("CALL sp_event_delete(%s)", [eid], fetch=False)


def get_dashboard_counts():
    _, rows, _ = execute_query(
        "SELECT (SELECT COUNT(*) FROM MATCH) AS match_count, "
        "(SELECT COUNT(*) FROM TEAM) AS team_count, "
        "(SELECT COUNT(*) FROM PLAYER) AS player_count, "
        "(SELECT COUNT(*) FROM STADIUM) AS stadium_count, "
        "(SELECT COUNT(*) FROM MATCH_EVENT) AS event_count"
    )
    if rows:
        return {
            "match_count": rows[0][0],
            "team_count": rows[0][1],
            "player_count": rows[0][2],
            "stadium_count": rows[0][3],
            "event_count": rows[0][4],
        }
    return {"match_count": 0, "team_count": 0, "player_count": 0,
            "stadium_count": 0, "event_count": 0}
