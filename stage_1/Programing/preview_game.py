import psycopg2

DB_CONFIG = {
    'dbname': 'my_database',
    'user': 'user2',
    'password': 'etdahan111',
    'host': 'localhost',
    'port': '5432'
}

conn = psycopg2.connect(**DB_CONFIG)
cursor = conn.cursor()

# Get a match with events
cursor.execute('''
SELECT m.MatchID, m.MatchDate, m.Stage, ht.CountryName, at.CountryName, 
       s.Name, s.City, COUNT(me.MatchID) as goals
FROM MATCHES m
JOIN TEAM ht ON m.HomeTeamCode = ht.TeamCode
JOIN TEAM at ON m.AwayTeamCode = at.TeamCode
JOIN STADIUM s ON m.StadiumID = s.StadiumID
LEFT JOIN MATCH_EVENT me ON m.MatchID = me.MatchID
WHERE m.MatchID IN (SELECT DISTINCT MatchID FROM MATCH_EVENT)
GROUP BY m.MatchID, m.MatchDate, m.Stage, ht.CountryName, at.CountryName, s.Name, s.City
LIMIT 1
''')

result = cursor.fetchone()
if result:
    match_id, date, stage, home, away, stadium, city, goals = result
    
    print('='*70)
    print(f'MATCH #{match_id}')
    print('='*70)
    print(f'Date:     {date}')
    print(f'Stage:    {stage}')
    print(f'Teams:    {home} vs {away}')
    print(f'Stadium:  {stadium} ({city})')
    print(f'Goals:    {goals}')
    print()
    
    # Get goals
    cursor.execute('''
    SELECT me.Minute, me.EventType, p.Name, t.CountryName, pl.Position
    FROM MATCH_EVENT me
    JOIN PLAYER pl ON me.PlayerID = pl.ID
    JOIN PERSON p ON pl.ID = p.ID
    JOIN TEAM t ON pl.TeamCode = t.TeamCode
    WHERE me.MatchID = %s
    ORDER BY me.Minute
    ''', (match_id,))
    
    print('GOALS SCORED:')
    print('-'*70)
    events = cursor.fetchall()
    if events:
        for minute, event_type, player, team, position in events:
            print(f'  Min {minute}: {event_type:15} | {player:20} ({team})')
    else:
        print('  No goals recorded')
    
    print()
    print('PLAYER STATISTICS:')
    print('-'*70)
    
    # Get player stats
    cursor.execute('''
    SELECT p.Name, t.CountryName, pl.Position, pms.MinutesPlayed, pms.DistanceCovered
    FROM PLAYER_MATCH_STATS pms
    JOIN PLAYER pl ON pms.PlayerID = pl.ID
    JOIN PERSON p ON pl.ID = p.ID
    JOIN TEAM t ON pl.TeamCode = t.TeamCode
    WHERE pms.MatchID = %s
    ORDER BY pms.MinutesPlayed DESC
    LIMIT 15
    ''', (match_id,))
    
    stats = cursor.fetchall()
    if stats:
        print('Player                Team            Position       Minutes Distance')
        print('-'*70)
        for player, team, pos, minutes, distance in stats:
            print(f'{player:22} {team:17} {pos:13} {minutes:8} {distance:10.2f}km')
    else:
        print('  No player statistics available')
    
    print('='*70)
else:
    print('No matches with events found in database')

cursor.close()
conn.close()
