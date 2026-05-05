import psycopg2
import pandas as pd

DB_CONFIG = {
    'dbname': 'my_database',
    'user': 'user2',
    'password': 'etdahan111',
    'host': 'localhost',
    'port': '5432'
}

print("🔧 Cleaning database - keeping ONLY real Kaggle data...\n")

conn = psycopg2.connect(**DB_CONFIG)
cursor = conn.cursor()

# Load real goal scorers from Kaggle
print("📊 Loading real goal scorers from Kaggle...")
df = pd.read_csv(r'c:\Users\TOP\Downloads\archive\goalscorers.csv')
real_scorers = set(df['scorer'].dropna().unique())
print(f"✅ Found {len(real_scorers)} real goal scorers\n")

# Step 1: Delete all PLAYER_MATCH_STATS and MATCH_EVENT with synthetic players
print("🗑️  Deleting synthetic player data...")

# Get real player IDs (those with names in goalscorers)
cursor.execute('''
    SELECT DISTINCT ID FROM PLAYER 
    JOIN PERSON ON PLAYER.ID = PERSON.ID
    WHERE PERSON.Name IN %s
''', (tuple(real_scorers),))

real_player_ids = [row[0] for row in cursor.fetchall()]
print(f"✅ Found {len(real_player_ids)} real players in database\n")

if real_player_ids:
    # Delete stats from synthetic players
    cursor.execute('''
        DELETE FROM PLAYER_MATCH_STATS 
        WHERE PlayerID NOT IN %s
    ''', (tuple(real_player_ids),))
    deleted_stats = cursor.rowcount
    print(f"✅ Deleted {deleted_stats:,} synthetic player stats")
    
    # Delete events from synthetic players
    cursor.execute('''
        DELETE FROM MATCH_EVENT 
        WHERE PlayerID NOT IN %s
    ''', (tuple(real_player_ids),))
    deleted_events = cursor.rowcount
    print(f"✅ Deleted {deleted_events:,} synthetic events\n")
    
    # Step 2: Delete synthetic PLAYER records
    cursor.execute('''
        DELETE FROM PLAYER 
        WHERE ID NOT IN %s
    ''', (tuple(real_player_ids),))
    deleted_players = cursor.rowcount
    print(f"✅ Deleted {deleted_players:,} synthetic players\n")
    
    # Step 3: Delete synthetic PERSON records
    cursor.execute('''
        DELETE FROM PERSON 
        WHERE ID NOT IN (
            SELECT DISTINCT ID FROM PLAYER
            UNION
            SELECT DISTINCT ID FROM REFEREE
        )
    ''')
    deleted_persons = cursor.rowcount
    print(f"✅ Deleted {deleted_persons:,} synthetic persons\n")

conn.commit()

# Verify final data
print("="*60)
print("FINAL DATA STATUS:")
print("="*60)

cursor.execute('SELECT COUNT(*) FROM MATCHES')
total_matches = cursor.fetchone()[0]

cursor.execute('SELECT COUNT(*) FROM TEAM')
total_teams = cursor.fetchone()[0]

cursor.execute('SELECT COUNT(*) FROM STADIUM')
total_stadiums = cursor.fetchone()[0]

cursor.execute('SELECT COUNT(*) FROM PERSON')
total_persons = cursor.fetchone()[0]

cursor.execute('SELECT COUNT(*) FROM PLAYER')
total_players = cursor.fetchone()[0]

cursor.execute('SELECT COUNT(*) FROM REFEREE')
total_referees = cursor.fetchone()[0]

cursor.execute('SELECT COUNT(*) FROM MATCH_EVENT')
total_events = cursor.fetchone()[0]

cursor.execute('SELECT COUNT(*) FROM PLAYER_MATCH_STATS')
total_stats = cursor.fetchone()[0]

cursor.execute('SELECT COUNT(DISTINCT MatchID) FROM MATCH_EVENT')
matches_with_events = cursor.fetchone()[0]

print(f"  Matches:          {total_matches:,}")
print(f"  Teams:            {total_teams:,}")
print(f"  Stadiums:         {total_stadiums:,}")
print(f"  Persons:          {total_persons:,}")
print(f"  Players:          {total_players:,}")
print(f"  Referees:         {total_referees:,}")
print(f"  Match Events:     {total_events:,}")
print(f"  Matches w/Goals:  {matches_with_events:,}")
print(f"  Player Stats:     {total_stats:,}")
print("="*60)

cursor.close()
conn.close()

print("\n✅ Database cleaned! Only REAL Kaggle data remains.")
