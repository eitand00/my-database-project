from db_connection import get_connection
conn = get_connection()
cur = conn.cursor()
tables = ['bets','odds','users','global_match']
for t in tables:
    try:
        cur.execute(f"SELECT COUNT(*) FROM {t}")
        c = cur.fetchone()[0]
        print(f"  {t}: {c} rows")
    except Exception as e:
        print(f"  {t}: MISSING - {e}")
cur.close()
conn.close()
