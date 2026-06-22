from db_connection import get_connection
conn = get_connection()
cur = conn.cursor()
cur.execute("""
    SELECT table_schema, table_name FROM information_schema.tables 
    WHERE table_name IN ('match','team','player','person','stadium','referee',
                         'match_event','player_match_stats','global_match')
    ORDER BY table_name
""")
rows = cur.fetchall()
if rows:
    for r in rows:
        print(f"  Found: {r[0]}.{r[1]}")
else:
    print("  No World Cup tables found")

cur.execute("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'")
print(f"Total tables in public: {cur.fetchone()[0]}")
cur.close()
conn.close()
