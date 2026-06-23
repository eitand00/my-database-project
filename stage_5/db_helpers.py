from db_connection import execute_query


def get_teams_list(search=None):
    if search:
        return execute_query(
            "SELECT * FROM vw_teams_list WHERE countryname ILIKE %s",
            [f"%{search}%"]
        )[1]
    return execute_query("SELECT * FROM vw_teams_list")[1]


def get_team_detail(code):
    cols, rows, _ = execute_query(
        "SELECT * FROM vw_team_detail WHERE TeamCode = %s", [code]
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
    return execute_query("SELECT * FROM vw_tournaments")[1]


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
    return execute_query("SELECT * FROM vw_teams_short")[1]


def get_stadiums_short():
    return execute_query("SELECT * FROM vw_stadiums_short")[1]


def get_referees_short():
    return execute_query("SELECT * FROM vw_referees_short")[1]


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
    _, rows, _ = execute_query("SELECT * FROM vw_dashboard_counts")
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
