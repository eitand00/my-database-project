import psycopg2
from psycopg2.extras import execute_batch
import pandas as pd
import random
from datetime import datetime, timedelta
from collections import defaultdict

# Database config (same as your other script)
DB_CONFIG = {
    'dbname': 'my_database',
    'user': 'user2',
    'password': 'etdahan111',
    'host': 'localhost',
    'port': '5432'
}

# Kaggle CSV files
RESULTS_CSV = r'c:\Users\TOP\Downloads\archive\results.csv'
GOALSCORERS_CSV = r'c:\Users\TOP\Downloads\archive\goalscorers.csv'
FORMER_NAMES_CSV = r'c:\Users\TOP\Downloads\archive\former_names.csv'

# Positions for randomly assigned players
POSITIONS = ['Goalkeeper', 'Defender', 'Midfielder', 'Forward']

# Map countries to confederations
CONFEDERATIONS = {
    'Argentina': 'CONMEBOL', 'Brazil': 'CONMEBOL', 'Chile': 'CONMEBOL', 'Colombia': 'CONMEBOL',
    'Paraguay': 'CONMEBOL', 'Peru': 'CONMEBOL', 'Uruguay': 'CONMEBOL', 'Venezuela': 'CONMEBOL',
    'Belgium': 'UEFA', 'England': 'UEFA', 'France': 'UEFA', 'Germany': 'UEFA', 'Italy': 'UEFA',
    'Netherlands': 'UEFA', 'Portugal': 'UEFA', 'Spain': 'UEFA', 'Denmark': 'UEFA', 'Sweden': 'UEFA',
    'Poland': 'UEFA', 'Croatia': 'UEFA', 'Switzerland': 'UEFA', 'Austria': 'UEFA', 'Czech Republic': 'UEFA',
    'Greece': 'UEFA', 'Russia': 'UEFA', 'Ukraine': 'UEFA', 'Turkey': 'UEFA', 'Romania': 'UEFA',
    'Serbia': 'UEFA', 'Hungary': 'UEFA', 'Norway': 'UEFA', 'Slovakia': 'UEFA', 'Slovenia': 'UEFA',
    'Japan': 'AFC', 'South Korea': 'AFC', 'China PR': 'AFC', 'India': 'AFC', 'Iran': 'AFC',
    'Saudi Arabia': 'AFC', 'Australia': 'AFC', 'Thailand': 'AFC', 'Vietnam': 'AFC', 'UAE': 'AFC',
    'USA': 'CONCACAF', 'Mexico': 'CONCACAF', 'Canada': 'CONCACAF', 'Costa Rica': 'CONCACAF',
    'Honduras': 'CONCACAF', 'Jamaica': 'CONCACAF', 'Panama': 'CONCACAF', 'Suriname': 'CONCACAF',
    'Egypt': 'CAF', 'Nigeria': 'CAF', 'Cameroon': 'CAF', 'Morocco': 'CAF', 'Algeria': 'CAF',
    'Ghana': 'CAF', 'Ivory Coast': 'CAF', 'Senegal': 'CAF', 'Tunisia': 'CAF', 'Mali': 'CAF',
    'New Zealand': 'OFC', 'Australia': 'AFC', 'Samoa': 'OFC', 'Fiji': 'OFC',
}

def get_team_code(country_name):
    """Generate 3-letter team code from country name"""
    country_map = {
        'England': 'ENG', 'Scotland': 'SCO', 'Wales': 'WAL', 'Northern Ireland': 'NIR',
        'Republic of Ireland': 'IRL', 'South Korea': 'SKO', 'China PR': 'CHN', 'Czech Republic': 'CZE',
        'United States': 'USA', 'United Arab Emirates': 'UAE',
    }
    
    if country_name in country_map:
        return country_map[country_name]
    
    # Default: first 3 letters uppercase
    return country_name[:3].upper()

def get_confederation(country_name):
    """Get confederation for country"""
    return CONFEDERATIONS.get(country_name, 'OTHER')

def load_results_data():
    """Load and parse results.csv"""
    print("Loading results.csv...")
    df = pd.read_csv(RESULTS_CSV)
    df['date'] = pd.to_datetime(df['date'])
    return df

def load_goalscorers_data():
    """Load and parse goalscorers.csv"""
    print("Loading goalscorers.csv...")
    df = pd.read_csv(GOALSCORERS_CSV)
    df['date'] = pd.to_datetime(df['date'])
    return df

def main():
    print("🔄 Starting Kaggle data transformation...\n")
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return

    try:
        # Load Kaggle data
        results_df = load_results_data()
        goalscorers_df = load_goalscorers_data()
        
        print(f"✅ Loaded {len(results_df)} matches and {len(goalscorers_df)} goal records\n")

        # ===== 1. Extract and insert TEAMS =====
        print("📍 Processing TEAMS...")
        unique_teams = set()
        unique_teams.update(results_df['home_team'].unique())
        unique_teams.update(results_df['away_team'].unique())
        
        teams = []
        team_codes = {}
        for country in sorted(unique_teams):
            code = get_team_code(country)
            confederation = get_confederation(country)
            teams.append((code, country, confederation))
            team_codes[country] = code
        
        execute_batch(
            cursor,
            "INSERT INTO TEAM (TeamCode, CountryName, Confederation) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING",
            teams
        )
        print(f"✅ Inserted {len(teams)} teams\n")

        # ===== 2. Extract and insert STADIUMS =====
        print("📍 Processing STADIUMS...")
        stadium_data = results_df[['city', 'country']].drop_duplicates()
        stadiums = []
        stadium_ids = {}
        
        for idx, (city, country) in enumerate(stadium_data.values, 1):
            if pd.notna(city) and pd.notna(country):
                stadium_name = f"{city} Stadium"
                capacity = random.randint(40000, 100000)
                stadiums.append((idx, city, stadium_name, capacity))
                stadium_ids[(city, country)] = idx
        
        execute_batch(
            cursor,
            "INSERT INTO STADIUM (StadiumID, City, Name, Capacity) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING",
            stadiums
        )
        print(f"✅ Inserted {len(stadiums)} stadiums\n")

        # ===== 3. Extract goalscorers and create PERSONS =====
        print("📍 Processing PERSONS and PLAYERS...")
        unique_players = set(goalscorers_df['scorer'].dropna().unique())
        
        persons = []
        player_info = {}
        person_id = 1000  # Start from 1000 to avoid conflicts
        
        for player_name in unique_players:
            if pd.notna(player_name) and player_name.strip():
                dob = datetime(random.randint(1980, 2000), random.randint(1, 12), random.randint(1, 28)).date()
                persons.append((person_id, player_name, dob))
                player_info[player_name] = {
                    'id': person_id,
                    'dob': dob,
                    'teams': set()  # Will populate this
                }
                person_id += 1
        
        execute_batch(
            cursor,
            "INSERT INTO PERSON (ID, Name, DateOfBirth) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING",
            persons
        )
        print(f"✅ Inserted {len(persons)} players as persons\n")

        # Determine which team each player played for (using goalscorers data)
        for _, row in goalscorers_df.iterrows():
            if pd.notna(row['scorer']) and row['scorer'] in player_info:
                player_info[row['scorer']]['teams'].add(row['team'])
        
        # Create PLAYER records (assign to their first team, random position)
        print("📍 Creating PLAYER records...")
        players = []
        for player_name, info in player_info.items():
            if info['teams']:
                team_name = list(info['teams'])[0]
                team_code = team_codes.get(team_name, get_team_code(team_name))
                position = random.choice(POSITIONS)
                players.append((position, team_code, info['id']))
        
        execute_batch(
            cursor,
            "INSERT INTO PLAYER (Position, TeamCode, ID) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING",
            players
        )
        print(f"✅ Created {len(players)} player records\n")

        # ===== 4. Create dummy REFEREES =====
        print("📍 Creating dummy REFEREE records...")
        # Create 100 dummy referees
        persons_for_refs = []
        refs = []
        ref_person_id = person_id
        
        for i in range(100):
            dob = datetime(random.randint(1960, 1985), random.randint(1, 12), random.randint(1, 28)).date()
            persons_for_refs.append((ref_person_id, f"Referee_{i}", dob))
            refs.append((random.randint(1, 40), ref_person_id))
            ref_person_id += 1
        
        execute_batch(
            cursor,
            "INSERT INTO PERSON (ID, Name, DateOfBirth) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING",
            persons_for_refs
        )
        execute_batch(
            cursor,
            "INSERT INTO REFEREE (Years_of_experience, ID) VALUES (%s, %s) ON CONFLICT DO NOTHING",
            refs
        )
        print(f"✅ Created {len(refs)} referee records\n")

        # ===== 5. Insert MATCHES =====
        print("📍 Processing MATCHES...")
        matches = []
        match_id = 1
        match_lookup = {}  # (date, home, away) -> match_id
        referee_ids = [r[1] for r in refs]
        
        for _, row in results_df.iterrows():
            match_date = row['date'].date()
            home_team = row['home_team']
            away_team = row['away_team']
            
            # Skip matches where same team plays against itself
            if home_team == away_team:
                continue
            
            home_code = team_codes.get(home_team, get_team_code(home_team))
            away_code = team_codes.get(away_team, get_team_code(away_team))
            
            # Skip if teams end up with same code after mapping
            if home_code == away_code:
                continue
            
            stadium_id = stadium_ids.get((row['city'], row['country']), 1)
            referee_id = random.choice(referee_ids)
            stage = row.get('tournament', 'Friendly')
            
            matches.append((match_id, match_date, stage, home_code, away_code, stadium_id, referee_id))
            match_lookup[(pd.Timestamp(match_date), home_team, away_team)] = match_id
            match_id += 1
        
        execute_batch(
            cursor,
            "INSERT INTO MATCHES (MatchID, MatchDate, Stage, HomeTeamCode, AwayTeamCode, StadiumID, RefereeID) VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING",
            matches
        )
        print(f"✅ Inserted {len(matches)} matches\n")

        # ===== 6. Insert MATCH_EVENT (goals) =====
        print("📍 Processing MATCH_EVENTS (goals)...")
        events = []
        event_id = 0
        
        for _, row in goalscorers_df.iterrows():
            if pd.notna(row['scorer']) and row['scorer'] in player_info:
                match_key = (row['date'], row['home_team'], row['away_team'])
                if match_key in match_lookup:
                    match_id = match_lookup[match_key]
                    player_id = player_info[row['scorer']]['id']
                    minute = int(row['minute']) if pd.notna(row['minute']) else random.randint(1, 90)
                    event_type = 'Goal'
                    
                    if row.get('penalty', False):
                        event_type = 'Penalty Goal'
                    if row.get('own_goal', False):
                        event_type = 'Own Goal'
                    
                    events.append((minute, event_type, match_id, player_id))
        
        execute_batch(
            cursor,
            "INSERT INTO MATCH_EVENT (Minute, EventType, MatchID, PlayerID) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING",
            events
        )
        print(f"✅ Inserted {len(events)} match events\n")

        # ===== 7. Generate PLAYER_MATCH_STATS =====
        print("📍 Generating PLAYER_MATCH_STATS...")
        stats = []
        player_ids = [info['id'] for info in player_info.values()]
        
        for match_id in range(1, min(len(matches) + 1, 501)):  # Limit to 500 matches for stats
            # Random 15 players per match
            match_players = random.sample(player_ids, min(15, len(player_ids)))
            
            for player_id in match_players:
                minutes_played = random.randint(1, 120)
                distance_covered = round(random.uniform(1.0, 15.0), 2)
                stats.append((minutes_played, distance_covered, match_id, player_id))
        
        execute_batch(
            cursor,
            "INSERT INTO PLAYER_MATCH_STATS (MinutesPlayed, DistanceCovered, MatchID, PlayerID) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING",
            stats
        )
        print(f"✅ Inserted {len(stats)} player match stats\n")

        conn.commit()
        
        print("=" * 60)
        print("✅ SUCCESS! Kaggle data has been transformed and loaded!")
        print("=" * 60)
        print(f"📊 Summary:")
        print(f"  • Teams: {len(teams)}")
        print(f"  • Stadiums: {len(stadiums)}")
        print(f"  • Players (PERSON): {len(persons)}")
        print(f"  • Referees: {len(refs)}")
        print(f"  • Matches: {len(matches)}")
        print(f"  • Match Events (Goals): {len(events)}")
        print(f"  • Player Match Stats: {len(stats)}")
        print("=" * 60)

    except Exception as e:
        print(f"❌ Error during transformation: {e}")
        conn.rollback()
        import traceback
        traceback.print_exc()
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    main()
