import psycopg2
from psycopg2.extras import execute_batch
import pandas as pd
import numpy as np

# הגדרות ההתחברות שלך
DB_CONFIG = {
    'dbname': 'my_database',
    'user': 'user2',
    'password': 'etdahan111',
    'host': 'localhost',
    'port': '5432'
}

def clean_df_for_db(df):
    """פונקציית עזר להמרת ערכים חסרים (NaN) ל-None כדי ש-Postgres יקבל אותם כ-NULL"""
    return df.replace({np.nan: None}).to_dict('records')

def main():
    print("Connecting to database...")
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
    except Exception as e:
        print(f"Connection failed: {e}")
        return

    try:
        print("Reading CSV files...")
        players_df = pd.read_csv('C:\\Users\\TOP\\Downloads\\archive (2)\\players.csv')
        referees_df = pd.read_csv('C:\\Users\\TOP\\Downloads\\archive (2)\\referees.csv')
        teams_df = pd.read_csv('C:\\Users\\TOP\\Downloads\\archive (2)\\teams.csv')
        stadiums_df = pd.read_csv('C:\\Users\\TOP\\Downloads\\archive (2)\\stadiums.csv')
        matches_df = pd.read_csv('C:\\Users\\TOP\\Downloads\\archive (2)\\matches.csv')
        ref_apps_df = pd.read_csv('C:\\Users\\TOP\\Downloads\\archive (2)\\referee_appearances.csv')
        squads_df = pd.read_csv('C:\\Users\\TOP\\Downloads\\archive (2)\\squads.csv')
        goals_df = pd.read_csv('C:\\Users\\TOP\\Downloads\\archive (2)\\goals.csv')
        bookings_df = pd.read_csv('C:\\Users\\TOP\\Downloads\\archive (2)\\bookings.csv')
        subs_df = pd.read_csv('C:\\Users\\TOP\\Downloads\\archive (2)\\substitutions.csv')
        player_apps_df = pd.read_csv('C:\\Users\\TOP\\Downloads\\archive (2)\\player_appearances.csv')

        print("Processing and inserting data. Please wait...")

        # --- 1. PERSON ---
        # עכשיו PERSON מכיל רק ID ו-Name
        print("Inserting PERSON (Players & Referees)...")
        players_person = players_df[['player_id', 'family_name', 'given_name']].copy()
        players_person['Name'] = players_person['given_name'].fillna('') + ' ' + players_person['family_name'].fillna('')
        players_person = players_person.rename(columns={'player_id': 'ID'})[['ID', 'Name']]

        referees_person = referees_df[['referee_id', 'family_name', 'given_name']].copy()
        referees_person['Name'] = referees_person['given_name'].fillna('') + ' ' + referees_person['family_name'].fillna('')
        referees_person = referees_person.rename(columns={'referee_id': 'ID'})[['ID', 'Name']]

        person_df = pd.concat([players_person, referees_person]).drop_duplicates(subset=['ID'])
        persons = [(r['ID'], r['Name'].strip()) for r in clean_df_for_db(person_df)]
        
        execute_batch(cursor, "INSERT INTO PERSON (ID, Name) VALUES (%s, %s) ON CONFLICT DO NOTHING", persons)

        # --- 2. TEAM ---
        print("Inserting TEAM...")
        team_table = teams_df[['team_id', 'team_name', 'confederation_name']].copy()
        team_table = team_table.rename(columns={'team_id': 'TeamCode', 'team_name': 'CountryName', 'confederation_name': 'Confederation'})
        teams = [(r['TeamCode'], r['CountryName'], r['Confederation']) for r in clean_df_for_db(team_table)]
        
        execute_batch(cursor, "INSERT INTO TEAM (TeamCode, CountryName, Confederation) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING", teams)

        # --- 3. STADIUM ---
        print("Inserting STADIUM...")
        stadium_table = stadiums_df[['stadium_id', 'city_name', 'stadium_name', 'stadium_capacity']].copy()
        stadium_table = stadium_table.rename(columns={'stadium_id': 'StadiumID', 'city_name': 'City', 'stadium_name': 'Name', 'stadium_capacity': 'Capacity'})
        stadiums = [(r['StadiumID'], r['City'], r['Name'], r['Capacity']) for r in clean_df_for_db(stadium_table)]
        
        execute_batch(cursor, "INSERT INTO STADIUM (StadiumID, City, Name, Capacity) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING", stadiums)

        # --- 4. PLAYER ---
        # בסכמה החדשה: ID, DateOfBirth, Position, TeamCode
        print("Inserting PLAYER...")
        # ניקח את תאריך הלידה מ-players_df
        player_dates = players_df[['player_id', 'birth_date']].copy()
        player_dates['birth_date'] = player_dates['birth_date'].replace('not available', None)
        # ניקח את העמדה והקבוצה מ-squads_df (נשמור רק הופעה אחת לכל שחקן למניעת כפילויות)
        player_squads = squads_df[['player_id', 'position_name', 'team_id']].copy().drop_duplicates(subset=['player_id'])
        
        player_table = player_dates.merge(player_squads, on='player_id', how='left')
        player_table = player_table.rename(columns={
            'player_id': 'ID', 
            'birth_date': 'DateOfBirth',
            'position_name': 'Position', 
            'team_id': 'TeamCode'
        })
        
        # סינון שחקנים שיש להם עמדה וקבוצה (כדי לעמוד ב-NOT NULL)
        player_table = player_table.dropna(subset=['Position', 'TeamCode'])
        
        players = [(r['ID'], r['DateOfBirth'], r['Position'], r['TeamCode']) for r in clean_df_for_db(player_table)]
        
        execute_batch(cursor, "INSERT INTO PLAYER (ID, DateOfBirth, Position, TeamCode) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING", players)

        # --- 5. REFEREE ---
        print("Inserting REFEREE...")
        referees = [(r['referee_id'], None) for r in clean_df_for_db(referees_df)] # None for Years_of_experience
        execute_batch(cursor, "INSERT INTO REFEREE (ID, Years_of_experience) VALUES (%s, %s) ON CONFLICT DO NOTHING", referees)

        # --- 6. MATCHES ---
        # הטבלה נקראת matches בסכמה
        print("Inserting MATCHES...")
        # קח את הראשון (main referee) לכל match
        main_referees = ref_apps_df.drop_duplicates(subset=['match_id'])[['match_id', 'referee_id']]
        match_table = matches_df[['match_id', 'match_date', 'stage_name', 'home_team_id', 'away_team_id', 'stadium_id']].copy()
        match_table = match_table.merge(main_referees, on='match_id', how='left')
        
        matches_records = [(r['match_id'], r['match_date'], r['stage_name'], r['home_team_id'], r['away_team_id'], r['stadium_id'], r['referee_id']) 
                   for r in clean_df_for_db(match_table)]
        
        execute_batch(cursor, """
            INSERT INTO MATCHES (MatchID, MatchDate, Stage, HomeTeamCode, AwayTeamCode, StadiumID, RefereeID) 
            VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING
        """, matches_records)

        # --- 7. MATCH_EVENT ---
        print("Inserting MATCH_EVENT...")
        events = []
        
        # שערים
        goals = goals_df[['match_id', 'minute_label', 'player_id']].copy()
        goals['EventType'] = 'Goal'
        events.append(goals)

        # כרטיסים
        bookings = bookings_df[['match_id', 'minute_label', 'player_id', 'yellow_card', 'red_card']].copy()
        yellow_bookings = bookings[bookings['yellow_card'] == True].copy()
        yellow_bookings['EventType'] = 'Yellow Card'
        events.append(yellow_bookings[['match_id', 'minute_label', 'player_id', 'EventType']])

        red_bookings = bookings[bookings['red_card'] == True].copy()
        red_bookings['EventType'] = 'Red Card'
        events.append(red_bookings[['match_id', 'minute_label', 'player_id', 'EventType']])

        second_yellow = (yellow_bookings
                         .sort_values(['match_id', 'player_id', 'minute_label'])
                         .groupby(['match_id', 'player_id'])
                         .nth(1)
                         .reset_index())
        if not second_yellow.empty:
            second_yellow['EventType'] = 'Red Card'
            events.append(second_yellow[['match_id', 'minute_label', 'player_id', 'EventType']])

        # חילופים
        subs = subs_df[['match_id', 'minute_label', 'player_id']].copy()
        subs['EventType'] = 'Substitution In'
        events.append(subs)

        match_event_table = pd.concat(events).rename(columns={'match_id': 'MatchID', 'minute_label': 'Minute', 'player_id': 'PlayerID'})
        match_event_table['Minute'] = match_event_table['Minute'].astype(str)
        
        match_events = [(r['Minute'], r['EventType'], r['MatchID'], r['PlayerID']) for r in clean_df_for_db(match_event_table)]
        
        execute_batch(cursor, """
            INSERT INTO MATCH_EVENT (Minute, EventType, MatchID, PlayerID) 
            VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING
        """, match_events)

        # --- 8. PLAYER_MATCH_STATS ---
        print("Inserting PLAYER_MATCH_STATS...")
        player_match_stats_table = player_apps_df[['match_id', 'player_id']].copy()
        player_match_stats_table['MinutesPlayed'] = None
        player_match_stats_table['DistanceCovered'] = None
        
        stats = [(r['MinutesPlayed'], r['DistanceCovered'], r['match_id'], r['player_id']) 
                 for r in clean_df_for_db(player_match_stats_table)]
        
        execute_batch(cursor, """
            INSERT INTO PLAYER_MATCH_STATS (MinutesPlayed, DistanceCovered, MatchID, PlayerID) 
            VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING
        """, stats)

        # שמירת השינויים
        conn.commit()
        print("✅ Success! All data transferred perfectly to your database.")

    except Exception as e:
        print(f"Error during execution: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    main()