"""
This Cloud Function retrieves the most recent NBA games (from the NBA Stats API)
and updates a Firestore database with the results.

It also removes outdated games from the "games_schedule" collection to keep the data fresh.
"""

import functions_framework
import pandas as pd
import time
import requests
import os
from datetime import datetime, timedelta
import firebase_admin
from firebase_admin import credentials, firestore
from nba_api.stats.endpoints import leaguegamefinder

cred = credentials.Certificate("firebase_key.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

base_dir = os.path.dirname(__file__)
team_ids_path = os.path.join(base_dir, "../ai/utils/team_ids.csv")
team_ids_df = pd.read_csv(team_ids_path)
TEAM_IDS = dict(zip(team_ids_df["Team"], team_ids_df["ID"]))

@functions_framework.http
def update_games(request):
    season_start_date = '2025-10-21'
    season_phase = 'Regular Season'
    games_per_day = 15

    # Get games for 2025-26 season
    games = leaguegamefinder.LeagueGameFinder(season_nullable='2025-26')

    df = games.get_data_frames()[0]
    df['GAME_DATE'] = pd.to_datetime(df['GAME_DATE'])

    today = datetime.now()
    # Some games start in the morning
    today_morning = today.replace(hour=4, minute=0, second=0, microsecond=0)
    yesterday = (today - timedelta(days=1)).replace(hour=6, minute=0, second=0, microsecond=0)

    df = df[df['GAME_DATE'].dt.date == yesterday.date()]

    formatted_games = []

    for game_id in df['GAME_ID'].unique():
        game_data = df[df['GAME_ID'] == game_id]
        
        if len(game_data) != 2:
            continue

        home_team = game_data[game_data['MATCHUP'].str.contains('vs.')].iloc[0]
        away_team = game_data[game_data['MATCHUP'].str.contains('@')].iloc[0]
        
        team_id_home = TEAM_IDS.get(home_team['TEAM_NAME'], str(home_team['TEAM_ID']))
        team_id_away = TEAM_IDS.get(away_team['TEAM_NAME'], str(away_team['TEAM_ID']))
        
        # Create formatted game dictionary
        game_dict = {
            'game_id': int(game_id),
            'game_date': str(home_team['GAME_DATE']),
            'season_id': int(home_team['SEASON_ID']),
            'season_type': season_phase,
            'min': int(home_team['MIN']) if home_team['MIN'] else 240,
            
            'team_id_home': int(team_id_home),
            'team_id_away': int(team_id_away),
            
            'pts_home': int(home_team['PTS']),
            'pts_away': int(away_team['PTS']),
            
            'fgm_home': int(home_team['FGM']),
            'fgm_away': int(away_team['FGM']),
            'fga_home': int(home_team['FGA']),
            'fga_away': int(away_team['FGA']),
            'fg_pct_home': float(home_team['FG_PCT']),
            'fg_pct_away': float(away_team['FG_PCT']),
            
            'fg3m_home': int(home_team['FG3M']),
            'fg3m_away': int(away_team['FG3M']),
            'fg3a_home': int(home_team['FG3A']),
            'fg3a_away': int(away_team['FG3A']),
            'fg3_pct_home': float(home_team['FG3_PCT']),
            'fg3_pct_away': float(away_team['FG3_PCT']),

            'ftm_home': int(home_team['FTM']),
            'ftm_away': int(away_team['FTM']),
            'fta_home': int(home_team['FTA']),
            'fta_away': int(away_team['FTA']),
            'ft_pct_home': float(home_team['FT_PCT']),
            'ft_pct_away': float(away_team['FT_PCT']),
            
            'oreb_home': int(home_team['OREB']),
            'oreb_away': int(away_team['OREB']),
            'dreb_home': int(home_team['DREB']),
            'dreb_away': int(away_team['DREB']),
            'reb_home': int(home_team['REB']),
            'reb_away': int(away_team['REB']),
            
            'ast_home': int(home_team['AST']),
            'ast_away': int(away_team['AST']),
            'stl_home': int(home_team['STL']),
            'stl_away': int(away_team['STL']),
            'blk_home': int(home_team['BLK']),
            'blk_away': int(away_team['BLK']),
            'tov_home': int(home_team['TOV']),
            'tov_away': int(away_team['TOV']),
            'pf_home': int(home_team['PF']),
            'pf_away': int(away_team['PF']),
            
            'plus_minus_home': float(home_team['PLUS_MINUS']),
            'plus_minus_away': float(away_team['PLUS_MINUS']),
            
            'wl_home': home_team['WL'] if home_team['WL'] else '-',
            'wl_away': away_team['WL'] if away_team['WL'] else '-',
        }
        
        formatted_games.append(game_dict)

    formatted_df = pd.DataFrame(formatted_games)

    print("\n" + "="*60)
    print("FORMATTED GAMES (Home/Away Structure):")
    print("="*60)
    print(formatted_df)

    # Assign the yesterday played games into games_played
    for idx, row in formatted_df.iterrows():
        game_id = str(row['game_id'])
        print(game_id)
        game_ref = db.collection('games_played').document(game_id)
        game_data = row.to_dict()
        game_ref.set(game_data)

    schedule_docs = db.collection("games_schedule").order_by("startTime").limit(15).stream()

    for doc in schedule_docs:
        schedule_data = doc.to_dict()

        # Check if the game was no later than yesterday, else skip the game
        start_time = pd.to_datetime(schedule_data.get('startTime'))
        if ((str(start_time)).split("+"))[0] <= str(today_morning):
            print(f"Deleting old game: {schedule_data.get('gameId')} ({start_time})")
            db.collection("games_schedule").document(doc.id).delete()
            continue
    
    return f"Successfully updated games.", 200
