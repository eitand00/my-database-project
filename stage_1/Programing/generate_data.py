import psycopg2
from psycopg2.extras import execute_batch
import random
from datetime import datetime, timedelta
import sys

# פרטי ההתחברות (זכור להחזיר את הסיסמה האמיתית שלך)
DB_CONFIG = {
    'dbname': 'world_cup_db', # או postgres בהתאם למה שהגדרת
    'user': 'user_db', # <--- שם המשתמש שלך מה-Docker Compose
    'password': 'password_db', # <--- הסיסמה שלך מה-Docker Compose
    'host': 'localhost',
    'port': '5432'
}

POSITIONS = ['Goalkeeper', 'Defender', 'Midfielder', 'Forward']
EVENT_TYPES = ['Goal', 'Yellow Card', 'Red Card', 'Substitution', 'Foul', 'Corner', 'Offside']
STAGES = ['Group Stage', 'Round of 16', 'Quarter Final', 'Semi Final', 'Final']

def generate_random_date(start_year=2023, end_year=2024):
    start = datetime(start_year, 1, 1)
    end = datetime(end_year, 12, 31)
    return start + timedelta(days=random.randint(0, (end - start).days))

def main():
    print("Connecting to database...")
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
    except Exception as e:
        print(f"Connection failed: {e}")
        return

    try:
        # --- שלב א': קריאת נתוני הבסיס (שהוזנו ע"י SQL ו-Mockaroo) ---
        print("Fetching existing Stadiums, Teams, and Persons...")
        
        cursor.execute("SELECT StadiumID FROM STADIUM")
        stadium_ids = [row[0] for row in cursor.fetchall()]
        
        cursor.execute("SELECT TeamCode FROM TEAM")
        team_codes = [row[0] for row in cursor.fetchall()]
        
        cursor.execute("SELECT ID FROM PERSON")
        person_ids = [row[0] for row in cursor.fetchall()]

        # וידוא שיש מספיק נתונים כדי לעמוד בדרישות הסילבוס
        if len(stadium_ids) < 500 or len(team_codes) < 500 or len(person_ids) < 1000:
            print("⚠️ Error: Not enough base data found!")
            print(f"Current count - Stadiums: {len(stadium_ids)}, Teams: {len(team_codes)}, Persons: {len(person_ids)}")
            print("Please run the manual INSERTs and Mockaroo scripts first (Aim for 500+ Stadiums, 500+ Teams, 1000+ Persons).")
            sys.exit()

        print("Base data verified! Proceeding to generate dependent data...")

        # --- שלב ב': חלוקת האנשים לשופטים ושחקנים ---
        # ניקח את 500 הראשונים להיות שופטים, ואת ה-500 הבאים להיות שחקנים
        referee_person_ids = person_ids[:500]
        player_person_ids = person_ids[500:1000]

        # 1. יצירת שופטים (500 רשומות)
        print("Generating 500 Referees...")
        refs = [(random.randint(1, 25), pid) for pid in referee_person_ids]
        execute_batch(cursor, "INSERT INTO REFEREE (Years_of_experience, ID) VALUES (%s, %s) ON CONFLICT DO NOTHING", refs)

        # 2. יצירת שחקנים (500 רשומות)
        print("Generating 500 Players...")
        players = [(random.choice(POSITIONS), random.choice(team_codes), pid) for pid in player_person_ids]
        execute_batch(cursor, "INSERT INTO PLAYER (Position, TeamCode, ID) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING", players)

        # 3. יצירת משחקים (550 משחקים, כולם עומדים בחוק ה-500+)
        print("Generating 550 Matches...")
        matches = []
        for match_id in range(1, 551):
            home_team, away_team = random.sample(team_codes, 2)
            matches.append((
                match_id, 
                generate_random_date(), 
                random.choice(STAGES), 
                home_team, 
                away_team, 
                random.choice(stadium_ids), 
                random.choice(referee_person_ids)
            ))
        execute_batch(cursor, "INSERT INTO MATCHES (MatchID, MatchDate, Stage, HomeTeamCode, AwayTeamCode, StadiumID, RefereeID) VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING", matches)

        # 4. יצירת 20,000+ אירועים וסטטיסטיקות (דרישת המסה הקריטית)
        print("Generating 22,000+ Events and Stats...")
        events = []
        stats = []
        
        # נעבור על כל 550 המשחקים ונייצר לכל אחד סטטיסטיקות ואירועים
        for match_id in range(1, 551):
            # בחירת 40 שחקנים שלקחו חלק במשחק (שחקני הרכב + מחליפים) כדי לנפח נתונים
            match_players = random.sample(player_person_ids, 40)
            
            # יצירת סטטיסטיקה לכל שחקן (550 משחקים * 40 שחקנים = 22,000 רשומות!)
            for pid in match_players:
                minutes = random.randint(1, 120)
                distance = round(random.uniform(1.0, 15.0), 2)
                stats.append((minutes, distance, match_id, pid))
            
            # יצירת אירועי משחק (550 משחקים * 40 אירועים בממוצע = ~22,000 רשומות!)
            used_minutes = set()
            for _ in range(40):
                minute = random.randint(1, 120)
                while minute in used_minutes:
                    minute = random.randint(1, 120)
                used_minutes.add(minute)
                events.append((minute, random.choice(EVENT_TYPES), match_id, random.choice(match_players)))

        execute_batch(cursor, "INSERT INTO PLAYER_MATCH_STATS (MinutesPlayed, DistanceCovered, MatchID, PlayerID) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING", stats)
        execute_batch(cursor, "INSERT INTO MATCH_EVENT (Minute, EventType, MatchID, PlayerID) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING", events)

        # אישור סופי למסד הנתונים
        conn.commit()
        print(f"✅ Success! Generated {len(refs)} Referees, {len(players)} Players, {len(matches)} Matches.")
        print(f"✅ Critical Mass Achieved: {len(events)} Events and {len(stats)} Stats records injected.")

    except Exception as e:
        print(f"Error during execution: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    main()