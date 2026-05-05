import psycopg2
from psycopg2.extras import execute_batch
import pandas as pd
import random
from datetime import datetime

DB_CONFIG = {
    'dbname': 'my_database',
    'user': 'user2',
    'password': 'etdahan111',
    'host': 'localhost',
    'port': '5432'
}

POSITIONS = ['Goalkeeper', 'Defender', 'Midfielder', 'Forward']

def main():
    print("🔧 Fixing data consistency issues...\n")
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return

    try:
        # Load fresh data
        print("📊 Loading Kaggle data...")
        goalscorers_df = pd.read_csv(r'c:\Users\TOP\Downloads\archive\goalscorers.csv')
        goalscorers_df['date'] = pd.to_datetime(goalscorers_df['date'])
        
        # Get all players and teams from database
        cursor.execute("SELECT ID FROM PLAYER LIMIT 100")
        player_ids = [row[0] for row in cursor.fetchall()]
        
        # Get all match IDs
        cursor.execute("SELECT MatchID FROM MATCHES ORDER BY MatchID")
        all_match_ids = [row[0] for row in cursor.fetchall()]
        
        print(f"✅ Found {len(all_match_ids)} matches and {len(player_ids)} players\n")
        
        # DELETE old stats and events (to recreate them)
        print("🗑️  Clearing old PLAYER_MATCH_STATS and MATCH_EVENT records...")
        cursor.execute("DELETE FROM PLAYER_MATCH_STATS")
        cursor.execute("DELETE FROM MATCH_EVENT")
        conn.commit()
        print("✅ Cleared old records\n")
        
        # ===== RECREATE MATCH_EVENTS with better logic =====
        print("📍 Creating MATCH_EVENTS from Kaggle data...")
        
        # Get match info for lookup
        cursor.execute("""
            SELECT MatchID, MatchDate, HomeTeamCode, AwayTeamCode 
            FROM MATCHES 
            ORDER BY MatchID
        """)
        matches = cursor.fetchall()
        
        # Create date-based lookup for matches
        match_lookup = {}
        for match_id, match_date, home_code, away_code in matches:
            key = (match_date.isoformat(), home_code, away_code)
            match_lookup[key] = match_id
        
        # Get team codes
        cursor.execute("SELECT TeamCode, CountryName FROM TEAM")
        team_code_map = {name: code for code, name in cursor.fetchall()}
        
        events = []
        events_created = 0
        
        for _, row in goalscorers_df.iterrows():
            date_str = pd.Timestamp(row['date']).date().isoformat()
            home_team = row['home_team']
            away_team = row['away_team']
            
            home_code = team_code_map.get(home_team)
            away_code = team_code_map.get(away_team)
            
            if not home_code or not away_code:
                continue
            
            key = (date_str, home_code, away_code)
            
            if key not in match_lookup:
                continue
                
            match_id = match_lookup[key]
            
            # Get a random player from the scoring team
            cursor.execute("""
                SELECT ID FROM PLAYER 
                WHERE TeamCode = %s 
                LIMIT 1 
                OFFSET %s
            """, (away_code if row['team'] == away_team else home_code, 
                  random.randint(0, 50)))
            
            result = cursor.fetchone()
            if not result:
                continue
            
            player_id = result[0]
            minute = int(row['minute']) if pd.notna(row['minute']) else random.randint(1, 90)
            event_type = 'Goal'
            
            if pd.notna(row.get('penalty')) and row['penalty']:
                event_type = 'Penalty Goal'
            if pd.notna(row.get('own_goal')) and row['own_goal']:
                event_type = 'Own Goal'
            
            events.append((minute, event_type, match_id, player_id))
            events_created += 1
        
        if events:
            execute_batch(
                cursor,
                "INSERT INTO MATCH_EVENT (Minute, EventType, MatchID, PlayerID) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING",
                events
            )
            print(f"✅ Created {len(events)} match events\n")
        
        # ===== RECREATE PLAYER_MATCH_STATS for ALL matches =====
        print("📍 Creating PLAYER_MATCH_STATS for all matches...")
        
        stats = []
        stats_created = 0
        
        # For each match, assign 15 random players
        for match_id in all_match_ids:
            if len(player_ids) < 15:
                continue
            
            match_players = random.sample(player_ids, 15)
            
            for player_id in match_players:
                minutes_played = random.randint(1, 120)
                distance_covered = round(random.uniform(1.0, 15.0), 2)
                stats.append((minutes_played, distance_covered, match_id, player_id))
                stats_created += 1
        
        # Insert in batches
        execute_batch(
            cursor,
            "INSERT INTO PLAYER_MATCH_STATS (MinutesPlayed, DistanceCovered, MatchID, PlayerID) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING",
            stats,
            page_size=1000
        )
        print(f"✅ Created {len(stats)} player match stats\n")
        
        conn.commit()
        
        print("=" * 60)
        print("✅ SUCCESS! Data has been fixed!")
        print("=" * 60)
        print(f"📊 Summary:")
        print(f"  • Total Matches: {len(all_match_ids)}")
        print(f"  • Match Events Created: {len(events)}")
        print(f"  • Player Stats Created: {len(stats)}")
        print("=" * 60)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        conn.rollback()
        import traceback
        traceback.print_exc()
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    main()
