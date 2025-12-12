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
from google.cloud import secretmanager
from openai import OpenAI

if not firebase_admin._apps:
    firebase_admin.initialize_app()

db = firestore.client()
BUCKET_NAME = "statistiq-models"

def get_openai_key():
    client = secretmanager.SecretManagerServiceClient()
    name = "projects/statistiq-5158d/secrets/openai_api_key/versions/latest"
    response = client.access_secret_version(name=name)
    return response.payload.data.decode("UTF-8")

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

        mapping[firebase_id] = {
            "name": team_name,
            "nba_id": nba_id
        }

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

FEATURE_MEDIANS = None

def get_feature_medians():
    global FEATURE_MEDIANS
    if FEATURE_MEDIANS is None:
        FEATURE_MEDIANS = load_from_gcs("data/feature_medians.pkl")
    return FEATURE_MEDIANS

def apply_training_imputation(base_features: dict) -> dict:
    medians = get_feature_medians()
    for k, median in medians.items():
        v = base_features.get(k)
        if v is None or pd.isna(v):
            base_features[k] = float(median)
        else:
            base_features[k] = float(v)
    return base_features

def build_winning_percentage_payload(df, home_id, away_id):
    df = df.sort_values("GAME_DATE").copy()

    # Home / Away slices
    home_df = df[df["TEAM_ID"] == home_id].copy()
    away_df = df[df["TEAM_ID"] == away_id].copy()

    # =========================
    # AVG POINTS (expanding, shift)
    # =========================
    home_avg_points = home_df["PTS"].shift(1).expanding().mean().iloc[-1]
    away_avg_points = away_df["PTS"].shift(1).expanding().mean().iloc[-1]

    # =========================
    # LAST 5 WIN %
    # =========================
    home_last_5_win_percentage = (
        (home_df["WL"] == "W").astype(int).shift(1).rolling(5, min_periods=1).mean().iloc[-1]
    )
    away_last_5_win_percentage = (
        (away_df["WL"] == "W").astype(int).shift(1).rolling(5, min_periods=1).mean().iloc[-1]
    )

    # =========================
    # POSSESSIONS
    # =========================
    home_poss = home_df["FGA"] + 0.44 * home_df["FTA"] + home_df["TOV"]
    away_poss = away_df["FGA"] + 0.44 * away_df["FTA"] + away_df["TOV"]

    # =========================
    # OFF EFF L10
    # =========================
    home_off_eff = home_df["PTS"] / home_poss.replace(0, pd.NA)
    away_off_eff = away_df["PTS"] / away_poss.replace(0, pd.NA)

    home_off_eff_L10 = home_off_eff.shift(1).rolling(10, min_periods=1).mean().iloc[-1]
    away_off_eff_L10 = away_off_eff.shift(1).rolling(10, min_periods=1).mean().iloc[-1]

    # =========================
    # DEF EFF (points allowed, L5)
    # =========================
    home_def_efficiency = (
        away_df["PTS"].shift(1).rolling(5, min_periods=1).mean().iloc[-1]
    )

    # =========================
    # TRUE SHOOTING L5
    # =========================
    home_TS = home_df["PTS"] / (2 * (home_df["FGA"] + 0.44 * home_df["FTA"])).replace(0, pd.NA)
    away_TS = away_df["PTS"] / (2 * (away_df["FGA"] + 0.44 * away_df["FTA"])).replace(0, pd.NA)

    home_TS_L5 = home_TS.shift(1).rolling(5, min_periods=1).mean().iloc[-1]
    away_TS_L5 = away_TS.shift(1).rolling(5, min_periods=1).mean().iloc[-1]

    # =========================
    # eFG% L10
    # =========================
    home_eFG = (home_df["FGM"] + 0.5 * home_df["FG3M"]) / home_df["FGA"].replace(0, pd.NA)
    away_eFG = (away_df["FGM"] + 0.5 * away_df["FG3M"]) / away_df["FGA"].replace(0, pd.NA)

    home_eFG_L10 = home_eFG.shift(1).rolling(10, min_periods=1).mean().iloc[-1]
    away_eFG_L10 = away_eFG.shift(1).rolling(10, min_periods=1).mean().iloc[-1]

    # =========================
    # TOV RATE L5
    # =========================
    home_tov_rate_L5 = (home_df["TOV"] / home_poss).shift(1).rolling(5, min_periods=1).mean().iloc[-1]
    away_tov_rate_L5 = (away_df["TOV"] / away_poss).shift(1).rolling(5, min_periods=1).mean().iloc[-1]

    # =========================
    # HEAD TO HEAD AVG POINTS
    # =========================
    away_abbrev = away_df["TEAM_ABBREVIATION"].iloc[-1]
    h2h = home_df[home_df["MATCHUP"].str.contains(away_abbrev, na=False)]

    home_head_to_head_avg_points = (
        h2h["PTS"].shift(1).expanding().mean().iloc[-1]
        if not h2h.empty
        else home_avg_points
    )
    
    home_abbrev = home_df["TEAM_ABBREVIATION"].iloc[-1]
    h2h_away = away_df[away_df["MATCHUP"].str.contains(home_abbrev, na=False)]

    away_head_to_head_avg_points = (
        h2h_away["PTS"].shift(1).expanding().mean().iloc[-1]
        if not h2h_away.empty
        else away_avg_points
    )
    
    home_season_win_percentage = (
    (home_df["WL"] == "W").astype(int).shift(1).expanding().mean().iloc[-1]
    )
    away_season_win_percentage = (
        (away_df["WL"] == "W").astype(int).shift(1).expanding().mean().iloc[-1]
    )


    # =========================
    # ELO (recomputed inline, same logic)
    # =========================

    game_df = df.copy()
    game_df = game_df.sort_values("GAME_DATE")

    home_games = game_df[game_df["MATCHUP"].str.contains("vs.")].copy()
    away_games = game_df[game_df["MATCHUP"].str.contains("@")].copy()

    home_games["game_id"] = home_games["GAME_ID"]
    away_games["game_id"] = away_games["GAME_ID"]

    games = home_games.merge(
        away_games,
        on="game_id",
        suffixes=("_home", "_away")
    )

    games = games.rename(columns={
        "TEAM_ID_home": "home_teamId",
        "TEAM_ID_away": "away_teamId",
        "WL_home": "home_WL",
        "GAME_DATE_home": "gameDate"
    })

    games["home_win"] = (games["home_WL"] == "W").astype(int)
    games = games.sort_values("gameDate").reset_index(drop=True)

    base_elo = 1500
    k = 20
    elo = {}

    games["home_elo"] = 0.0
    games["away_elo"] = 0.0

    for i, row in games.iterrows():
        h = row["home_teamId"]
        a = row["away_teamId"]

        elo.setdefault(h, base_elo)
        elo.setdefault(a, base_elo)

        # PRE-GAME ELO (important)
        games.at[i, "home_elo"] = elo[h]
        games.at[i, "away_elo"] = elo[a]

        expected_home = 1 / (1 + 10 ** ((elo[a] - elo[h]) / 400))
        actual_home = row["home_win"]

        elo[h] += k * (actual_home - expected_home)
        elo[a] -= k * (actual_home - expected_home)
    
    home_elo = elo.get(home_id, base_elo)
    away_elo = elo.get(away_id, base_elo)

    elo_diff = home_elo - away_elo

    # =========================
    # RETURN BASE FEATURES
    # =========================
    return {
        "elo_diff": elo_diff,
        "home_off_eff_L10": home_off_eff_L10,
        "away_off_eff_L10": away_off_eff_L10,
        "home_def_efficiency": home_def_efficiency,
        "home_TS_L5": home_TS_L5,
        "home_last_5_win_percentage": home_last_5_win_percentage,
        "away_TS_L5": away_TS_L5,
        "home_tov_rate_L5": home_tov_rate_L5,
        "home_eFG_L10": home_eFG_L10,
        "home_avg_points": home_avg_points,
        "away_eFG_L10": away_eFG_L10,
        "away_tov_rate_L5": away_tov_rate_L5,
        "home_head_to_head_avg_points": home_head_to_head_avg_points,
    }
    
def get_recent_form_text(df, team_id, n=5):
    games = (
        df[df["TEAM_ID"] == team_id]
        .sort_values("GAME_DATE")
        .tail(n)
    )

    if games.empty:
        return None

    wins = (games["WL"] == "W").sum()
    losses = (games["WL"] == "L").sum()

    if wins == n:
        return f"are riding a {n}-game winning streak"
    if losses == n:
        return f"have dropped their last {n} games"

    if wins >= n - 1:
        return f"have been in strong form recently ({wins}-{losses} in their last {n})"
    if wins <= 1:
        return f"have struggled lately ({wins}-{losses} in their last {n})"

    return f"have gone {wins}-{losses} over their last {n} games"

def get_last_game_summary(df, team_id):
    games = (
        df[df["TEAM_ID"] == team_id]
        .sort_values("GAME_DATE")
    )

    if games.empty:
        return None

    last = games.iloc[-1]

    opponent = last["MATCHUP"].replace("vs.", "").replace("@", "").strip()
    pts = int(last["PTS"])
    wl = last["WL"]

    if wl == "W":
        return f"coming off a {pts}-point win against {opponent}"
    else:
        return f"after a {pts}-point loss to {opponent}"

def classify_match_context(win_home_pct, margin, ot_pct):
    # Favorite strength
    if win_home_pct >= 72:
        favorite = "clear"
    elif win_home_pct >= 60:
        favorite = "moderate"
    elif win_home_pct >= 52:
        favorite = "slight"
    else:
        favorite = "uncertain"

    # Game type
    if abs(margin) <= 3:
        game_type = "very tight"
    elif abs(margin) <= 7:
        game_type = "competitive"
    else:
        game_type = "potentially one-sided"

    # OT likelihood
    if ot_pct >= 18:
        ot_note = "with a real chance of overtime"
    elif ot_pct >= 10:
        ot_note = "where overtime is not out of the question"
    else:
        ot_note = "unlikely to require overtime"

    return favorite, game_type, ot_note

def generate_prediction_summary(
    api_key,
    home_name,
    away_name,
    win_home,
    win_away,
    margin,
    home_min,
    home_max,
    away_min,
    away_max,
    ot_prob,
    home_form=None,
    away_form=None,
    home_last_game=None,
    away_last_game=None,
):
    client = OpenAI(api_key=api_key)

    favorite, game_type, ot_note = classify_match_context(
        win_home, margin, ot_prob
    )

    prompt = f"""
    Write a short, natural 2–3 sentence basketball match preview.

    Do NOT mention exact percentages or numeric probabilities.
    Do NOT mention AI, models, or predictions by name.
    Do NOT mention specific timing such as "tonight", "this evening", or dates.

    The preview should clearly reflect a predictive outlook, not a recap.

    Write in a relaxed, fan-friendly sports analyst tone.

    This matchup features {home_name} hosting {away_name}.

    Prediction outlook:
    {home_name} are projected to enter the matchup as a {favorite} favorite on their home floor, with the overall outlook pointing to a {game_type} contest {ot_note}.

    Recent context:
    {home_name} {home_form or "have shown mixed recent form"}, while {away_name} {away_form or "have experienced an inconsistent stretch"}.

    Latest games:
    {home_name} are {home_last_game or "looking to build momentum"}, while {away_name} are {away_last_game or "aiming to respond after their previous outing"}.

    Focus on form, momentum, home-court impact, and what the outlook suggests.
    Keep the language natural and conversational.
    """


    result = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=120,
        temperature=0.85,
    )

    return result.choices[0].message.content.strip()

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
        home_id = team_mapping[home_firebase_id]["nba_id"]
        away_id = team_mapping[away_firebase_id]["nba_id"]

        home_form = get_recent_form_text(season_df, home_id, n=5)
        away_form = get_recent_form_text(season_df, away_id, n=5)

        home_last_game = get_last_game_summary(season_df, home_id)
        away_last_game = get_last_game_summary(season_df, away_id)
        
        home_record = get_team_record(season_df, home_id)
        away_record = get_team_record(season_df, away_id)

        # features from NBA API
        base_features = build_feature_payload(season_df, home_id, away_id)
        
        build_winning_percentage_features = build_winning_percentage_payload(season_df, home_id, away_id)
        build_winning_percentage_features = apply_training_imputation(build_winning_percentage_features)
        
        # build model inputs
        features_winprob = pd.DataFrame([{
            k: build_winning_percentage_features[k] for k in [
                'elo_diff',
                'home_off_eff_L10',
                'away_off_eff_L10', 
                'home_def_efficiency',
                'home_TS_L5',
                'home_last_5_win_percentage',
                'away_TS_L5',
                'home_tov_rate_L5',
                'home_eFG_L10',
                'home_avg_points',
                'away_eFG_L10',
                'away_tov_rate_L5',
                'home_head_to_head_avg_points'
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
        win_prob = models["win_prob"].predict_proba(features_winprob)[0, 1]

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
        
        fav_team_id = home_firebase_id if margin >= 0 else away_firebase_id
        
        api_key = get_openai_key()

        # Required names
        home_name = team_mapping[home_firebase_id]["name"]
        away_name = team_mapping[away_firebase_id]["name"]

        # Convert predictions to percentages
        win_home_pct = win_prob * 100
        win_away_pct = (1 - win_prob) * 100
        ot_pct = ot_prob * 100

        prediction_summary = generate_prediction_summary(
            api_key,
            home_name,
            away_name,
            win_home_pct,
            win_away_pct,
            margin,
            home_pts - 10,
            home_pts + 10,
            away_pts - 10,
            away_pts + 10,
            ot_pct,
            home_form=home_form,
            away_form=away_form,
            home_last_game=home_last_game,
            away_last_game=away_last_game,
        )


        # form_summary = generate_form_summary(
        #     api_key,
        #     home_name, away_name,
        #     home_record, away_record
        # )

        # save back to Firestore
        
        db.collection("games_schedule").document(game_id).update({
            "predictions": {
                "winProbability": {"home": float(win_prob), "away": float(1 - win_prob)},
                "pointsRange": {
                    "home": {"min": float(home_pts - 10), "max": float(home_pts + 10)},
                    "away": {"min": float(away_pts - 10), "max": float(away_pts + 10)},
                },
                "expectedMargin": {
                    "teamId": fav_team_id,
                    "value": float(abs(margin))
                },
                "overtimeProbability": float(ot_prob),
            },
            "summary": {
                "prediction": prediction_summary
                # "currentForm": form_summary
            },
            "home_record": home_record,
            "away_record": away_record,
            "updatedAt": firestore.SERVER_TIMESTAMP
        })

        print(f"Updated predictions for game {game_id}")

    return ("Predictions updated successfully!", 200)
