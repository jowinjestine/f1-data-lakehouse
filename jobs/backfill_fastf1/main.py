import json
import logging
import os
import sys

from jobs.backfill_jolpica.checkpoint import get_checkpoint, save_checkpoint
from jobs.ingest_recent import fastf1_client, gcs_writer, manifest, schema_contracts
from jobs.ingest_recent.config import SCHEMA_VERSION, generate_ingest_run_id

logging.basicConfig(
    level=logging.INFO,
    format='{"time":"%(asctime)s","level":"%(levelname)s","logger":"%(name)s","message":"%(message)s"}',
    stream=sys.stdout,
)
logger = logging.getLogger(__name__)

GCP_PROJECT = os.environ.get("GCP_PROJECT", "")
RAW_BUCKET = os.environ.get("RAW_BUCKET", "")
OPS_DATASET = os.environ.get("BQ_OPS_DATASET", "f1_ops")
START_YEAR = int(os.environ.get("BACKFILL_START_YEAR", "2018"))
END_YEAR = int(os.environ.get("BACKFILL_END_YEAR", "2024"))
DRY_RUN = os.environ.get("DRY_RUN", "false").lower() == "true"

SESSION_TYPES = ["R", "Q"]


def _get_rounds_for_season(year: int) -> list[int]:
    import fastf1

    schedule = fastf1.get_event_schedule(year)
    return [int(row["RoundNumber"]) for _, row in schedule.iterrows() if row["RoundNumber"] > 0]


def run() -> None:
    logger.info("Starting FastF1 backfill (years=%d-%d, dry_run=%s)", START_YEAR, END_YEAR, DRY_RUN)
    stats = {"files_written": 0, "rows_ingested": 0, "errors": 0, "skipped": 0}

    checkpoint = get_checkpoint(GCP_PROJECT, OPS_DATASET, "fastf1", "all")
    effective_start = START_YEAR
    if checkpoint:
        effective_start = checkpoint["last_completed_year"]
        logger.info("Resuming from year %d", effective_start)

    for year in range(effective_start, END_YEAR + 1):
        try:
            rounds = _get_rounds_for_season(year)
        except Exception:
            logger.exception("Failed to get schedule for %d", year)
            stats["errors"] += 1
            continue

        for round_num in rounds:
            ingest_run_id = generate_ingest_run_id()

            for session_type in SESSION_TYPES:
                try:
                    datasets = fastf1_client.load_session_data(year, round_num, session_type)
                except Exception:
                    logger.exception("Failed: FastF1 %s %d R%02d", session_type, year, round_num)
                    stats["errors"] += 1
                    continue

                for dataset_name, df in datasets.items():
                    if DRY_RUN:
                        logger.info(
                            "[DRY RUN] Would write %s %d R%02d %s (%d rows)",
                            dataset_name,
                            year,
                            round_num,
                            session_type,
                            len(df),
                        )
                        stats["skipped"] += 1
                        continue

                    result = schema_contracts.validate(df, "fastf1", dataset_name)
                    if not result.valid:
                        gcs_writer.write_quarantine(
                            RAW_BUCKET,
                            schema_contracts.format_quarantine_error("fastf1", dataset_name, result),
                            "fastf1",
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
                        "fastf1",
                        dataset_name,
                        year,
                        round_num,
                        session_type,
                        ingest_run_id,
                    )
                    manifest.log_ingest_object(
                        ingest_run_id,
                        "fastf1",
                        dataset_name,
                        year,
                        round_num,
                        session_type,
                        "success",
                        row_count,
                        gcs_uri,
                        SCHEMA_VERSION,
                    )
                    manifest.update_latest_successful_object(
                        "fastf1",
                        dataset_name,
                        year,
                        round_num,
                        session_type,
                        ingest_run_id,
                        gcs_uri,
                        row_count,
                    )
                    stats["files_written"] += 1
                    stats["rows_ingested"] += row_count

        save_checkpoint(GCP_PROJECT, OPS_DATASET, "fastf1", "all", year, None)

    logger.info("FastF1 backfill complete: %s", json.dumps(stats))


if __name__ == "__main__":
    run()
