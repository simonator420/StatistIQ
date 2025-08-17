import kagglehub
from datetime import datetime
import pandas as pd
import random
import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("statistiq-5158d-firebase-adminsdk-fbsvc-51f4cb04e0.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

def prepare_dataframe(csv_path):
    df = pd.read_csv(csv_path)
    df = df.loc[df['game_date'] > '2019']
    df = df[df['team_name_home'].map(df['team_name_home'].value_counts()) > 10]

    df.replace({'team_name_away': {'LA Clippers': 'Los Angeles Clippers'},
                'team_name_home': {'LA Clippers': 'Los Angeles Clippers'}},
            inplace=True)

    teams_sorted = sorted(df['team_name_home'].unique())
    new_ids = range(132, 132+len(teams_sorted)-1)
    team_id_map = {team: new_id for team, new_id in zip(teams_sorted, new_ids)}

    df['team_id_home'] = df['team_name_home'].map(team_id_map)
    df['team_id_away'] = df['team_name_away'].map(team_id_map)

    columns_to_keep = [
        'season_id', 'team_id_home', 'game_id', 'game_date', 'wl_home', 'min',
        'fgm_home', 'fga_home', 'fg_pct_home', 'fg3m_home', 'fg3a_home', 'fg3_pct_home',
        'ftm_home', 'fta_home', 'ft_pct_home', 'oreb_home', 'dreb_home', 'reb_home',
        'ast_home', 'stl_home', 'blk_home', 'tov_home', 'pf_home', 'pts_home', 'plus_minus_home',
        'team_id_away', 'wl_away', 'fgm_away', 'fga_away', 'fg_pct_away',
        'fg3m_away', 'fg3a_away', 'fg3_pct_away', 'ftm_away', 'fta_away', 'ft_pct_away',
        'oreb_away', 'dreb_away', 'reb_away', 'ast_away', 'stl_away', 'blk_away',
        'tov_away', 'pf_away', 'pts_away', 'plus_minus_away', 'season_type'
    ]
    
    return df[columns_to_keep]

def upload_games_to_firestore(df, limit=None):
    if limit is not None:
        df = df.head(limit)
    
    for _, row in df.iterrows():
        game_id = str(row['game_id'])
        game_ref = db.collection("games_played").document(game_id)

        if game_ref.get().exists:
            print(f"Game {game_id} already exists. Skipping...")
            continue

        game_data = row.to_dict()

        game_ref.set(game_data)
        print(f"Uploaded game {game_id}")
        
# df = prepare_dataframe('/Users/simonsalaj/Library/Mobile Documents/com~apple~CloudDocs/StatistIQ/StatistIQApp/Services/csv/game.csv')
# upload_games_to_firestore(df)

def create_game_schedule(
    game_id,
    home_team_id,
    away_team_id,
    start_datetime,  # Python datetime object
    venue,
    home_win_prob,
    away_win_prob,
    home_points_range,
    away_points_range,
    expected_margin
):
    collection = db.collection("games_schedule")
    predicted_winner = home_team_id if home_win_prob >= away_win_prob else away_team_id

    game_data = {
        "gameId": game_id,
        "teams": {
            "homeId": home_team_id,
            "awayId": away_team_id
        },
        "startTime": start_datetime,
        "venue": venue,
        "predictions": {
            "winProbability": {
                "home": home_win_prob,
                "away": away_win_prob
            },
            "pointsRange": {
                "home": {"min": home_points_range[0], "max": home_points_range[1]},
                "away": {"min": away_points_range[0], "max": away_points_range[1]}
            },
            "expectedMargin": {
                "teamId": predicted_winner,
                "value": expected_margin
            }
        },
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP
    }

    collection.document(str(game_id)).set(game_data)
    print(f"Game schedule {game_id} created.")

# Example usage
# create_game_schedule(
#     game_id=124,
#     home_team_id=134,
#     away_team_id=135,
#     start_datetime=datetime(2025, 2, 22, 19, 30),
#     venue="Madison Square Garden, New York, USA",
#     home_win_prob=0.62,
#     away_win_prob=0.38,
#     home_points_range=(99, 105),
#     away_points_range=(94, 100),
#     expected_margin=6.2
# )

TEAM_NICKNAME = {
    # Atlantic
    "Boston Celtics": "Celtics",
    "Brooklyn Nets": "Nets",
    "New York Knicks": "Knicks",
    "Philadelphia 76ers": "76ers",
    "Toronto Raptors": "Raptors",

    # Central
    "Chicago Bulls": "Bulls",
    "Cleveland Cavaliers": "Cavaliers",
    "Detroit Pistons": "Pistons",
    "Indiana Pacers": "Pacers",
    "Milwaukee Bucks": "Bucks",

    # Southeast
    "Atlanta Hawks": "Hawks",
    "Charlotte Hornets": "Hornets",
    "Miami Heat": "Heat",
    "Orlando Magic": "Magic",
    "Washington Wizards": "Wizards",

    # Northwest
    "Denver Nuggets": "Nuggets",
    "Minnesota Timberwolves": "Timberwolves",
    "Oklahoma City Thunder": "Thunder",
    "Portland Trail Blazers": "Trail Blazers",
    "Utah Jazz": "Jazz",

    # Pacific
    "Golden State Warriors": "Warriors",
    "LA Clippers": "Clippers",             # variant
    "Los Angeles Clippers": "Clippers",
    "Los Angeles Lakers": "Lakers",
    "Phoenix Suns": "Suns",
    "Sacramento Kings": "Kings",

    # Southwest
    "Dallas Mavericks": "Mavericks",
    "Houston Rockets": "Rockets",
    "Memphis Grizzlies": "Grizzlies",
    "New Orleans Pelicans": "Pelicans",
    "San Antonio Spurs": "Spurs",
}

TEAM_ARENA = {
    # Atlantic
    "Boston Celtics": "TD Garden",
    "Brooklyn Nets": "Barclays Center",
    "New York Knicks": "Madison Square Garden",
    "Philadelphia 76ers": "Wells Fargo Center",
    "Toronto Raptors": "Scotiabank Arena",

    # Central
    "Chicago Bulls": "United Center",
    "Cleveland Cavaliers": "Rocket Mortgage FieldHouse",
    "Detroit Pistons": "Little Caesars Arena",
    "Indiana Pacers": "Gainbridge Fieldhouse",
    "Milwaukee Bucks": "Fiserv Forum",

    # Southeast
    "Atlanta Hawks": "State Farm Arena",
    "Charlotte Hornets": "Spectrum Center",
    "Miami Heat": "Kaseya Center",
    "Orlando Magic": "Kia Center",
    "Washington Wizards": "Capital One Arena",

    # Northwest
    "Denver Nuggets": "Ball Arena",
    "Minnesota Timberwolves": "Target Center",
    "Oklahoma City Thunder": "Paycom Center",
    "Portland Trail Blazers": "Moda Center",
    "Utah Jazz": "Delta Center",

    # Pacific
    "Golden State Warriors": "Chase Center",
    "Los Angeles Clippers": "Intuit Dome",
    "Los Angeles Lakers": "Crypto.com Arena",
    "Phoenix Suns": "Footprint Center",
    "Sacramento Kings": "Golden 1 Center",

    # Southwest
    "Dallas Mavericks": "American Airlines Center",
    "Houston Rockets": "Toyota Center",
    "Memphis Grizzlies": "FedExForum",
    "New Orleans Pelicans": "Smoothie King Center",
    "San Antonio Spurs": "Frost Bank Center",
}

TEAM_CITY = {
    # Atlantic
    "Boston Celtics": "Boston",
    "Brooklyn Nets": "Brooklyn",
    "New York Knicks": "New York",
    "Philadelphia 76ers": "Philadelphia",
    "Toronto Raptors": "Toronto",

    # Central
    "Chicago Bulls": "Chicago",
    "Cleveland Cavaliers": "Cleveland",
    "Detroit Pistons": "Detroit",
    "Indiana Pacers": "Indianapolis",
    "Milwaukee Bucks": "Milwaukee",

    # Southeast
    "Atlanta Hawks": "Atlanta",
    "Charlotte Hornets": "Charlotte",
    "Miami Heat": "Miami",
    "Orlando Magic": "Orlando",
    "Washington Wizards": "Washington",

    # Northwest
    "Denver Nuggets": "Denver",
    "Minnesota Timberwolves": "Minneapolis",
    "Oklahoma City Thunder": "Oklahoma City",
    "Portland Trail Blazers": "Portland",
    "Utah Jazz": "Salt Lake City",

    # Pacific
    "Golden State Warriors": "San Francisco",
    "Los Angeles Clippers": "Inglewood",
    "Los Angeles Lakers": "Los Angeles",
    "Phoenix Suns": "Phoenix",
    "Sacramento Kings": "Sacramento",

    # Southwest
    "Dallas Mavericks": "Dallas",
    "Houston Rockets": "Houston",
    "Memphis Grizzlies": "Memphis",
    "New Orleans Pelicans": "New Orleans",
    "San Antonio Spurs": "San Antonio",
}

TEAM_CODE = {
    # Atlantic
    "Boston Celtics": "BOS",
    "Brooklyn Nets": "BKN",
    "New York Knicks": "NYK",
    "Philadelphia 76ers": "PHI",
    "Toronto Raptors": "TOR",

    # Central
    "Chicago Bulls": "CHI",
    "Cleveland Cavaliers": "CLE",
    "Detroit Pistons": "DET",
    "Indiana Pacers": "IND",
    "Milwaukee Bucks": "MIL",

    # Southeast
    "Atlanta Hawks": "ATL",
    "Charlotte Hornets": "CHA",
    "Miami Heat": "MIA",
    "Orlando Magic": "ORL",
    "Washington Wizards": "WAS",

    # Northwest
    "Denver Nuggets": "DEN",
    "Minnesota Timberwolves": "MIN",
    "Oklahoma City Thunder": "OKC",
    "Portland Trail Blazers": "POR",
    "Utah Jazz": "UTA",

    # Pacific
    "Golden State Warriors": "GSW",
    "Los Angeles Clippers": "LAC",
    "Los Angeles Lakers": "LAL",
    "Phoenix Suns": "PHX",
    "Sacramento Kings": "SAC",

    # Southwest
    "Dallas Mavericks": "DAL",
    "Houston Rockets": "HOU",
    "Memphis Grizzlies": "MEM",
    "New Orleans Pelicans": "NOP",
    "San Antonio Spurs": "SAS",
}



# Lowercased lookup for robustness (handles minor case differences)
TEAM_NICKNAME_LC = {k.lower(): v for k, v in TEAM_NICKNAME.items()}
print(TEAM_NICKNAME_LC)


def compute_abbreviation(team_name: str) -> str:
    """
    Returns the preferred nickname (e.g., 'Hawks', 'Trail Blazers').
    Falls back to a simple heuristic if the team isn't in the map.
    """
    if not team_name:
        return ""

    key = team_name.strip().lower()
    if key in TEAM_NICKNAME_LC:
        return TEAM_NICKNAME_LC[key]

    # Heuristic fallback:
    # - If name contains common city + nickname, use everything after the first token.
    # - Otherwise, return the last word (e.g., "Bulls", "Lakers").
    parts = team_name.strip().split()
    if len(parts) >= 2:
        # special-case a few multiword nicknames if ever missed in the map
        tail = " ".join(parts[1:])
        if tail in ("Trail Blazers", "76ers"):  # keep as-is
            return tail
        return tail
    return parts[-1] if parts else ""

def add_abbreviations_to_teams(batch_size: int = 450, dry_run: bool = False):
    """
    Iterates all documents in 'teams' and sets the 'abbreviation' field
    based on the team name. Uses batched writes.
    """
    coll = db.collection("teams")
    docs = list(coll.stream())

    batch = db.batch()
    count_in_batch = 0
    updated = 0

    for doc in docs:
        data = doc.to_dict() or {}
        name = data.get("name") or data.get("team_name")  # support either field
        abbr = compute_abbreviation(name or "")

        if dry_run:
            print(f"[DRY RUN] {doc.id}: name='{name}' -> abbreviation='{abbr}'")
            continue

        batch.update(doc.reference, {"abbreviation": abbr})
        count_in_batch += 1
        updated += 1

        if count_in_batch >= batch_size:
            batch.commit()
            batch = db.batch()
            count_in_batch = 0

    if not dry_run and count_in_batch > 0:
        batch.commit()

    print(f"Teams processed: {len(docs)}  |  Abbreviations updated: {updated}")

# --- Run it ---
# Preview without writing:
# add_abbreviations_to_teams(dry_run=True)

# add_abbreviations_to_teams()

def add_item_to_teams(dict, item_name, dry_run = False):
    collection = db.collection("teams")
    docs = list(collection.stream())
    batch = db.batch()
    
    for doc in docs:
        data = doc.to_dict()
        name = data.get('name')
        if name in dict.keys():
            item = dict[name]
            if dry_run:
                print(f"[DRY RUN] {doc.id}: name='{name}' -> {item_name}='{item}'")
                continue
            batch.update(doc.reference, {item_name: item})
            
            if not dry_run:
                batch.commit()
            
# add_item_to_teams(TEAM_CODE, "code", dry_run=False)

def add_ot_prob_to_upcoming_game():
    collection = db.collection('games_schedule')
    docs = list(collection.stream())
    batch = db.batch()
    
    for doc in docs:
        data = doc.to_dict()
        predictions = data.get('predictions')
        
        prob = random.uniform(0.0, 49.9)
        batch.update(doc.reference, {f'predictions.overtimeProbability':prob})
        
    batch.commit()
    
# add_ot_prob_to_upcoming_game()

def save_2025_season():
    df = pd.read_json('csv/games.json')
    
    print(df)
    
save_2025_season()