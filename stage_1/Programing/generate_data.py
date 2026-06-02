import os
from pathlib import Path

import numpy as np
import pandas as pd
import psycopg2
from psycopg2.extras import execute_batch

DB_CONFIG = {
    'dbname': os.getenv('DB_NAME', os.getenv('DB_NAME_SECRET', 'my_database')),
    'user': os.getenv('DB_USER', os.getenv('DB_USER_SECRET', 'user2')),
    'password': os.getenv('DB_PASSWORD', os.getenv('DB_PASSWORD_SECRET', 'etdahan111')),
    'host': os.getenv('DB_HOST', 'db'),
    'port': os.getenv('DB_PORT', '5432'),
}

BASE_DIR = Path(__file__).resolve().parents[2]
DATASET_DIR = Path(os.getenv('DATASET_DIR', str(BASE_DIR / 'dataset')))
CUTOFF_DATE = pd.Timestamp('1970-01-01')


def clean_df_for_db(df: pd.DataFrame):
    return df.replace({np.nan: None}).to_dict('records')


def to_bool(series: pd.Series) -> pd.Series:
    return series.fillna(0).astype(int).astype(bool)


def load_csv(name: str) -> pd.DataFrame:
    return pd.read_csv(str(DATASET_DIR / name))


def filter_matches(matches_df: pd.DataFrame):
    match_dates = pd.to_datetime(matches_df['match_date'], errors='coerce')
    filtered = matches_df.loc[match_dates >= CUTOFF_DATE].copy()
    filtered['match_date'] = pd.to_datetime(filtered['match_date'], errors='coerce').dt.date
    return filtered, set(filtered['match_id'].dropna().astype(str)), set(filtered['tournament_id'].dropna().astype(str))


def main():
    print('Connecting to database...')
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
    except Exception as exc:
        print(f'Connection failed: {exc}')
        return

    try:
        print(f'Reading CSV files from {DATASET_DIR}...')
        players_df = load_csv('players.csv')
        referees_df = load_csv('referees.csv')
        teams_df = load_csv('teams.csv')
        stadiums_df = load_csv('stadiums.csv')
        matches_df = load_csv('matches.csv')
        ref_apps_df = load_csv('referee_appearances.csv')
        squads_df = load_csv('squads.csv')
        goals_df = load_csv('goals.csv')
        bookings_df = load_csv('bookings.csv')
        subs_df = load_csv('substitutions.csv')
        player_apps_df = load_csv('player_appearances.csv')

        filtered_matches_df, allowed_match_ids, allowed_tournament_ids = filter_matches(matches_df)
        filtered_ref_apps_df = ref_apps_df[ref_apps_df['match_id'].isin(allowed_match_ids)].copy()
        filtered_goals_df = goals_df[goals_df['match_id'].isin(allowed_match_ids)].copy()
        filtered_bookings_df = bookings_df[bookings_df['match_id'].isin(allowed_match_ids)].copy()
        filtered_subs_df = subs_df[subs_df['match_id'].isin(allowed_match_ids)].copy()
        filtered_player_apps_df = player_apps_df[player_apps_df['match_id'].isin(allowed_match_ids)].copy()
        filtered_squads_df = squads_df[squads_df['tournament_id'].isin(allowed_tournament_ids)].copy()

        print('Processing and inserting data. Please wait...')

        print('Inserting PERSON...')
        players_person = players_df[['player_id', 'family_name', 'given_name', 'player_wikipedia_link']].copy()
        players_person = players_person.rename(columns={
            'player_id': 'ID',
            'family_name': 'FamilyName',
            'given_name': 'GivenName',
            'player_wikipedia_link': 'WikipediaPage',
        })
        referees_person = referees_df[['referee_id', 'family_name', 'given_name', 'referee_wikipedia_link']].copy()
        referees_person = referees_person.rename(columns={
            'referee_id': 'ID',
            'family_name': 'FamilyName',
            'given_name': 'GivenName',
            'referee_wikipedia_link': 'WikipediaPage',
        })
        person_df = pd.concat([players_person, referees_person], ignore_index=True).drop_duplicates(subset=['ID'])
        person_records = [(r['ID'], r['FamilyName'], r['GivenName'], None if r['WikipediaPage'] == 'not available' else r['WikipediaPage']) for r in clean_df_for_db(person_df)]
        execute_batch(cursor, 'INSERT INTO PERSON (ID, FamilyName, GivenName, WikipediaPage) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING', person_records)

        print('Inserting TEAM...')
        team_table = teams_df[['team_id', 'team_name', 'confederation_name', 'confederation_code', 'team_wikipedia_link']].copy()
        team_table = team_table.rename(columns={
            'team_id': 'TeamCode',
            'team_name': 'CountryName',
            'confederation_name': 'ConfederationName',
            'confederation_code': 'ConfederationCode',
            'team_wikipedia_link': 'WikipediaPage',
        })
        team_records = [(r['TeamCode'], r['CountryName'], r['ConfederationName'], r['ConfederationCode'], None if r['WikipediaPage'] == 'not available' else r['WikipediaPage']) for r in clean_df_for_db(team_table)]
        execute_batch(cursor, 'INSERT INTO TEAM (TeamCode, CountryName, ConfederationName, ConfederationCode, WikipediaPage) VALUES (%s, %s, %s, %s, %s) ON CONFLICT DO NOTHING', team_records)

        print('Inserting STADIUM...')
        stadium_table = stadiums_df[['stadium_id', 'city_name', 'stadium_name', 'stadium_capacity', 'stadium_wikipedia_link', 'country_name']].copy()
        stadium_table = stadium_table.rename(columns={
            'stadium_id': 'StadiumID',
            'city_name': 'City',
            'stadium_name': 'Name',
            'stadium_capacity': 'Capacity',
            'stadium_wikipedia_link': 'WikipediaPage',
            'country_name': 'Country',
        })
        stadium_records = [(r['StadiumID'], r['City'], r['Name'], r['Capacity'], None if r['WikipediaPage'] == 'not available' else r['WikipediaPage'], r['Country']) for r in clean_df_for_db(stadium_table)]
        execute_batch(cursor, 'INSERT INTO STADIUM (StadiumID, City, Name, Capacity, WikipediaPage, Country) VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING', stadium_records)

        print('Inserting PLAYER...')
        player_dates = players_df[['player_id', 'birth_date']].copy()
        player_dates['birth_date'] = player_dates['birth_date'].replace('not available', None)
        player_squads = filtered_squads_df[['player_id', 'team_id']].copy().drop_duplicates(subset=['player_id'])
        player_table = player_dates.merge(player_squads, on='player_id', how='left')
        player_table = player_table.rename(columns={
            'player_id': 'ID',
            'birth_date': 'DateOfBirth',
            'team_id': 'TeamCode',
        })
        player_records = [(r['DateOfBirth'], r['TeamCode'], r['ID']) for r in clean_df_for_db(player_table)]
        execute_batch(cursor, 'INSERT INTO PLAYER (DateOfBirth, TeamCode, ID) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING', player_records)

        print('Inserting REFEREE...')
        referee_table = referees_df[['referee_id', 'country_name', 'confederation_code', 'confederation_name']].copy()
        referee_table = referee_table.rename(columns={
            'referee_id': 'ID',
            'country_name': 'Country',
            'confederation_code': 'ConfederationCode',
            'confederation_name': 'ConfederationName',
        })
        referee_records = [(r['Country'], r['ConfederationCode'], r['ConfederationName'], r['ID']) for r in clean_df_for_db(referee_table)]
        execute_batch(cursor, 'INSERT INTO REFEREE (Country, ConfederationCode, ConfederationName, ID) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING', referee_records)

        print('Inserting MATCH...')
        main_referees = filtered_ref_apps_df.drop_duplicates(subset=['match_id'])[['match_id', 'referee_id']]
        match_table = filtered_matches_df[['match_id', 'match_date', 'stage_name', 'tournament_name', 'match_time', 'stadium_id', 'away_team_id', 'home_team_id']].copy()
        match_table = match_table.merge(main_referees, on='match_id', how='left')
        match_table = match_table.rename(columns={
            'match_id': 'MatchID',
            'match_date': 'MatchDate',
            'stage_name': 'Stage',
            'tournament_name': 'Tournament',
            'match_time': 'MatchTime',
            'stadium_id': 'StadiumID',
            'away_team_id': 'GuestTeamCode',
            'home_team_id': 'HomeTeamCode',
            'referee_id': 'RefereeID',
        })
        match_records = [
            (r['MatchID'], r['MatchDate'], r['Stage'], r['Tournament'], r['MatchTime'], r['StadiumID'], r['GuestTeamCode'], r['HomeTeamCode'], r['RefereeID'])
            for r in clean_df_for_db(match_table)
        ]
        execute_batch(cursor, 'INSERT INTO MATCH (MatchID, MatchDate, Stage, Tournament, MatchTime, StadiumID, GuestTeamCode, HomeTeamCode, RefereeID) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING', match_records)

        print('Inserting MATCH_EVENT...')
        goals = filtered_goals_df[['goal_id', 'minute_label', 'match_id', 'player_id', 'own_goal', 'penalty']].copy()
        goals = goals.rename(columns={'goal_id': 'MatchEventID', 'minute_label': 'Minute', 'match_id': 'MatchID', 'player_id': 'ID'})
        goals['EventType'] = goals.apply(
            lambda row: 'Own Goal' if row['own_goal'] == 1 else ('Penalty Goal' if row['penalty'] == 1 else 'Goal'),
            axis=1,
        )

        bookings = filtered_bookings_df[['booking_id', 'minute_label', 'match_id', 'player_id', 'yellow_card', 'red_card', 'second_yellow_card', 'sending_off']].copy()
        bookings = bookings.rename(columns={'booking_id': 'MatchEventID', 'minute_label': 'Minute', 'match_id': 'MatchID', 'player_id': 'ID'})
        bookings['EventType'] = bookings.apply(
            lambda row: 'Red Card' if row['red_card'] == 1 else (
                'Second Yellow Card' if row['second_yellow_card'] == 1 else (
                    'Sending Off' if row['sending_off'] == 1 else 'Yellow Card'
                )
            ),
            axis=1,
        )

        subs = filtered_subs_df[['substitution_id', 'minute_label', 'match_id', 'player_id']].copy()
        subs = subs.rename(columns={'substitution_id': 'MatchEventID', 'minute_label': 'Minute', 'match_id': 'MatchID', 'player_id': 'ID'})
        subs['EventType'] = 'Substitution'

        match_events_df = pd.concat([
            goals[['MatchEventID', 'Minute', 'EventType', 'MatchID', 'ID']],
            bookings[['MatchEventID', 'Minute', 'EventType', 'MatchID', 'ID']],
            subs[['MatchEventID', 'Minute', 'EventType', 'MatchID', 'ID']],
        ], ignore_index=True)
        match_event_records = [(r['Minute'], r['EventType'], r['MatchEventID'], r['MatchID'], r['ID']) for r in clean_df_for_db(match_events_df)]
        execute_batch(cursor, 'INSERT INTO MATCH_EVENT (Minute, EventType, MatchEventID, MatchID, ID) VALUES (%s, %s, %s, %s, %s) ON CONFLICT DO NOTHING', match_event_records)

        print('Inserting PLAYER_MATCH_STATS...')
        player_stats_table = filtered_player_apps_df[['position_name', 'shirt_number', 'match_id', 'player_id']].copy()
        player_stats_table = player_stats_table.rename(columns={
            'position_name': 'Position',
            'shirt_number': 'ShirtNumber',
            'match_id': 'MatchID',
            'player_id': 'PlayerID',
        })
        player_stats_records = [(r['Position'], r['ShirtNumber'], r['MatchID'], r['PlayerID']) for r in clean_df_for_db(player_stats_table)]
        execute_batch(cursor, 'INSERT INTO PLAYER_MATCH_STATS (Position, ShirtNumber, MatchID, PlayerID) VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING', player_stats_records)

        conn.commit()
        print('Success: data transferred to the database.')

    except Exception as exc:
        print(f'Error during execution: {exc}')
        conn.rollback()
    finally:
        cursor.close()
        conn.close()


if __name__ == '__main__':
    main()
