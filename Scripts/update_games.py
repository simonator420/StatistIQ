# update_games.py - With proxy rotation support
from nba_api.stats.endpoints import leaguegamefinder
from nba_api.stats.static import teams
import pandas as pd
from datetime import date, timedelta, datetime
import firebase_admin
from firebase_admin import credentials, firestore
import time
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import os

# Configure nba_api with custom headers
from nba_api.stats.library.http import NBAStatsHTTP

class CustomNBAStatsHTTP(NBAStatsHTTP):
    def send_api_request(self, endpoint, parameters, referer=None, proxy=None, headers=None, timeout=30):
        # Enhanced headers to avoid detection
        request_headers = {
            'Host': 'stats.nba.com',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Referer': 'https://www.nba.com/',
            'Origin': 'https://www.nba.com',
            'x-nba-stats-origin': 'stats',
            'x-nba-stats-token': 'true',
        }
        
        if headers:
            request_headers.update(headers)
            
        return super().send_api_request(
            endpoint=endpoint,
            parameters=parameters,
            referer=referer or 'https://www.nba.com/',
            proxy=proxy,
            headers=request_headers,
            timeout=timeout
        )

# Monkey patch the HTTP class
import nba_api.stats.library.http as http_module
http_module.NBAStatsHTTP = CustomNBAStatsHTTP

cred = credentials.Certificate("firebase_key.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Team ID mapping
TEAM_IDS = {
    'Atlanta Hawks': '132',
    'Boston Celtics': '133',
    'Brooklyn Nets': '134',
    'Charlotte Hornets': '135',
    'Chicago Bulls': '136',
    'Cleveland Cavaliers': '137',
    'Dallas Mavericks': '138',
    'Denver Nuggets': '139',
    'Detroit Pistons': '140',
    'Golden State Warriors': '141',
    'Houston Rockets': '142',
    'Indiana Pacers': '143',
    'LA Clippers': '144',
    'Los Angeles Lakers': '145',
    'Memphis Grizzlies': '146',
    'Miami Heat': '147',
    'Milwaukee Bucks': '148',
    'Minnesota Timberwolves': '149',
    'New Orleans Pelicans': '150',
    'New York Knicks': '151',
    'Oklahoma City Thunder': '152',
    'Orlando Magic': '153',
    'Philadelphia 76ers': '154',
    'Phoenix Suns': '155',
    'Portland Trail Blazers': '156',
    'Sacramento Kings': '157',
    'San Antonio Spurs': '158',
    'Toronto Raptors': '159',
    'Utah Jazz': '160',
    'Washington Wizards': '161'
}

CURRENT_SEASON = '2024-25'
MAX_RETRIES = 5

print(f"Fetching games for season: {CURRENT_SEASON}")

# Get games with exponential backoff
for attempt in range(MAX_RETRIES):
    try:
        print(f"Attempt {attempt + 1}/{MAX_RETRIES} to connect to NBA API...")
        
        # Add delay before request (helps avoid rate limiting)
        if attempt > 0:
            delay = min(30 * (2 ** attempt), 300)  # Exponential backoff, max 5 minutes
            print(f"Waiting {delay}s before retry...")
            time.sleep(delay)
        
        # Initial delay to look more human
        time.sleep(3)
        
        games = leaguegamefinder.LeagueGameFinder(
            season_nullable=CURRENT_SEASON,
            timeout=60
        )
        print("Successfully connected to NBA API")
        break
        
    except requests.exceptions.ReadTimeout as e:
        print(f"Timeout on attempt {attempt + 1}/{MAX_RETRIES}: {str(e)}")
        if attempt == MAX_RETRIES - 1:
            raise SystemExit("Failed to connect to stats.nba.com after multiple retries. The API may be blocking GitHub Actions IPs.")
            
    except requests.exceptions.HTTPError as e:
        print(f"HTTP Error on attempt {attempt + 1}/{MAX_RETRIES}: {str(e)}")
        if e.response.status_code == 429:  # Rate limited
            print("Rate limited by NBA API")
        if attempt == MAX_RETRIES - 1:
            raise SystemExit(f"Failed to connect: {str(e)}")
            
    except Exception as e:
        print(f"Error on attempt {attempt + 1}/{MAX_RETRIES}: {str(e)}")
        if attempt == MAX_RETRIES - 1:
            raise SystemExit(f"Failed to connect: {str(e)}")

df = games.get_data_frames()[0]
print(f"Retrieved {len(df)} game records")

df['GAME_DATE'] = pd.to_datetime(df['GAME_DATE'])

today = datetime.now()
today_morning = today.replace(hour=4, minute=0, second=0, microsecond=0)
yesterday = (today - timedelta(days=1)).replace(hour=6, minute=0, second=0, microsecond=0)

print(f"Looking for games on: {yesterday.date()}")
df = df[df['GAME_DATE'].dt.date == yesterday.date()]
print(f"Found {len(df)} records for yesterday's games")

formatted_games = []

for game_id in df['GAME_ID'].unique():
    game_data = df[df['GAME_ID'] == game_id]
    
    if len(game_data) != 2:
        print(f"Warning: Game {game_id} has {len(game_data)} records (expected 2), skipping")
        continue

    home_team = game_data[game_data['MATCHUP'].str.contains('vs.')].iloc[0]
    away_team = game_data[game_data['MATCHUP'].str.contains('@')].iloc[0]
    
    team_id_home = TEAM_IDS.get(home_team['TEAM_NAME'], str(home_team['TEAM_ID']))
    team_id_away = TEAM_IDS.get(away_team['TEAM_NAME'], str(away_team['TEAM_ID']))
    
    game_dict = {
        'game_id': int(game_id),
        'game_date': str(home_team['GAME_DATE']),
        'season_id': int(home_team['SEASON_ID']),
        'season_type': 'Regular Season',
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

if not formatted_games:
    print("No games found for yesterday.")
else:
    formatted_df = pd.DataFrame(formatted_games)
    print(f"\nUploading {len(formatted_games)} games to Firestore...")
    
    for idx, row in formatted_df.iterrows():
        game_id = str(row['game_id'])
        print(f"Uploading game: {game_id}")
        game_ref = db.collection('games_played').document(game_id)
        game_data = row.to_dict()
        game_ref.set(game_data)
    
    print("Successfully uploaded all games")

# Clean up old scheduled games
print("\nCleaning up old scheduled games...")
schedule_docs = db.collection("games_schedule").order_by("startTime").limit(15).stream()

deleted_count = 0
for doc in schedule_docs:
    schedule_data = doc.to_dict()
    start_time = pd.to_datetime(schedule_data.get('startTime'))
    if ((str(start_time)).split("+"))[0] <= str(today_morning):
        print(f"Deleting old game: {schedule_data.get('gameId')} ({start_time})")
        db.collection("games_schedule").document(doc.id).delete()
        deleted_count += 1

print(f"Deleted {deleted_count} old scheduled games")
print("\nScript completed successfully!")