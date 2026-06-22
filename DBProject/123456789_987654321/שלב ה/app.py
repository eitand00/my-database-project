import streamlit as st
import pandas as pd
import psycopg2
from psycopg2 import sql
import os
from dotenv import load_dotenv

# Load environment variables (fallback to default if not found)
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), '.env'))

DB_USER = os.getenv('DB_USER_SECRET', 'user2')
DB_PASSWORD = os.getenv('DB_PASSWORD_SECRET', 'etdahan111')
DB_NAME = os.getenv('DB_NAME_SECRET', 'my_database')
DB_HOST = os.getenv('DB_HOST', 'db')
DB_PORT = '5432'

# Setup Streamlit page configuration
st.set_page_config(page_title="World Cup Database Manager", page_icon="⚽", layout="wide")

# Helper to connect to DB
def get_connection():
    try:
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT
        )
        return conn
    except Exception as e:
        st.error(f"Error connecting to database: {e}")
        return None

# Helper to run SELECT queries and return DataFrame
def run_query(query, params=None):
    conn = get_connection()
    if conn is not None:
        try:
            df = pd.read_sql_query(query, conn, params=params)
            return df
        except Exception as e:
            st.error(f"Query error: {e}")
        finally:
            conn.close()
    return pd.DataFrame()

# Helper to run INSERT/UPDATE/DELETE queries
def execute_query(query, params=None):
    conn = get_connection()
    if conn is not None:
        try:
            cursor = conn.cursor()
            cursor.execute(query, params)
            conn.commit()
            cursor.close()
            return True
        except Exception as e:
            st.error(f"Execution error: {e}")
            conn.rollback()
            return False
        finally:
            conn.close()
    return False

# Sidebar Navigation
st.sidebar.title("⚽ WORLDCUP MANAGER")
st.sidebar.markdown("---")
page = st.sidebar.radio("בחר מסך:", [
    "🏠 לוח בקרה (Dashboard)", 
    "🔍 חיפוש שחקן",
    "🛡️ ניהול קבוצות (TEAM)", 
    "🏃 ניהול שחקנים (PLAYER)", 
    "🏟️ ניהול אצטדיונים (STADIUM)",
    "📊 שאילתות (שלב ב')",
    "💰 מערכת הימורים (שלב ד')"
])

st.sidebar.markdown("---")
st.sidebar.info("פותח ע״י צוות הפרויקט.")

# ---------------------------------------------------------
# Page 1: Dashboard
# ---------------------------------------------------------
if page == "🏠 לוח בקרה (Dashboard)":
    st.markdown("""
        <style>
        .metric-card {
            background-color: #1e293b;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
            border: 1px solid #334155;
            text-align: center;
        }
        .metric-value {
            font-size: 36px;
            font-weight: bold;
            color: #f8fafc;
            margin-top: 10px;
        }
        .metric-label {
            color: #94a3b8;
            font-size: 14px;
            text-transform: uppercase;
        }
        .match-card {
            background-color: #1e293b;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            border: 1px solid #334155;
        }
        .match-header {
            display: flex;
            justify-content: space-between;
            color: #94a3b8;
            font-size: 14px;
            margin-bottom: 15px;
        }
        .stage-badge {
            background-color: #9f1239;
            color: white;
            padding: 4px 10px;
            border-radius: 4px;
            font-weight: bold;
            font-size: 12px;
        }
        .match-teams {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        .team-col {
            text-align: center;
            flex: 1;
        }
        .team-circle {
            background-color: #334155;
            color: white;
            border-radius: 50%;
            width: 60px;
            height: 60px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 18px;
            margin-bottom: 10px;
        }
        .team-name {
            color: #f8fafc;
            font-weight: bold;
            font-size: 16px;
        }
        .score-col {
            text-align: center;
            flex: 1;
        }
        .score {
            font-size: 42px;
            font-weight: bold;
            color: white;
            margin-bottom: 5px;
        }
        .ft-badge {
            color: #22c55e;
            font-size: 12px;
            font-weight: bold;
        }
        .match-footer {
            display: flex;
            justify-content: space-between;
            color: #64748b;
            font-size: 14px;
        }
        </style>
    """, unsafe_allow_html=True)

    st.title("WORLDCUP MANAGER")
    st.markdown("---")

    # Fetch Metrics
    tot_matches = run_query("SELECT COUNT(*) FROM MATCH").iloc[0,0]
    tot_goals = run_query("SELECT COUNT(*) FROM MATCH_EVENT WHERE EventType = 'Goal'").iloc[0,0]
    tot_stad = run_query("SELECT COUNT(*) FROM STADIUM").iloc[0,0]
    tot_players = run_query("SELECT COUNT(*) FROM PLAYER").iloc[0,0]

    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.markdown(f'<div class="metric-card"><div class="metric-label">Total Matches</div><div class="metric-value">{tot_matches}</div></div>', unsafe_allow_html=True)
    with col2:
        st.markdown(f'<div class="metric-card"><div class="metric-label">Goals Scored</div><div class="metric-value">{tot_goals}</div></div>', unsafe_allow_html=True)
    with col3:
        st.markdown(f'<div class="metric-card"><div class="metric-label">Stadiums</div><div class="metric-value">{tot_stad}</div></div>', unsafe_allow_html=True)
    with col4:
        st.markdown(f'<div class="metric-card"><div class="metric-label">Active Players</div><div class="metric-value">{tot_players}</div></div>', unsafe_allow_html=True)

    st.markdown("<br><br>", unsafe_allow_html=True)

    # Fetch recent matches for cards
    matches_q = """
    WITH match_scores AS (
        SELECT m.matchid,
               SUM(CASE WHEN pl.teamcode = m.hometeamcode THEN 1 ELSE 0 END) AS h_goals,
               SUM(CASE WHEN pl.teamcode = m.guestteamcode THEN 1 ELSE 0 END) AS g_goals
        FROM match m
        LEFT JOIN match_event me ON m.matchid = me.matchid AND me.eventtype = 'Goal'
        LEFT JOIN player pl ON me.id = pl.id
        GROUP BY m.matchid
    )
    SELECT m.MatchID, m.Stage, m.MatchDate, s.Name as Stadium,
           ht.CountryName as HomeName, ht.TeamCode as HomeCode,
           gt.CountryName as GuestName, gt.TeamCode as GuestCode,
           COALESCE(ms.h_goals, 0) as HScore, COALESCE(ms.g_goals, 0) as GScore
    FROM MATCH m
    JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
    JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
    JOIN STADIUM s ON m.StadiumID = s.StadiumID
    LEFT JOIN match_scores ms ON m.MatchID = ms.matchid
    ORDER BY m.MatchDate DESC LIMIT 6
    """
    df_m = run_query(matches_q)

    if not df_m.empty:
        # Show 3 cards per row
        for i in range(0, len(df_m), 3):
            cols = st.columns(3)
            for j in range(3):
                if i + j < len(df_m):
                    row = df_m.iloc[i+j]
                    date_str = str(row['matchdate'])
                    card_html = f"""
                    <div class="match-card">
                        <div class="match-header">
                            <span>ID: WC-{row['matchid']:03d}</span>
                            <span class="stage-badge">{row['stage'].upper()}</span>
                        </div>
                        <div class="match-teams">
                            <div class="team-col">
                                <div class="team-circle">{row['homecode']}</div>
                                <div class="team-name">{row['homename']}</div>
                            </div>
                            <div class="score-col">
                                <div class="score">{row['hscore']} - {row['gscore']}</div>
                                <div class="ft-badge">FULL TIME</div>
                            </div>
                            <div class="team-col">
                                <div class="team-circle">{row['guestcode']}</div>
                                <div class="team-name">{row['guestname']}</div>
                            </div>
                        </div>
                        <div class="match-footer">
                            <span>📍 {row['stadium']}</span>
                            <span>📅 {date_str}</span>
                        </div>
                    </div>
                    """
                    cols[j].markdown(card_html, unsafe_allow_html=True)


# ---------------------------------------------------------
# Page: Player Search
# ---------------------------------------------------------
elif page == "🔍 חיפוש שחקן":
    st.title("חיפוש שחקן (Player Search)")
    st.markdown("חפש שחקנים לפי שם או חלק משם כדי לקבל את הנתונים שלהם.")
    
    search_term = st.text_input("הכנס שם שחקן:")
    if search_term:
        search_q = """
        SELECT pl.ID as "מזהה", pe.GivenName || ' ' || pe.FamilyName as "שם השחקן",
               pl.DateOfBirth as "תאריך לידה", t.CountryName as "נבחרת",
               t.ConfederationName as "קונפדרציה"
        FROM PLAYER pl
        JOIN PERSON pe ON pl.ID = pe.ID
        LEFT JOIN TEAM t ON pl.TeamCode = t.TeamCode
        WHERE pe.GivenName ILIKE %s OR pe.FamilyName ILIKE %s
        ORDER BY pe.GivenName
        """
        like_term = f"%{search_term}%"
        res_df = run_query(search_q, (like_term, like_term))
        if not res_df.empty:
            st.success(f"נמצאו {len(res_df)} תוצאות עבור '{search_term}':")
            st.dataframe(res_df, use_container_width=True)
        else:
            st.warning("לא נמצאו שחקנים התואמים לחיפוש.")

# ---------------------------------------------------------
# Page 2: TEAM CRUD
# ---------------------------------------------------------
elif page == "🛡️ ניהול קבוצות (TEAM)":
    st.title("ניהול נבחרות")
    tab1, tab2, tab3, tab4 = st.tabs(["צפייה בנתונים", "הוספת נבחרת", "עדכון נבחרת", "מחיקת נבחרת"])
    
    with tab1:
        st.subheader("רשימת הנבחרות במונדיאל")
        df_teams = run_query("SELECT TeamCode as \"קוד\", CountryName as \"מדינה\", ConfederationName as \"קונפדרציה\" FROM TEAM ORDER BY CountryName")
        st.dataframe(df_teams, use_container_width=True)
        
    with tab2:
        st.subheader("הוספת נבחרת חדשה")
        with st.form("add_team_form"):
            t_code = st.text_input("קוד קבוצה (לדוגמה: ISR)")
            t_name = st.text_input("שם מדינה")
            t_conf_name = st.text_input("שם קונפדרציה (לדוגמה: UEFA)")
            t_conf_code = st.text_input("קוד קונפדרציה")
            t_wiki = st.text_input("קישור לויקיפדיה")
            submitted = st.form_submit_button("הוסף נבחרת")
            if submitted:
                if t_code and t_name:
                    success = execute_query(
                        "INSERT INTO TEAM (TeamCode, CountryName, ConfederationName, ConfederationCode, WikipediaPage) VALUES (%s, %s, %s, %s, %s)",
                        (t_code, t_name, t_conf_name, t_conf_code, t_wiki)
                    )
                    if success:
                        st.success("הנבחרת הוספה בהצלחה! רענן כדי לראות.")
                else:
                    st.warning("יש למלא לפחות קוד ושם.")
                    
    with tab3:
        st.subheader("עדכון נבחרת קיימת")
        teams_list = run_query("SELECT TeamCode, CountryName FROM TEAM ORDER BY CountryName")
        if not teams_list.empty:
            team_options = dict(zip(teams_list['countryname'], teams_list['teamcode']))
            selected_team_name = st.selectbox("בחר נבחרת לעדכון:", list(team_options.keys()))
            selected_team_code = team_options[selected_team_name]
            
            # Fetch existing data
            team_data = run_query("SELECT * FROM TEAM WHERE TeamCode = %s", (selected_team_code,))
            if not team_data.empty:
                with st.form("update_team_form"):
                    u_name = st.text_input("שם מדינה", value=team_data['countryname'][0])
                    u_conf_name = st.text_input("שם קונפדרציה", value=team_data['confederationname'][0])
                    u_conf_code = st.text_input("קוד קונפדרציה", value=team_data['confederationcode'][0])
                    u_wiki = st.text_input("קישור לויקיפדיה", value=team_data['wikipediapage'][0] if team_data['wikipediapage'][0] else "")
                    updated = st.form_submit_button("שמור שינויים")
                    if updated:
                        success = execute_query(
                            "UPDATE TEAM SET CountryName=%s, ConfederationName=%s, ConfederationCode=%s, WikipediaPage=%s WHERE TeamCode=%s",
                            (u_name, u_conf_name, u_conf_code, u_wiki, selected_team_code)
                        )
                        if success:
                            st.success("הנבחרת עודכנה בהצלחה!")
                            
    with tab4:
        st.subheader("מחיקת נבחרת")
        if not teams_list.empty:
            del_team_name = st.selectbox("בחר נבחרת למחיקה:", list(team_options.keys()))
            del_team_code = team_options[del_team_name]
            if st.button("מחק נבחרת (פעולה בלתי הפיכה!)", type="primary"):
                success = execute_query("DELETE FROM TEAM WHERE TeamCode = %s", (del_team_code,))
                if success:
                    st.success("הנבחרת נמחקה בהצלחה.")

# ---------------------------------------------------------
# Page 3: PLAYER CRUD (Uses Join with PERSON and TEAM)
# ---------------------------------------------------------
elif page == "🏃 ניהול שחקנים (PLAYER)":
    st.title("ניהול שחקנים")
    tab1, tab2, tab3 = st.tabs(["צפייה בנתונים", "הוספת שחקן", "מחיקת שחקן (ללא PERSON)"])
    
    with tab1:
        st.subheader("רשימת שחקנים")
        st.info("כאן אנו מציגים את שמות השחקנים מטבלת PERSON ואת שם הנבחרת מטבלת TEAM, במקום מזהים (IDs).")
        query = """
        SELECT pl.ID, pe.GivenName || ' ' || pe.FamilyName as "שם השחקן", 
               pl.DateOfBirth as "תאריך לידה", t.CountryName as "נבחרת"
        FROM PLAYER pl
        JOIN PERSON pe ON pl.ID = pe.ID
        LEFT JOIN TEAM t ON pl.TeamCode = t.TeamCode
        ORDER BY t.CountryName, pe.GivenName
        LIMIT 500
        """
        df_players = run_query(query)
        st.dataframe(df_players, use_container_width=True)
        
    with tab2:
        st.subheader("הוספת שחקן חדש")
        st.warning("מכיוון ששחקן הוא ירושה של PERSON, יש קודם ליצור את ה-PERSON.")
        with st.form("add_player_form"):
            p_id = st.text_input("מזהה חדש (ID)")
            p_given = st.text_input("שם פרטי")
            p_family = st.text_input("שם משפחה")
            p_dob = st.date_input("תאריך לידה")
            
            teams_list = run_query("SELECT TeamCode, CountryName FROM TEAM ORDER BY CountryName")
            team_options = dict(zip(teams_list['countryname'], teams_list['teamcode']))
            p_team_name = st.selectbox("בחר נבחרת:", list(team_options.keys()))
            
            submitted = st.form_submit_button("הוסף אדם ושחקן")
            if submitted:
                if p_id and p_given:
                    # Insert PERSON first
                    res1 = execute_query("INSERT INTO PERSON (ID, GivenName, FamilyName) VALUES (%s, %s, %s)", (p_id, p_given, p_family))
                    if res1:
                        # Insert PLAYER
                        p_team_code = team_options[p_team_name]
                        res2 = execute_query("INSERT INTO PLAYER (ID, DateOfBirth, TeamCode) VALUES (%s, %s, %s)", (p_id, p_dob, p_team_code))
                        if res2:
                            st.success("השחקן הוסף בהצלחה!")
                        else:
                            st.error("שגיאה בהוספת Player (Person נוסף)")
                else:
                    st.warning("חובה למלא מזהה ושם פרטי.")
                    
    with tab3:
        st.subheader("מחיקת שחקן")
        pl_list = run_query("SELECT pl.ID, pe.GivenName || ' ' || pe.FamilyName as Name FROM PLAYER pl JOIN PERSON pe ON pl.ID = pe.ID")
        if not pl_list.empty:
            pl_options = dict(zip(pl_list['name'] + " (" + pl_list['id'] + ")", pl_list['id']))
            del_pl_name = st.selectbox("בחר שחקן למחיקה:", list(pl_options.keys()))
            del_pl_id = pl_options[del_pl_name]
            if st.button("מחק שחקן"):
                success = execute_query("DELETE FROM PLAYER WHERE ID = %s", (del_pl_id,))
                if success:
                    st.success("השחקן נמחק מטבלת PLAYER.")

# ---------------------------------------------------------
# Page 4: STADIUM CRUD
# ---------------------------------------------------------
elif page == "🏟️ ניהול אצטדיונים (STADIUM)":
    st.title("ניהול אצטדיונים")
    tab1, tab2, tab3 = st.tabs(["צפייה בנתונים", "עדכון אצטדיון", "הוספת אצטדיון"])
    
    with tab1:
        st.subheader("רשימת אצטדיונים")
        df_stad = run_query("SELECT StadiumID, Name, City, Country, Capacity FROM STADIUM ORDER BY Name")
        st.dataframe(df_stad, use_container_width=True)
        
    with tab2:
        st.subheader("עדכון אצטדיון (הדגמת משיכת נתונים לפי מפתח)")
        stad_list = run_query("SELECT StadiumID, Name FROM STADIUM ORDER BY Name")
        if not stad_list.empty:
            stad_options = dict(zip(stad_list['name'], stad_list['stadiumid']))
            sel_stad = st.selectbox("בחר אצטדיון לעדכון:", list(stad_options.keys()))
            sel_stad_id = stad_options[sel_stad]
            
            stad_data = run_query("SELECT * FROM STADIUM WHERE StadiumID = %s", (sel_stad_id,))
            if not stad_data.empty:
                with st.form("update_stad_form"):
                    s_name = st.text_input("שם", value=stad_data['name'][0])
                    s_city = st.text_input("עיר", value=stad_data['city'][0])
                    s_country = st.text_input("מדינה", value=stad_data['country'][0])
                    s_cap = st.number_input("תכולה", min_value=0, value=int(stad_data['capacity'][0]))
                    updated = st.form_submit_button("עדכן אצטדיון")
                    if updated:
                        success = execute_query(
                            "UPDATE STADIUM SET Name=%s, City=%s, Country=%s, Capacity=%s WHERE StadiumID=%s",
                            (s_name, s_city, s_country, s_cap, sel_stad_id)
                        )
                        if success:
                            st.success("עודכן בהצלחה!")

    with tab3:
        st.subheader("הוספת אצטדיון")
        with st.form("add_stad_form"):
            st_id = st.text_input("מזהה (StadiumID)")
            st_name = st.text_input("שם")
            st_city = st.text_input("עיר")
            st_country = st.text_input("מדינה")
            st_cap = st.number_input("תכולה", min_value=0, value=50000)
            submitted = st.form_submit_button("הוסף")
            if submitted and st_id and st_name:
                success = execute_query(
                    "INSERT INTO STADIUM (StadiumID, Name, City, Country, Capacity) VALUES (%s, %s, %s, %s, %s)",
                    (st_id, st_name, st_city, st_country, st_cap)
                )
                if success:
                    st.success("הוסף בהצלחה!")


# ---------------------------------------------------------
# Page 5: Queries
# ---------------------------------------------------------
elif page == "📊 שאילתות (שלב ב')":
    st.title("שאילתות מתקדמות")
    
    st.subheader("משחקים עם יותר מ-3 שערים (ב-2018)")
    if st.button("הצג נתונים", key="q1"):
        query1 = """
        WITH GoalCounts AS (
            SELECT MatchID, COUNT(MatchEventID) AS TotalGoals
            FROM MATCH_EVENT
            WHERE EventType = 'Goal'
            GROUP BY MatchID
            HAVING COUNT(MatchEventID) > 3
        )
        SELECT m.MatchID as "מזהה משחק", m.Stage as "שלב",
               ht.CountryName as "קבוצת בית", gt.CountryName as "קבוצת חוץ",
               gc.TotalGoals as "סך שערים"
        FROM MATCH m
        JOIN GoalCounts gc ON m.MatchID = gc.MatchID
        JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
        JOIN TEAM gt ON m.GuestTeamCode = gt.TeamCode
        WHERE EXTRACT(YEAR FROM m.MatchDate) = 2018
        ORDER BY gc.TotalGoals DESC;
        """
        df1 = run_query(query1)
        st.dataframe(df1, use_container_width=True)

    st.markdown("---")
    
    st.subheader("שופטים שהוציאו יותר מ-4 כרטיסים צהובים (2018)")
    if st.button("הצג נתונים", key="q2"):
        query2 = """
        SELECT p.GivenName || ' ' || p.FamilyName AS "שם השופט",
               r.Country AS "מדינת השופט", m.Stage as "שלב",
               COUNT(me.MatchEventID) AS "צהובים שהוצאו"
        FROM PERSON p
        JOIN REFEREE r ON p.ID = r.ID
        JOIN MATCH m ON r.ID = m.RefereeID
        JOIN MATCH_EVENT me ON m.MatchID = me.MatchID
        WHERE me.EventType = 'Yellow Card' 
          AND EXTRACT(YEAR FROM m.MatchDate) = 2018
        GROUP BY p.ID, p.GivenName, p.FamilyName, r.Country, m.MatchID, m.Stage, m.MatchDate
        HAVING COUNT(me.MatchEventID) > 4
        ORDER BY COUNT(me.MatchEventID) DESC;
        """
        df2 = run_query(query2)
        st.dataframe(df2, use_container_width=True)

    st.markdown("---")

    st.subheader("אצטדיונים עם תכולה מעל 60,000 שאירחו משחקים עם כרטיסים אדומים")
    if st.button("הצג נתונים", key="q3"):
        query3 = """
        SELECT DISTINCT
            s.Name AS "שם אצטדיון", s.City AS "עיר", s.Capacity as "תכולה",
            m.MatchDate as "תאריך", m.Stage as "שלב", m.Tournament as "טורניר"
        FROM STADIUM s
        JOIN MATCH m ON s.StadiumID = m.StadiumID
        WHERE s.Capacity >= 60000
          AND EXISTS (
              SELECT 1 FROM MATCH_EVENT me 
              WHERE me.MatchID = m.MatchID AND me.EventType = 'Red Card'
          );
        """
        df3 = run_query(query3)
        st.dataframe(df3, use_container_width=True)

    st.markdown("---")

    st.subheader("שחקנים שהבקיעו שער וקיבלו כרטיס באותו משחק (2018)")
    if st.button("הצג נתונים", key="q4"):
        query4 = """
        SELECT DISTINCT
            p.GivenName || ' ' || p.FamilyName AS "שם שחקן",
            t.CountryName AS "נבחרת", m.Stage AS "שלב",
            (SELECT MIN(Minute) FROM MATCH_EVENT me2 WHERE me2.ID = p.ID AND me2.MatchID = m.MatchID AND me2.EventType = 'Goal') AS "דקת שער ראשון",
            (SELECT MAX(Minute) FROM MATCH_EVENT me3 WHERE me3.ID = p.ID AND me3.MatchID = m.MatchID AND me3.EventType IN ('Yellow Card', 'Red Card')) AS "דקת כרטיס אחרון"
        FROM PERSON p
        JOIN PLAYER pl ON p.ID = pl.ID
        JOIN TEAM t ON pl.TeamCode = t.TeamCode
        JOIN MATCH_EVENT me ON p.ID = me.ID
        JOIN MATCH m ON me.MatchID = m.MatchID
        WHERE EXTRACT(YEAR FROM m.MatchDate) = 2018
          AND (SELECT COUNT(MatchEventID) FROM MATCH_EVENT me4 WHERE me4.ID = p.ID AND me4.MatchID = m.MatchID AND me4.EventType = 'Goal') > 0
          AND (SELECT COUNT(MatchEventID) FROM MATCH_EVENT me5 WHERE me5.ID = p.ID AND me5.MatchID = m.MatchID AND me5.EventType IN ('Yellow Card', 'Red Card')) > 0
        ORDER BY "דקת שער ראשון" ASC;
        """
        df4 = run_query(query4)
        st.dataframe(df4, use_container_width=True)

    st.markdown("---")

    st.subheader("שחקנים שנולדו ב-1990 והבקיעו שערים")
    if st.button("הצג נתונים", key="q5"):
        query5 = """
        SELECT p.GivenName || ' ' || p.FamilyName AS "שם שחקן",
               EXTRACT(DAY FROM pl.DateOfBirth) || '/' || EXTRACT(MONTH FROM pl.DateOfBirth) || '/' || EXTRACT(YEAR FROM pl.DateOfBirth) AS "תאריך לידה",
               t.CountryName AS "נבחרת", m.Stage as "שלב",
               me.Minute AS "דקת שער", m.Tournament as "טורניר"
        FROM PERSON p
        JOIN PLAYER pl ON p.ID = pl.ID
        JOIN TEAM t ON pl.TeamCode = t.TeamCode
        JOIN MATCH_EVENT me ON pl.ID = me.ID
        JOIN MATCH m ON me.MatchID = m.MatchID
        WHERE me.EventType = 'Goal' AND EXTRACT(YEAR FROM pl.DateOfBirth) = 1990
        ORDER BY pl.DateOfBirth ASC;
        """
        df5 = run_query(query5)
        st.dataframe(df5, use_container_width=True)

    st.markdown("---")

    st.subheader("משחקים שבהם קבוצת החוץ ניצחה בשלבי הנוקאאוט")
    if st.button("הצג נתונים", key="q6"):
        query6 = """
        WITH match_scores AS (
            SELECT m.matchid,
                   SUM(CASE WHEN pl.teamcode = m.hometeamcode THEN 1 ELSE 0 END) AS home_goals,
                   SUM(CASE WHEN pl.teamcode = m.guestteamcode THEN 1 ELSE 0 END) AS guest_goals
            FROM match m
            JOIN match_event me ON m.matchid = me.matchid
            JOIN player pl ON me.id = pl.id
            WHERE LOWER(me.eventtype) = 'goal'
            GROUP BY m.matchid
        )
        SELECT m.matchdate as "תאריך", m.stage as "שלב",
               ht.countryname AS "קבוצת בית", gt.countryname AS "קבוצת חוץ",
               ms.home_goals || ' - ' || ms.guest_goals AS "תוצאה סופית"
        FROM match m
        JOIN match_scores ms ON m.matchid = ms.matchid
        JOIN team ht ON m.hometeamcode = ht.teamcode
        JOIN team gt ON m.guestteamcode = gt.teamcode
        WHERE ms.guest_goals > ms.home_goals
          AND LOWER(m.stage) IN ('semi-final', 'quarter-final', 'round of 16', 'final', 'semi-finals', 'quarter-finals')
        ORDER BY m.matchdate DESC;
        """
        df6 = run_query(query6)
        st.dataframe(df6, use_container_width=True)

    st.markdown("---")

    st.subheader("שחקנים שקיבלו כרטיס במשחק, כולל פרטי שופט")
    if st.button("הצג נתונים", key="q7"):
        query7 = """
        SELECT p_player.givenname || ' ' || p_player.familyname AS "שם שחקן",
               t.countryname AS "נבחרת", me.eventtype AS "סוג כרטיס",
               EXTRACT(DAY FROM m.matchdate) || '/' || EXTRACT(MONTH FROM m.matchdate) || '/' || EXTRACT(YEAR FROM m.matchdate) AS "תאריך",
               p_ref.givenname || ' ' || p_ref.familyname AS "שם שופט"
        FROM match_event me
        JOIN player pl ON me.id = pl.id
        JOIN person p_player ON pl.id = p_player.id
        JOIN team t ON pl.teamcode = t.teamcode
        JOIN match m ON me.matchid = m.matchid
        JOIN referee r ON m.refereeid = r.id
        JOIN person p_ref ON r.id = p_ref.id
        WHERE LOWER(me.eventtype) LIKE '%card%'
        ORDER BY m.matchdate DESC
        LIMIT 500;
        """
        df7 = run_query(query7)
        st.dataframe(df7, use_container_width=True)

    st.markdown("---")

    st.subheader("5 הנבחרות עם הכי הרבה שחקנים במונדיאל")
    if st.button("הצג נתונים", key="q8"):
        query8 = """
        SELECT t.CountryName AS "נבחרת",
               COUNT(pl.ID) AS "מספר שחקנים",
               t.ConfederationName AS "קונפדרציה"
        FROM TEAM t
        JOIN PLAYER pl ON t.TeamCode = pl.TeamCode
        GROUP BY t.TeamCode, t.CountryName, t.ConfederationName
        ORDER BY "מספר שחקנים" DESC
        LIMIT 5;
        """
        df8 = run_query(query8)
        st.dataframe(df8, use_container_width=True)


# ---------------------------------------------------------
# Page 6: Betting System (Procedures & Functions)
# ---------------------------------------------------------
elif page == "💰 מערכת הימורים (שלב ד')":
    st.title("מערכת הימורים חכמה (PL/pgSQL)")
    
    st.subheader("1. יצירת הימור (Procedure: create_bet)")
    st.markdown("פרוצדורה זו מורידה מהיתרה (Balance) ויוצרת רשומת הימור חדשה תחת מעטפת שגיאות מנוהלת.")
    
    users = run_query("SELECT user_id, full_name, balance FROM users")
    matches = run_query("""
    SELECT gm.GlobalMatchID, t1.CountryName || ' vs ' || t2.CountryName as MatchName
    FROM GLOBAL_MATCH gm
    JOIN MATCH m ON gm.WCMatchID = m.MatchID
    JOIN TEAM t1 ON m.HomeTeamCode = t1.TeamCode
    JOIN TEAM t2 ON m.GuestTeamCode = t2.TeamCode
    LIMIT 20
    """)
    
    if not users.empty and not matches.empty:
        user_options = dict(zip(users['full_name'] + " (יתרה: " + users['balance'].astype(str) + ")", users['user_id']))
        match_options = dict(zip(matches['matchname'] + " (ID: " + matches['globalmatchid'].astype(str) + ")", matches['globalmatchid']))
        
        with st.form("create_bet_form"):
            selected_user_label = st.selectbox("בחר משתמש:", list(user_options.keys()))
            selected_match_label = st.selectbox("בחר משחק:", list(match_options.keys()))
            amount = st.number_input("סכום ההימור:", min_value=1.0, value=100.0)
            prediction = st.selectbox("ניחוש:", ["Home", "Draw", "Away"])
            
            submit_bet = st.form_submit_button("בצע הימור!")
            
            if submit_bet:
                uid = user_options[selected_user_label]
                mid = match_options[selected_match_label]
                
                # We use psycopg2 directly to call PROCEDURE using CALL
                conn = get_connection()
                if conn:
                    try:
                        cursor = conn.cursor()
                        cursor.execute("CALL create_bet(%s, %s, %s, %s)", (uid, mid, amount, prediction))
                        conn.commit()
                        st.success("ההימור בוצע בהצלחה! (היתרה עודכנה וההימור נרשם)")
                    except Exception as e:
                        conn.rollback()
                        st.error(f"שגיאה בביצוע ההימור (הפעולה בוטלה): {e}")
                    finally:
                        conn.close()

    st.markdown("---")
    
    st.subheader("2. חישוב פוטנציאל זכייה (Function: Calculate_Potential_Payout)")
    st.markdown("פונקציה המקבלת מזהה הימור ומחשבת כמה כסף המשתמש יקבל במקרה של זכייה, בהתבסס על טבלת odds.")
    
    bets = run_query("""
    SELECT b.bet_id, u.full_name, b.predicted_result, b.bet_amount 
    FROM bets b JOIN users u ON b.user_id = u.user_id 
    ORDER BY b.bet_id DESC LIMIT 10
    """)
    
    if not bets.empty:
        bet_options = dict(zip("Bet #" + bets['bet_id'].astype(str) + " - " + bets['full_name'] + " (" + bets['predicted_result'] + ")", bets['bet_id']))
        selected_bet_label = st.selectbox("בחר הימור (10 אחרונים):", list(bet_options.keys()))
        
        if st.button("חשב פוטנציאל זכייה"):
            bid = bet_options[selected_bet_label]
            conn = get_connection()
            if conn:
                try:
                    cursor = conn.cursor()
                    cursor.execute("SELECT Calculate_Potential_Payout(%s)", (bid,))
                    payout = cursor.fetchone()[0]
                    st.info(f"💰 סכום הזכייה הפוטנציאלי עבור הימור #{bid} הוא: **{payout}**")
                except Exception as e:
                    st.error(f"שגיאה בפונקציה: {e}")
                finally:
                    conn.close()

