import logging
import os
import re
import tempfile
from datetime import UTC, datetime

import fastf1
import pandas as pd

from .config import SCHEMA_VERSION

logger = logging.getLogger(__name__)

SESSION_MAP = {
    "R": "Race",
    "Q": "Qualifying",
    "S": "Sprint",
    "SQ": "Sprint Qualifying",
}


def _to_snake_case(name: str) -> str:
    s = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name)
    s = re.sub(r"([a-z\d])([A-Z])", r"\1_\2", s)
    return s.lower()


def _normalize_columns(df: pd.DataFrame) -> pd.DataFrame:
    df.columns = [_to_snake_case(c) for c in df.columns]
    return df


def _add_metadata(df: pd.DataFrame) -> pd.DataFrame:
    df["ingestion_timestamp"] = datetime.now(UTC).isoformat()
    df["schema_version"] = SCHEMA_VERSION
    return df


def _convert_timedeltas(df: pd.DataFrame) -> pd.DataFrame:
    for col in df.columns:
        if pd.api.types.is_timedelta64_dtype(df[col]):
            df[col] = df[col].dt.total_seconds()
    return df


def load_session_data(year: int, round_number: int, session_type: str) -> dict[str, pd.DataFrame]:
    session_name = SESSION_MAP.get(session_type, session_type)
    logger.info("Loading FastF1 %s %d R%02d", session_name, year, round_number)

    cache_dir = os.environ.get("FASTF1_CACHE_DIR", os.path.join(tempfile.gettempdir(), "fastf1_cache"))
    os.makedirs(cache_dir, exist_ok=True)
    fastf1.Cache.enable_cache(cache_dir)
    session = fastf1.get_session(year, round_number, session_name)
    session.load()

    datasets: dict[str, pd.DataFrame] = {}

    if session.laps is not None and len(session.laps) > 0:
        laps = session.laps.reset_index(drop=True)
        laps = _normalize_columns(laps)
        laps = _convert_timedeltas(laps)
        laps = _add_metadata(laps)
        datasets["laps"] = laps

    if session.results is not None and len(session.results) > 0:
        results = session.results.reset_index(drop=True)
        results = _normalize_columns(results)
        results = _convert_timedeltas(results)
        results = _add_metadata(results)
        datasets["results"] = results

    if session.weather_data is not None and len(session.weather_data) > 0:
        weather = session.weather_data.reset_index(drop=True)
        weather = _normalize_columns(weather)
        weather = _convert_timedeltas(weather)
        weather = _add_metadata(weather)
        datasets["weather"] = weather

    logger.info("Loaded %d datasets for %s %d R%02d", len(datasets), session_name, year, round_number)
    return datasets
