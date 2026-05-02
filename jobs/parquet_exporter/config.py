import os

GCP_PROJECT = os.environ["GCP_PROJECT_ID"]
RAW_BUCKET = os.environ["RAW_BUCKET"]
BQ_DATASET = os.environ.get("OPENF1_BQ_DATASET", "f1_streaming")
LOOKBACK_HOURS = int(os.environ.get("EXPORT_LOOKBACK_HOURS", "48"))

COLLECTIONS_WITH_SESSION_KEY = [
    "car_data",
    "location",
    "laps",
    "stints",
    "weather",
    "position",
    "intervals",
    "pit",
    "race_control",
    "team_radio",
    "drivers",
    "championship_drivers",
    "championship_teams",
    "overtakes",
]

COLLECTIONS_WITH_MEETING_KEY = [
    "sessions",
    "meetings",
]
