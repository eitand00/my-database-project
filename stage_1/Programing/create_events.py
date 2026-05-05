import psycopg2
from psycopg2.extras import execute_batch
import pandas as pd
import random

DB_CONFIG = {
    'dbname': 'my_database',
    'user': 'user2',
    'password': 'etdahan111',
    'host': 'localhost',
    'port': '5432'
}

print("⚡ Fast: Loading matches and creating events...\n")

conn = psycopg2.connect(**DB_CONFIG)
cursor = conn.cursor()

# Load ALL matches into memory (fast lookups)
print("📍 Loading matches into memory...")
cursor.execute('''
    SELECT MatchID, MatchDate::text, HomeTeamCode, AwayTeamCode 
    FROM MATCHES
''')
matches_data = cursor.fetchall()

# Create lookup: (date, home_code, away_code) -> match_id
match_lookup = {}
for match_id, date_str, home_code, away_code in matches_data:
    key = (date_str[:10], home_code, away_code)  # Use YYYY-MM-DD format
    match_lookup[key] = match_id

print(f"✅ Loaded {len(match_lookup)} matches\n")

# Load goalscorers data
print("📊 Loading Kaggle goalscorers.csv...")
df = pd.read_csv(r'c:\Users\TOP\Downloads\archive\goalscorers.csv')
df['date'] = pd.to_datetime(df['date'])

# Get team code mapping
cursor.execute("SELECT TeamCode, CountryName FROM TEAM")
team_map = {name: code for code, name in cursor.fetchall()}

# Get some player IDs
cursor.execute("SELECT ID FROM PLAYER")
player_ids = [row[0] for row in cursor.fetchall()]

print(f"✅ Loaded {len(player_ids)} players\n")

events = []
created = 0

print(f"Processing {len(df)} goal records...\n")

for idx, row in df.iterrows():
    if idx % 5000 == 0:
        print(f"  {idx}/{len(df)} records processed...")
    
    date_str = row['date'].strftime('%Y-%m-%d')
    home_team = row['home_team']
    away_team = row['away_team']
    
    home_code = team_map.get(home_team)
    away_code = team_map.get(away_team)
    
    if not home_code or not away_code:
        continue
    
    key = (date_str, home_code, away_code)
    
    if key not in match_lookup:
        continue
    
    match_id = match_lookup[key]
    minute = int(row['minute']) if pd.notna(row['minute']) else random.randint(1, 90)
    event_type = 'Goal'
    
    if pd.notna(row.get('penalty')) and row['penalty']:
        event_type = 'Penalty Goal'
    if pd.notna(row.get('own_goal')) and row['own_goal']:
        event_type = 'Own Goal'
    
    player_id = random.choice(player_ids)
    
    events.append((minute, event_type, match_id, player_id))
    created += 1
    
    if len(events) >= 5000:
        execute_batch(cursor, 
            "INSERT INTO MATCH_EVENT (Minute, EventType, MatchID, PlayerID) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING",
            events)
        events = []

# Insert remaining
if events:
    execute_batch(cursor, 
        "INSERT INTO MATCH_EVENT (Minute, EventType, MatchID, PlayerID) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING",
        events)

conn.commit()

print(f"\n✅ Created {created} match events\n")

# Verify
cursor.execute('SELECT COUNT(DISTINCT MatchID) FROM MATCH_EVENT')
matches_with_events = cursor.fetchone()[0]

cursor.execute('SELECT COUNT(*) FROM MATCH_EVENT')
total_events = cursor.fetchone()[0]

print(f"Final Status:")
print(f"  Matches with Events: {matches_with_events:,}")
print(f"  Total Events:        {total_events:,}")

cursor.close()
conn.close()
