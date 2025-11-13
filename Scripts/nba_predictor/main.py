import functions_framework
import pandas as pd
import joblib
import tempfile
from google.cloud import storage
from firebase_admin import firestore, initialize_app
import firebase_admin
from datetime import datetime, timedelta

# === Initialize Firebase ===
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

@functions_framework.http
def predict_games(request):
    """Predict outcomes for upcoming games and store them in Firestore."""
    today = datetime.utcnow()
    two_days_ahead = today + timedelta(days=2)

    games = db.collection("games_schedule") \
        .where("startTime", ">=", today) \
        .where("startTime", "<=", two_days_ahead) \
        .stream()

    for doc in games:
        game = doc.to_dict()
        game_id = str(game["gameId"])
        
        updated_at = game.get("updatedAt")
        if updated_at:
            last_update = updated_at.replace(tzinfo=None)
            if (datetime.utcnow() - last_update).total_seconds() < 86400:
                print(f"⏩ Skipping {game_id}: predictions updated recently.")
                continue


        # Build placeholder features (later real fom NBA API)
        # Build placeholder features (later real from NBA API)
        base_features = {
            "home_avg_points": 112,
            "away_avg_points": 107,
            "home_head_to_head_avg_points": 109,
            "away_head_to_head_avg_points": 104,
            "home_last_5_win_percentage": 0.6,
            "away_last_5_win_percentage": 0.4,
            "home_season_win_percentage": 0.55,
            "away_season_win_percentage": 0.50,
            "home_advantage": 1,
            "points_avg_diff": 112 - 107,
            "winrate_diff": 0.55 - 0.50
        }

        # Create subsets for each model (to match training features)
        features_winprob = pd.DataFrame([{k: base_features[k] for k in [
            'home_avg_points',
            'away_avg_points',
            'home_head_to_head_avg_points',
            'away_head_to_head_avg_points',
            'home_last_5_win_percentage',
            'away_last_5_win_percentage',
            'home_season_win_percentage',
            'away_season_win_percentage'
        ]}])

        features_points = pd.DataFrame([{k: base_features[k] for k in [
            'home_avg_points',
            'away_avg_points',
            'home_head_to_head_avg_points',
            'away_head_to_head_avg_points',
            'home_last_5_win_percentage',
            'away_last_5_win_percentage',
            'home_advantage'
        ]}])

        features_margin = pd.DataFrame([{k: base_features[k] for k in [
            'home_avg_points',
            'away_avg_points',
            'points_avg_diff',
            'winrate_diff',
            'home_head_to_head_avg_points',
            'away_head_to_head_avg_points',
            'home_last_5_win_percentage',
            'away_last_5_win_percentage',
            'home_season_win_percentage',
            'away_season_win_percentage',
            'home_advantage'
        ]}])

        features_ot = pd.DataFrame([{k: base_features[k] for k in [
            'home_avg_points',
            'away_avg_points',
            'home_head_to_head_avg_points',
            'away_head_to_head_avg_points',
            'home_last_5_win_percentage',
            'away_last_5_win_percentage',
            'home_advantage'
        ]}])


        X_win = scalers["win_prob"].transform(features_winprob)
        win_prob = models["win_prob"].predict_proba(X_win)[0, 1]

        X_pts = scalers["points"].transform(features_points)
        home_pts = models["home_points"].predict(X_pts)[0]
        away_pts = models["away_points"].predict(X_pts)[0]

        X_margin = scalers["margin"].transform(features_margin)
        margin = models["margin"].predict(X_margin)[0]

        X_ot = scalers["ot"].transform(features_ot)
        ot_prob = models["ot"].predict_proba(X_ot)[0, 1]


        db.collection("games_schedule").document(game_id).update({
            "predictions": {
                "winProbability": {"home": float(win_prob), "away": float(1 - win_prob)},
                "pointsRange": {
                    "home": {"min": home_pts - 10, "max": home_pts + 10},
                    "away": {"min": away_pts - 10, "max": away_pts + 10}
                },
                "expectedMargin": float(margin),
                "overtimeProbability": float(ot_prob)
            },
            "updatedAt": firestore.SERVER_TIMESTAMP
        })

    return "Predictions updated successfully!", 200
