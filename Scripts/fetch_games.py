# fetch_games.py
import json
import time
import requests
from balldontlie import BalldontlieAPI
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone

API_KEY = "25ca20cb-da6a-4098-aafd-0d151974e12c"
BASE_URL = "https://api.balldontlie.io/v1/games"
SEASON = 2024

headers = {"Authorization": API_KEY}
params = {
    "seasons[]": SEASON,
    "per_page": 100,  # reduce requests (API typically caps at 100)
}

cred = credentials.Certificate("statistiq-5158d-firebase-adminsdk-fbsvc-51f4cb04e0.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

def get_with_retries(url, headers, params, max_retries=5):
    backoff = 1
    for attempt in range(1, max_retries + 1):
        resp = requests.get(url, headers=headers, params=params)
        # Success
        if resp.status_code == 200:
            return resp
        # Rate limited
        if resp.status_code == 429:
            retry_after = resp.headers.get("Retry-After")
            wait = int(retry_after) if retry_after and retry_after.isdigit() else backoff
        # Transient server errors
        elif 500 <= resp.status_code < 600:
            wait = backoff
        else:
            # Other errors: raise with details
            try:
                err = resp.json()
            except Exception:
                err = resp.text
            raise RuntimeError(f"Request failed ({resp.status_code}): {err}")

        time.sleep(wait)
        backoff = min(backoff * 2, 30)  # exponential backoff, capped
    raise RuntimeError(f"Gave up after {max_retries} retries.")

def fetch_all_games():
    all_games = []
    teams_dict = {}
    cursor = None
    page_num = 0
    
    teams_firebase = db.collection('teams')
    docs = list(teams_firebase.stream())
    batch = db.batch()
    
    for doc in docs:
        data = doc.to_dict()
        teams_dict[data['name'].split(' ')[-1]] = doc.id
        
    docs = (
        db.collection("games_played")
        .order_by("game_id", direction=firestore.Query.DESCENDING)
        .limit(1)
        .stream()
            )
    
    for doc in docs:
        new_game_id  = doc.to_dict()["game_id"]
        print(f"New game_id {new_game_id}")
        
    while True:
        if cursor is not None:
            params["cursor"] = cursor
        else:
            params.pop("cursor", None)

        resp = get_with_retries(BASE_URL, headers, params)
        payload = resp.json()

        data = payload.get("data", [])
        # print(f"Tohle jsou data {data}")
        
        for item in data:
            home_name = item['home_team']['full_name'].split(' ')[-1]
            away_name = item['visitor_team']['full_name'].split(' ')[-1]

            date = item['date']
            # dt = datetime.strptime(date, "%Y-%m-%d").replace(tzinfo=timezone.utc)
            game_date_str = f'{date} 00:00:00'
            print(f"game date str : {game_date_str}")
            
            id_home = teams_dict[home_name]
            id_away = teams_dict[away_name]

            pts_home = item['home_team_score']
            pts_away = item['visitor_team_score']
            
            wl_home = "W" if pts_home > pts_away else "L"
            wl_away = "L" if wl_home == "W" else "W"
            
            print(f"Correct id {pts_home} a result {wl_home}")
            print(f"Correct it {pts_away} a result {wl_away}")
            print(item)
            print(" ")
            
            insert_result = {
                "game_date": game_date_str,
                "pts_home": pts_home,
                "pts_away": pts_away,
                "team_id_away": id_away,
                "team_id_home": id_home,
                "wl_away": wl_away,
                "wl_home": wl_home,
            }
            
            print(insert_result)
            
            docs = (
                db.collection("games_played")
                .order_by("game_id", direction=firestore.Query.DESCENDING)
                .limit(1)
                .stream()
            )

            # for doc in docs:
            #     new_game_id  = doc.to_dict()["game_id"]
            #     print(f"New game_id {new_game_id}")
            print(f"Game id for that insert resul {new_game_id}")
            
            doc_ref = db.collection("games_played").document(str(new_game_id))
            batch.set(doc_ref, insert_result, merge=True)
            
            new_game_id += 1
        
        meta = payload.get("meta", {})
        all_games.extend(data)
        page_num += 1

        print(f"Fetched page {page_num}, +{len(data)} games (total {len(all_games)})")

        cursor = meta.get("next_cursor")
        if not cursor:
            break
        
    batch.commit()
    time.sleep(0.2)

    return all_games

def repair_teamids():
    col = db.collection('games_played')
    docs = col.stream()
    batch = db.batch()
    updated = 0
    in_batch = 0

    for doc in docs:
        d = doc.to_dict() or {}
        changes = {}

        for key in ('team_id_home', 'team_id_away'):
            team_id = d.get(key)
            if isinstance(team_id, str):
                changes[key] = int(team_id)
        
        if changes:
            batch.update(doc.reference, changes)
            updated += 1
            in_batch += 1
            
            if in_batch >= 450:
                batch.commit()
                batch = db.batch()
                in_batch = 0
                
    if in_batch:
        batch.commit()
        
    print(f"Updated {updated} documents.")

            
if __name__ == "__main__":
    repair_teamids()
    
    # with open("games.json", "w") as f:
    #     json.dump(games, f, indent=2)
    # print(f"✅ Saved {len(games)} games for season {SEASON} to games.json")
