import logging
import time
from datetime import UTC

import pandas as pd
from fastf1.ergast import Ergast

from .config import JOLPICA_DELAY_SECONDS, SCHEMA_VERSION

logger = logging.getLogger(__name__)


def _add_metadata(df: pd.DataFrame) -> pd.DataFrame:
    from datetime import datetime

    df["ingestion_timestamp"] = datetime.now(UTC).isoformat()
    df["schema_version"] = SCHEMA_VERSION
    return df


def _rate_limit():
    logger.debug("Rate limiting: sleeping %.1fs", JOLPICA_DELAY_SECONDS)
    time.sleep(JOLPICA_DELAY_SECONDS)


def _fetch_all_pages(result) -> pd.DataFrame:
    frames = [result.content[0]] if result.content and len(result.content[0]) > 0 else []
    while not result.is_complete:
        _rate_limit()
        result = result.get_next_result_page()
        if result.content and len(result.content[0]) > 0:
            frames.append(result.content[0])
    return pd.concat(frames, ignore_index=True) if frames else pd.DataFrame()


def fetch_results(year: int, round_number: int) -> pd.DataFrame:
    logger.info("Fetching Jolpica results for %d R%02d", year, round_number)
    ergast = Ergast()
    result = ergast.get_race_results(season=year, round=round_number)
    _rate_limit()
    df = _fetch_all_pages(result)
    return _add_metadata(df) if len(df) > 0 else df


def fetch_qualifying(year: int, round_number: int) -> pd.DataFrame:
    logger.info("Fetching Jolpica qualifying for %d R%02d", year, round_number)
    ergast = Ergast()
    result = ergast.get_qualifying_results(season=year, round=round_number)
    _rate_limit()
    df = _fetch_all_pages(result)
    return _add_metadata(df) if len(df) > 0 else df


def fetch_pitstops(year: int, round_number: int) -> pd.DataFrame:
    logger.info("Fetching Jolpica pit stops for %d R%02d", year, round_number)
    ergast = Ergast()
    result = ergast.get_pit_stops(season=year, round=round_number)
    _rate_limit()
    df = _fetch_all_pages(result)
    return _add_metadata(df) if len(df) > 0 else df


def fetch_driver_standings(year: int, round_number: int | None = None) -> pd.DataFrame:
    logger.info("Fetching Jolpica driver standings for %d", year)
    ergast = Ergast()
    kwargs = {"season": year}
    if round_number is not None:
        kwargs["round"] = round_number
    result = ergast.get_driver_standings(**kwargs)
    _rate_limit()
    df = _fetch_all_pages(result)
    return _add_metadata(df) if len(df) > 0 else df


def fetch_constructor_standings(year: int, round_number: int | None = None) -> pd.DataFrame:
    logger.info("Fetching Jolpica constructor standings for %d", year)
    ergast = Ergast()
    kwargs = {"season": year}
    if round_number is not None:
        kwargs["round"] = round_number
    result = ergast.get_constructor_standings(**kwargs)
    _rate_limit()
    df = _fetch_all_pages(result)
    return _add_metadata(df) if len(df) > 0 else df


def fetch_drivers(year: int | None = None) -> pd.DataFrame:
    logger.info("Fetching Jolpica drivers for %s", year or "all")
    ergast = Ergast()
    kwargs = {}
    if year is not None:
        kwargs["season"] = year
    result = ergast.get_driver_info(**kwargs)
    _rate_limit()
    df = _fetch_all_pages(result)
    return _add_metadata(df) if len(df) > 0 else df


def fetch_constructors(year: int | None = None) -> pd.DataFrame:
    logger.info("Fetching Jolpica constructors for %s", year or "all")
    ergast = Ergast()
    kwargs = {}
    if year is not None:
        kwargs["season"] = year
    result = ergast.get_constructor_info(**kwargs)
    _rate_limit()
    df = _fetch_all_pages(result)
    return _add_metadata(df) if len(df) > 0 else df


def fetch_circuits(year: int | None = None) -> pd.DataFrame:
    logger.info("Fetching Jolpica circuits for %s", year or "all")
    ergast = Ergast()
    kwargs = {}
    if year is not None:
        kwargs["season"] = year
    result = ergast.get_circuits(**kwargs)
    _rate_limit()
    df = _fetch_all_pages(result)
    return _add_metadata(df) if len(df) > 0 else df
