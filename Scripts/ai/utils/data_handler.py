"""
This module handles data preparation and transformation for team and game statistics.

It loads CSV files containing team and game data, cleans and merges them,
and produces structured datasets for model training or analysis.
"""

import pandas as pd
import datetime as dt
import os

utils_dir = os.path.dirname(__file__)

ai_dir = os.path.dirname(utils_dir)
scripts_dir = os.path.dirname(ai_dir)
data_dir = os.path.join(ai_dir, 'data')
basketball_reference_dir = os.path.join(data_dir, 'basketball_reference')

csv_path = os.path.join(data_dir, 'team_statistics.csv')
ids_path = os.path.join(data_dir, 'team_ids.csv')
games_path = os.path.join(data_dir, 'games.csv')

print(basketball_reference_dir)

# Load the main file for the original statistics
df = pd.read_csv(csv_path)

# Get only games from 2016 and earlier
df = df.loc[df['gameDate'].astype(str).str[:4].astype('int') > 2015].copy()

team_ids = pd.read_csv(ids_path).set_index('Team')['ID']

# Match the team ids from the document to those in my db
def repair_team_id(df):
    for index, row in df.iterrows():
        home_team = f'{row['teamCity']} {row['teamName']}'
        away_team = f'{row['opponentTeamCity']} {row['opponentTeamName']}'
           
        home_team_id = team_ids.get(home_team)
        away_team_id = team_ids.get(away_team)
        
        df.loc[index, 'teamId'] = home_team_id
        df.loc[index, 'opponentTeamId'] = away_team_id
        
        df.drop(['gameId', 'teamName', 'teamCity', 'opponentTeamCity', 'opponentTeamName', ])
    
    df.to_csv('team_statistics.csv')

# Append overtime data do the dataset
def append_overtime_data():    
    team_stats_df = pd.read_csv(csv_path)
    
    team_stats_df['onlyDate'] = pd.to_datetime(
            team_stats_df['gameDate'], 
            format='mixed',
            errors='coerce', 
            utc=True
        ).dt.date

    team_stats_df['visitor_team'] = team_stats_df['opponentTeamCity'].str.strip() + ' ' + team_stats_df['opponentTeamName'].str.strip()
    team_stats_df['home_team'] = team_stats_df['teamCity'].str.strip() + ' ' + team_stats_df['teamName'].str.strip()
    
    team_stats_df['overtime'] = None
    
    for dir_name in os.listdir(basketball_reference_dir):
        if dir_name == '.DS_Store':
            continue
        dir_path = os.path.join(basketball_reference_dir, dir_name)
        for season in os.listdir(dir_path):
            month_path = os.path.join(dir_path, season)
            try:
                dfs = pd.read_html(month_path)
                df = dfs[0]
                
                # df.rename(columns={df.columns[7]: 'overtime'}, inplace=True)
                            
                df['gameDate'] = df['Date'].astype(str) + ' ' + df['Start (ET)'].astype(str)
                
                df['gameDate'] = (
                    df['gameDate']
                    .str.replace(r'(?<=\d)([ap])$', r'\1m', regex=True)
                )
                df['gameDate'] = pd.to_datetime(
                    df['gameDate'],
                    format='%a, %b %d, %Y %I:%M%p',
                    errors='coerce'
                ).dt.date
                
                df['Visitor/Neutral'] = df['Visitor/Neutral'].astype(str).str.strip()
                df['Home/Neutral'] = df['Home/Neutral'].astype(str).str.strip()
                                        
                merged = pd.merge(
                    team_stats_df,
                    df[['gameDate', 'Visitor/Neutral', 'Home/Neutral', 'Unnamed: 7']],
                    left_on=['onlyDate', 'visitor_team', 'home_team'],
                    right_on=['gameDate', 'Visitor/Neutral', 'Home/Neutral'],
                    how='left'
                )
                
                team_stats_df['overtime'].update(merged['Unnamed: 7'])
                
            except Exception as e:
                print(f'\nError while processing file: {month_path}')
                print(f'{type(e).__name__}: {e}')
                try:
                    print(f'Columns found: {list(df.columns)}')
                except Exception:
                    print('No columns')
                    
    team_stats_df['overtime'] = team_stats_df['overtime'].notna()
    team_stats_df.to_csv('test.csv', index=False)
    return team_stats_df


# Prepare final dataset
def prepare_dataset(df):
    # Prepare gameId for merge
    df['gameId'] = df['gameId'].astype(int)
    
    # df['gameDate'] = pd.to_datetime(df['gameDate'], errors='coerce')
    
    # Split into home and away teams
    home_df = df[df['home'] == 1].copy()
    away_df = df[df['home'] == 0].copy()
    
    # Add prefixes to each group
    home_df = home_df.add_prefix('home_')
    away_df = away_df.add_prefix('away_')
    
    # Merge both into one row per game
    merged = pd.merge(
        home_df,
        away_df,
        left_on='home_gameId',
        right_on='away_gameId'
    )
    
    if 'home_overtime' in merged.columns or 'away_overtime' in merged.columns:
        merged['overtime'] = (
            merged.get('home_overtime', False).fillna(False).astype(bool) |
            merged.get('away_overtime', False).fillna(False).astype(bool)
        )
    else:
        merged['overtime'] = False
    
    if 'home_overtime' in merged.columns:
        merged['overtime'] = merged['home_overtime'].combine_first(
            merged.get('away_overtime')
        )
    elif 'away_overtime' in merged.columns:
        merged['overtime'] = merged['away_overtime']
    else:
        merged['overtime'] = None
            
    # Rename columns
    merged.rename(columns={
        'home_gameId': 'gameId',
        'home_gameDate': 'gameDate'
    }, inplace=True)
    
    # Remove duplicate ID/date columns from away team
    merged.drop(columns=['away_gameId', 'away_gameDate'], inplace=True)
    
    # Reorder columns for readability
    ordered_columns = [
        'gameId', 'gameDate',
        'home_teamCity', 'home_teamName', 'home_teamId',
        'away_teamCity', 'away_teamName', 'away_teamId',
        'home_teamScore', 'away_teamScore', 'overtime'
    ]
    
    # Add the rest of the columns that are not yet in the list
    for col in merged.columns:
        if col not in ordered_columns:
            ordered_columns.append(col)
    
    # Reorder columns
    merged = merged[ordered_columns]
    
    # Final clean
    drop_cols = [
        'home_Unnamed: 0', 'away_Unnamed: 0',
        'home_opponentTeamCity', 'home_opponentTeamName', 'home_opponentTeamId',
        'away_opponentTeamCity', 'away_opponentTeamName', 'away_opponentTeamId',
        'home_home', 'away_home',
        'home_opponentScore', 'away_opponentScore',
        'home_seasonWins', 'home_seasonLosses', 'home_coachId',
        'away_seasonWins', 'away_seasonLosses', 'away_coachId',
        'home_teamCity', 'home_teamName', 'away_teamName', 'away_teamCity', 'away_overtime',
        'away_home_team', 'away_visitor_team', 'away_onlyDate', 'home_overtime', 'home_home_team',
        'home_onlyDate', 'home_visitor_team'
    ]
    merged.drop(columns=[c for c in drop_cols if c in merged.columns], inplace=True)

    merged.to_csv('games.csv', index=False)
    return merged

# Function to retrieve the games dataset 
def get_games():
    df = pd.read_csv(games_path)
    return df

# Compute the head to head for data preprocessing
def compute_head_to_head_avg(row, df):
    h, a, date = row['home_teamId'], row['away_teamId'], row['gameDate']
    prev = df[
        (((df['home_teamId'] == h) & (df['away_teamId'] == a)) |
         ((df['home_teamId'] == a) & (df['away_teamId'] == h))) &
        (df['gameDate'] < date)
    ]
    if prev.empty:
        return pd.Series([None, None])
    home_pts = prev[prev['home_teamId'] == h]['home_teamScore'].mean()
    away_pts = prev[prev['away_teamId'] == a]['away_teamScore'].mean()
    return pd.Series([home_pts, away_pts])

# Get the current for average season calculations
def get_season_start(date):
    return date.year if date.month >= 9 else date.year - 1