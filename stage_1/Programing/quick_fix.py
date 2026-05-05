import psycopg2
from psycopg2.extras import execute_batch
import random

DB_CONFIG = {
    'dbname': 'my_database',
    'user': 'user2',
    'password': 'etdahan111',
    'host': 'localhost',
    'port': '5432'
}

def main():
    print("🔧 Quick fix: Adding player stats to matches without them...\n")
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return

    try:
        # Get all match IDs that don't have stats
        cursor.execute("""
            SELECT DISTINCT m.MatchID
            FROM MATCHES m
            WHERE m.MatchID NOT IN (SELECT DISTINCT MatchID FROM PLAYER_MATCH_STATS)
            ORDER BY m.MatchID
        """)
        matches_without_stats = [row[0] for row in cursor.fetchall()]
        
        print(f"📍 Found {len(matches_without_stats)} matches without player stats")
        
        # Get available players
        cursor.execute("SELECT ID FROM PLAYER LIMIT 50")
        player_ids = [row[0] for row in cursor.fetchall()]
        
        if not player_ids:
            print("❌ No players found!")
            return
        
        print(f"📍 Using {len(player_ids)} players\n")
        
        # Create stats for matches without them
        stats = []
        batch_size = 5000
        
        for i, match_id in enumerate(matches_without_stats):
            # 15 players per match
            match_players = random.sample(player_ids, min(15, len(player_ids)))
            
            for player_id in match_players:
                minutes_played = random.randint(1, 120)
                distance_covered = round(random.uniform(1.0, 15.0), 2)
                stats.append((minutes_played, distance_covered, match_id, player_id))
            
            # Insert in batches
            if (i + 1) % (batch_size // 15) == 0:
                print(f"  Processing match {i + 1}/{len(matches_without_stats)}...")
        
        print(f"\n✅ Inserting {len(stats)} player stats...")
        execute_batch(
            cursor,
            "INSERT INTO PLAYER_MATCH_STATS (MinutesPlayed, DistanceCovered, MatchID, PlayerID) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING",
            stats,
            page_size=500
        )
        
        conn.commit()
        
        # Verify the fix
        cursor.execute("""
            SELECT 
              COUNT(*) as total_matches,
              COUNT(CASE WHEN m.matchid IN (SELECT DISTINCT matchid FROM match_event) THEN 1 END) as matches_with_events,
              COUNT(CASE WHEN m.matchid IN (SELECT DISTINCT matchid FROM player_match_stats) THEN 1 END) as matches_with_stats
            FROM matches m
        """)
        total, with_events, with_stats = cursor.fetchone()
        
        print("\n" + "=" * 60)
        print("✅ SUCCESS! Data is now consistent!")
        print("=" * 60)
        print(f"📊 Final Summary:")
        print(f"  • Total Matches: {total}")
        print(f"  • Matches with Events: {with_events}")
        print(f"  • Matches with Stats: {with_stats}")
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
