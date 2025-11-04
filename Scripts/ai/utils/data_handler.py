import pandas as pd
import datetime as dt
import os

base_dir = os.path.dirname(__file__)
csv_path = os.path.join(base_dir, 'team_statistics.csv')
ids_path = os.path.join(base_dir, 'team_ids.csv')
games_path = os.path.join(base_dir, 'games.csv')

# Load the main file for the original statistics
df = pd.read_csv(csv_path)

# Get only games from 2016 and earlier
df = df.loc[df['gameDate'].astype(str).str[:4].astype('int') > 2015].copy()

team_ids = pd.read_csv(ids_path).set_index('Team')['ID']

# Match the team ids from the document to those in my db
def repair_team_id(df):
    for index, row in df.iterrows():
        home_team = f"{row['teamCity']} {row['teamName']}"
        away_team = f"{row['opponentTeamCity']} {row['opponentTeamName']}"
           
        home_team_id = team_ids.get(home_team)
        away_team_id = team_ids.get(away_team)
        
        df.loc[index, 'teamId'] = home_team_id
        df.loc[index, 'opponentTeamId'] = away_team_id
        
        df.drop(['gameId', 'teamName', 'teamCity', 'opponentTeamCity', 'opponentTeamName', ])
    
    df.to_csv('team_statistics.csv')

# Prepare final dataset
def prepare_dataset(df):
    # Prepare gameId for merge
    df["gameId"] = df["gameId"].astype(int)
    
    # Split into home and away teams
    home_df = df[df["home"] == 1].copy()
    away_df = df[df["home"] == 0].copy()
    
    # Add prefixes to each group
    home_df = home_df.add_prefix("home_")
    away_df = away_df.add_prefix("away_")
    
    # Merge both into one row per game
    merged = pd.merge(
        home_df,
        away_df,
        left_on="home_gameId",
        right_on="away_gameId"
    )
    
    # Rename columns
    merged.rename(columns={
        "home_gameId": "gameId",
        "home_gameDate": "gameDate"
    }, inplace=True)
    
    # Remove duplicate ID/date columns from away team
    merged.drop(columns=["away_gameId", "away_gameDate"], inplace=True)
    
    # Reorder columns for readability
    ordered_columns = [
        "gameId", "gameDate",
        "home_teamCity", "home_teamName", "home_teamId",
        "away_teamCity", "away_teamName", "away_teamId",
        "home_teamScore", "away_teamScore"
    ]
    
    # Add the rest of the columns that are not yet in the list
    for col in merged.columns:
        if col not in ordered_columns:
            ordered_columns.append(col)
    
    # Reorder columns
    merged = merged[ordered_columns]
    
    # Final clean
    drop_cols = [
        "home_Unnamed: 0", "away_Unnamed: 0",
        "home_opponentTeamCity", "home_opponentTeamName", "home_opponentTeamId",
        "away_opponentTeamCity", "away_opponentTeamName", "away_opponentTeamId",
        "home_home", "away_home",
        "home_opponentScore", "away_opponentScore",
        "home_seasonWins", "home_seasonLosses", "home_coachId",
        "away_seasonWins", "away_seasonLosses", "away_coachId",
        "home_teamCity", "home_teamName", "away_teamName", "away_teamCity"
    ]
    merged.drop(columns=[c for c in drop_cols if c in merged.columns], inplace=True)

    merged.to_csv("games.csv", index=False)
    return merged

# Function to retrieve the games dataset 
def get_games():
    df = pd.read_csv(games_path)
    return df