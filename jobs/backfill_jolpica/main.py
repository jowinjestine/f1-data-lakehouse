import json
import logging
import os
import sys

from jobs.ingest_recent import gcs_writer, jolpica_client, manifest, schema_contracts
from jobs.ingest_recent.config import SCHEMA_VERSION

from .checkpoint import get_checkpoint, save_checkpoint

logging.basicConfig(
    level=logging.INFO,
    format='{"time":"%(asctime)s","level":"%(levelname)s","logger":"%(name)s","message":"%(message)s"}',
    stream=sys.stdout,
)
logger = logging.getLogger(__name__)

GCP_PROJECT = os.environ.get("GCP_PROJECT", "")
RAW_BUCKET = os.environ.get("RAW_BUCKET", "")
OPS_DATASET = os.environ.get("BQ_OPS_DATASET", "f1_ops")
START_YEAR = int(os.environ.get("BACKFILL_START_YEAR", "1950"))
END_YEAR = int(os.environ.get("BACKFILL_END_YEAR", "2024"))
DRY_RUN = os.environ.get("DRY_RUN", "false").lower() == "true"


DATASET_CONFIGS = {
    "results": {"start_year": 1950, "fetcher": "fetch_results", "per_round": True},
    "qualifying": {"start_year": 2003, "fetcher": "fetch_qualifying", "per_round": True},
    "pitstops": {"start_year": 2011, "fetcher": "fetch_pitstops", "per_round": True},
    "driver_standings": {"start_year": 1950, "fetcher": "fetch_driver_standings", "per_round": False},
    "constructor_standings": {"start_year": 1958, "fetcher": "fetch_constructor_standings", "per_round": False},
    "drivers": {"start_year": 1950, "fetcher": "fetch_drivers", "per_round": False},
    "constructors": {"start_year": 1950, "fetcher": "fetch_constructors", "per_round": False},
    "circuits": {"start_year": 1950, "fetcher": "fetch_circuits", "per_round": False},
}


def _get_rounds_for_season(year: int) -> list[int]:
    try:
        from fastf1.ergast import Ergast

        ergast = Ergast()
        schedule = ergast.get_race_schedule(season=year)
        if schedule.content and len(schedule.content[0]) > 0:
            return list(range(1, len(schedule.content[0]) + 1))
    except Exception:
        logger.warning("Could not fetch schedule for %d, using default 20 rounds", year)
    return list(range(1, 21))


def run() -> None:
    logger.info("Starting Jolpica backfill (years=%d-%d, dry_run=%s)", START_YEAR, END_YEAR, DRY_RUN)
    stats = {"files_written": 0, "rows_ingested": 0, "errors": 0, "skipped": 0}

    from jobs.ingest_recent.config import generate_ingest_run_id

    for dataset_name, config in DATASET_CONFIGS.items():
        effective_start = max(START_YEAR, config["start_year"])

        checkpoint = get_checkpoint(GCP_PROJECT, OPS_DATASET, "jolpica", dataset_name)
        if checkpoint:
            resume_year = checkpoint["last_completed_year"]
            logger.info("Resuming %s from year %d", dataset_name, resume_year)
            effective_start = resume_year

        for year in range(effective_start, END_YEAR + 1):
            ingest_run_id = generate_ingest_run_id()
            fetcher = getattr(jolpica_client, config["fetcher"])

            if config["per_round"]:
                rounds = _get_rounds_for_season(year)
                for round_num in rounds:
                    try:
                        df = fetcher(year, round_num)
                    except Exception:
                        logger.exception("Failed: %s %d R%02d", dataset_name, year, round_num)
                        stats["errors"] += 1
                        continue

                    if df.empty:
                        stats["skipped"] += 1
                        continue

                    if DRY_RUN:
                        logger.info(
                            "[DRY RUN] Would write %s %d R%02d (%d rows)",
                            dataset_name,
                            year,
                            round_num,
                            len(df),
                        )
                        stats["skipped"] += 1
                        continue

                    result = schema_contracts.validate(df, "jolpica", dataset_name)
                    if not result.valid:
                        gcs_writer.write_quarantine(
                            RAW_BUCKET,
                            schema_contracts.format_quarantine_error("jolpica", dataset_name, result),
                            "jolpica",
                            dataset_name,
                            year,
                            round_num,
                            ingest_run_id,
                        )
                        stats["errors"] += 1
                        continue

                    gcs_uri, row_count = gcs_writer.write_parquet(
                        RAW_BUCKET,
                        df,
                        "jolpica",
                        dataset_name,
                        year,
                        round_num,
                        None,
                        ingest_run_id,
                    )
                    manifest.log_ingest_object(
                        ingest_run_id,
                        "jolpica",
                        dataset_name,
                        year,
                        round_num,
                        None,
                        "success",
                        row_count,
                        gcs_uri,
                        SCHEMA_VERSION,
                    )
                    manifest.update_latest_successful_object(
                        "jolpica",
                        dataset_name,
                        year,
                        round_num,
                        None,
                        ingest_run_id,
                        gcs_uri,
                        row_count,
                    )
                    stats["files_written"] += 1
                    stats["rows_ingested"] += row_count

            else:
                try:
                    df = fetcher(year)
                except Exception:
                    logger.exception("Failed: %s %d", dataset_name, year)
                    stats["errors"] += 1
                    continue

                if df.empty:
                    stats["skipped"] += 1
                    continue

                if DRY_RUN:
                    logger.info("[DRY RUN] Would write %s %d (%d rows)", dataset_name, year, len(df))
                    stats["skipped"] += 1
                    continue

                gcs_uri, row_count = gcs_writer.write_parquet(
                    RAW_BUCKET,
                    df,
                    "jolpica",
                    dataset_name,
                    year,
                    None,
                    None,
                    ingest_run_id,
                )
                manifest.log_ingest_object(
                    ingest_run_id,
                    "jolpica",
                    dataset_name,
                    year,
                    None,
                    None,
                    "success",
                    row_count,
                    gcs_uri,
                    SCHEMA_VERSION,
                )
                manifest.update_latest_successful_object(
                    "jolpica",
                    dataset_name,
                    year,
                    None,
                    None,
                    ingest_run_id,
                    gcs_uri,
                    row_count,
                )
                stats["files_written"] += 1
                stats["rows_ingested"] += row_count

            save_checkpoint(GCP_PROJECT, OPS_DATASET, "jolpica", dataset_name, year, None)

    logger.info("Backfill complete: %s", json.dumps(stats))


if __name__ == "__main__":
    run()
