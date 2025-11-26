import functions_framework
import pandas as pd
import joblib
import tempfile
from google.cloud import storage
from firebase_admin import firestore, initialize_app
import firebase_admin
from datetime import datetime, timedelta
from nba_api.stats.endpoints import leaguegamefinder
from nba_api.stats.static import teams as nba_teams_static

if not firebase_admin._apps:
    firebase_admin.initialize_app()

db = firestore.client()
BUCKET_NAME = "statistiq-models"

def load_from_gcs(filename):
    client = storage.Client()
    bucket = client.bucket(BUCKET_NAME)
    blob = bucket.blob(filename)
    tmp = tempfile.NamedTemporaryFile(delete=False)
    blob.download_to_filename(tmp.name)
    return joblib.load(tmp.name)

models = {
    "win_prob": load_from_gcs("models/win_probability_model.pkl"),
    "home_points": load_from_gcs("models/home_points_model.pkl"),
    "away_points": load_from_gcs("models/away_points_model.pkl"),
    "margin": load_from_gcs("models/expected_margin_model.pkl"),
    "ot": load_from_gcs("models/overtime_model_gb.pkl"),
}

scalers = {
    "win_prob": load_from_gcs("scalers/win_probability_scaler.pkl"),
    "points": load_from_gcs("scalers/points_scaler.pkl"),
    "ot": load_from_gcs("scalers/overtime_scaler.pkl"),
    "margin": load_from_gcs("scalers/expected_margin_scaler.pkl")
}

TEAM_MAPPING = None #cache

def load_team_mapping():
    """
    Loads Firebase team IDs from GCS file data/team_ids.csv
    and maps them to NBA official TEAM_ID using TEAM_NAME.
    """
    client = storage.Client()
    bucket = client.bucket(BUCKET_NAME)
    blob = bucket.blob("data/team_ids.csv")

    tmp = tempfile.NamedTemporaryFile(delete=False)
    blob.download_to_filename(tmp.name)

    df = pd.read_csv(tmp.name)  # columns: Team, ID
    df["Team"] = df["Team"].str.strip()

    # NBA teams metadata
    nba_list = nba_teams_static.get_teams()
    nba_by_name = {t["full_name"]: t["id"] for t in nba_list}

    mapping = {}
    for _, row in df.iterrows():
        team_name = row["Team"]
        firebase_id = int(row["ID"])
        nba_id = nba_by_name.get(team_name)

        if nba_id is None:
            print(f"WARNING: Team '{team_name}' not found in nba_api.")
            continue

        mapping[firebase_id] = nba_id

    print(f"Loaded team mapping: {len(mapping)} teams.")
    return mapping

def get_team_mapping():
    global TEAM_MAPPING
    if TEAM_MAPPING is None:
        TEAM_MAPPING = load_team_mapping()
    return TEAM_MAPPING

SEASON_STR = "2025-26"
SEASON_DF = None  # cache

def load_season_df(season: str = SEASON_STR):
    print("Downloading NBA game logs for season:", season)
    df = leaguegamefinder.LeagueGameFinder(
        season_nullable=season,
        season_type_nullable="Regular Season",
    ).get_data_frames()[0]

    df["GAME_DATE"] = pd.to_datetime(df["GAME_DATE"])
    return df[df["GAME_DATE"] < datetime.utcnow()]  # only past games


def get_season_df():
    global SEASON_DF
    if SEASON_DF is None:
        SEASON_DF = load_season_df(SEASON_STR)
    return SEASON_DF

def get_team_record(df, team_id):
    if "SEASON_TYPE" in df.columns:
        df_regular = df[df["SEASON_TYPE"] == "Regular Season"]
    else:
        df_regular = df
    
    team_games = df_regular[df_regular["TEAM_ID"] == team_id]

    if team_games.empty:
        return {"wins": 0, "losses": 0, "games": 0}

    wins = (team_games["WL"] == "W").sum()
    losses = (team_games["WL"] == "L").sum()
    total = wins + losses

    return {
        "wins": int(wins),
        "losses": int(losses),
        "games": int(total)
    }


def compute_team_features(df, team_id, opponent_id=None):
    team_games = df[df["TEAM_ID"] == team_id]
    if team_games.empty:
        print(f"No games for team {team_id}, using defaults.")
        return {
            "avg_points": 150.0,
            "season_win_pct": 0.5,
            "last5_win_pct": 0.5,
            "h2h_avg_points": 110.0,
        }

    avg_points = team_games["PTS"].mean()
    season_win_pct = (team_games["WL"] == "W").mean()

    last5 = team_games.sort_values("GAME_DATE").tail(5)
    last5_win_pct = (last5["WL"] == "W").mean()

    # Simple H2H: use ABBREVIATION
    if opponent_id is not None:
        opp_games = df[df["TEAM_ID"] == opponent_id]
        opp_abbrevs = opp_games["TEAM_ABBREVIATION"].unique()
        h2h = (
            team_games[team_games["MATCHUP"].str.contains(opp_abbrevs[0])]
            if len(opp_abbrevs)
            else pd.DataFrame()
        )
        h2h_avg_points = h2h["PTS"].mean() if not h2h.empty else avg_points
    else:
        h2h_avg_points = avg_points

    return {
        "avg_points": float(avg_points),
        "season_win_pct": float(season_win_pct),
        "last5_win_pct": float(last5_win_pct),
        "h2h_avg_points": float(h2h_avg_points),
    }


def build_feature_payload(df, home_id, away_id):
    home = compute_team_features(df, home_id, away_id)
    away = compute_team_features(df, away_id, home_id)

    return {
        "home_avg_points": home["avg_points"],
        "away_avg_points": away["avg_points"],
        "home_head_to_head_avg_points": home["h2h_avg_points"],
        "away_head_to_head_avg_points": away["h2h_avg_points"],
        "home_last_5_win_percentage": home["last5_win_pct"],
        "away_last_5_win_percentage": away["last5_win_pct"],
        "home_season_win_percentage": home["season_win_pct"],
        "away_season_win_percentage": away["season_win_pct"],
        "home_advantage": 1,
        "points_avg_diff": home["avg_points"] - away["avg_points"],
        "winrate_diff": home["season_win_pct"] - away["season_win_pct"],
    }

@functions_framework.http
def predict_games(request):
    today = datetime.utcnow()
    two_days_ahead = today + timedelta(days=2)

    season_df = get_season_df()
    team_mapping = get_team_mapping()

    games = (
        db.collection("games_schedule")
        .where("startTime", ">=", today)
        .where("startTime", "<=", two_days_ahead)
        .stream()
    )

    for doc in games:
        game = doc.to_dict()
        game_id = str(game["gameId"])

        # prevent repeated updates within 24h
        updated_at = game.get("updatedAt")
        if updated_at:
            last_update = updated_at.replace(tzinfo=None)
            if (datetime.utcnow() - last_update).total_seconds() < 86400:
                print(f"Skipping {game_id}: updated recently")
                continue

        try:
            home_firebase_id = int(game["teams"]["homeId"])
            away_firebase_id = int(game["teams"]["awayId"])
        except Exception:
            print(f"Invalid team data in game {game_id}, skipping.")
            continue

        if home_firebase_id not in team_mapping or away_firebase_id not in team_mapping:
            print(f"Missing mapping for teams in game {game_id}, skipping.")
            continue

        # convert to NBA TEAM_ID
        home_id = team_mapping[home_firebase_id]
        away_id = team_mapping[away_firebase_id]
        
        home_record = get_team_record(season_df, home_id)
        away_record = get_team_record(season_df, away_id)

        # features from NBA API
        base_features = build_feature_payload(season_df, home_id, away_id)

        # build model inputs
        features_winprob = pd.DataFrame([{
            k: base_features[k] for k in [
                "home_avg_points",
                "away_avg_points",
                "home_head_to_head_avg_points",
                "away_head_to_head_avg_points",
                "home_last_5_win_percentage",
                "away_last_5_win_percentage",
                "home_season_win_percentage",
                "away_season_win_percentage",
            ]
        }])

        features_points = pd.DataFrame([{
            k: base_features[k] for k in [
                "home_avg_points",
                "away_avg_points",
                "home_head_to_head_avg_points",
                "away_head_to_head_avg_points",
                "home_last_5_win_percentage",
                "away_last_5_win_percentage",
                "home_advantage",
            ]
        }])

        features_margin = pd.DataFrame([{
            k: base_features[k] for k in [
                "home_avg_points",
                "away_avg_points",
                "points_avg_diff",
                "winrate_diff",
                "home_head_to_head_avg_points",
                "away_head_to_head_avg_points",
                "home_last_5_win_percentage",
                "away_last_5_win_percentage",
                "home_season_win_percentage",
                "away_season_win_percentage",
                "home_advantage",
            ]
        }])

        features_ot = pd.DataFrame([{
            k: base_features[k] for k in [
                "home_avg_points",
                "away_avg_points",
                "home_head_to_head_avg_points",
                "away_head_to_head_avg_points",
                "home_last_5_win_percentage",
                "away_last_5_win_percentage",
                "home_advantage",
            ]
        }])

        # predictions
        win_prob = models["win_prob"].predict_proba(
            scalers["win_prob"].transform(features_winprob)
        )[0, 1]

        home_pts = models["home_points"].predict(
            scalers["points"].transform(features_points)
        )[0]

        away_pts = models["away_points"].predict(
            scalers["points"].transform(features_points)
        )[0]

        margin = models["margin"].predict(
            scalers["margin"].transform(features_margin)
        )[0]

        ot_prob = models["ot"].predict_proba(
            scalers["ot"].transform(features_ot)
        )[0, 1]

        # save back to Firestore
        db.collection("games_schedule").document(game_id).update({
            "predictions": {
                "winProbability": {"home": float(win_prob), "away": float(1 - win_prob)},
                "pointsRange": {
                    "home": {"min": float(home_pts - 10), "max": float(home_pts + 10)},
                    "away": {"min": float(away_pts - 10), "max": float(away_pts + 10)},
                },
                "expectedMargin": float(abs(margin)),
                "overtimeProbability": float(ot_prob),
            },
            "home_record": home_record,
            "away_record": away_record,
            "updatedAt": firestore.SERVER_TIMESTAMP
        })

        print(f"Updated predictions for game {game_id}")

    return ("Predictions updated successfully!", 200)
