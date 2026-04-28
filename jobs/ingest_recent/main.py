import json
import logging
import sys

from . import calendar_check, fastf1_client, gcs_writer, jolpica_client, manifest, schema_contracts
from .config import GCP_PROJECT, LOOKBACK_DAYS, RAW_BUCKET, SAMPLE_MODE, SCHEMA_VERSION, generate_ingest_run_id

logging.basicConfig(
    level=logging.INFO,
    format='{"time":"%(asctime)s","level":"%(levelname)s","logger":"%(name)s","message":"%(message)s"}',
    stream=sys.stdout,
)
logger = logging.getLogger(__name__)


def _ingest_fastf1_session(
    year: int,
    round_number: int,
    session_type: str,
    ingest_run_id: str,
    stats: dict,
) -> None:
    try:
        datasets = fastf1_client.load_session_data(year, round_number, session_type)
    except Exception:
        logger.exception("Failed to load FastF1 %s %d R%02d", session_type, year, round_number)
        stats["errors"] += 1
        return

    for dataset_name, df in datasets.items():
        result = schema_contracts.validate(df, "fastf1", dataset_name)
        if not result.valid:
            error_json = schema_contracts.format_quarantine_error("fastf1", dataset_name, result)
            gcs_writer.write_quarantine(
                RAW_BUCKET,
                error_json,
                "fastf1",
                dataset_name,
                year,
                round_number,
                ingest_run_id,
            )
            manifest.log_ingest_object(
                ingest_run_id,
                "fastf1",
                dataset_name,
                year,
                round_number,
                session_type,
                "quarantined",
                0,
                "",
                SCHEMA_VERSION,
                error_message="; ".join(result.errors),
            )
            stats["quarantined"] += 1
            continue

        gcs_uri, row_count = gcs_writer.write_parquet(
            RAW_BUCKET,
            df,
            "fastf1",
            dataset_name,
            year,
            round_number,
            session_type,
            ingest_run_id,
        )
        manifest.log_ingest_object(
            ingest_run_id,
            "fastf1",
            dataset_name,
            year,
            round_number,
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
            round_number,
            session_type,
            ingest_run_id,
            gcs_uri,
            row_count,
        )
        stats["files_written"] += 1
        stats["rows_ingested"] += row_count


def _ingest_jolpica_round(
    year: int,
    round_number: int,
    ingest_run_id: str,
    stats: dict,
) -> None:
    jolpica_datasets = {
        "results": lambda: jolpica_client.fetch_results(year, round_number),
        "qualifying": lambda: jolpica_client.fetch_qualifying(year, round_number),
        "pitstops": lambda: jolpica_client.fetch_pitstops(year, round_number),
    }

    for dataset_name, fetcher in jolpica_datasets.items():
        try:
            df = fetcher()
        except Exception:
            logger.exception("Failed to fetch Jolpica %s for %d R%02d", dataset_name, year, round_number)
            stats["errors"] += 1
            continue

        if df.empty:
            logger.info("No Jolpica %s data for %d R%02d", dataset_name, year, round_number)
            continue

        result = schema_contracts.validate(df, "jolpica", dataset_name)
        if not result.valid:
            error_json = schema_contracts.format_quarantine_error("jolpica", dataset_name, result)
            gcs_writer.write_quarantine(
                RAW_BUCKET,
                error_json,
                "jolpica",
                dataset_name,
                year,
                round_number,
                ingest_run_id,
            )
            stats["quarantined"] += 1
            continue

        gcs_uri, row_count = gcs_writer.write_parquet(
            RAW_BUCKET,
            df,
            "jolpica",
            dataset_name,
            year,
            round_number,
            None,
            ingest_run_id,
        )
        manifest.log_ingest_object(
            ingest_run_id,
            "jolpica",
            dataset_name,
            year,
            round_number,
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
            round_number,
            None,
            ingest_run_id,
            gcs_uri,
            row_count,
        )
        stats["files_written"] += 1
        stats["rows_ingested"] += row_count


def run() -> None:
    logger.info("Starting F1 ingestion (project=%s, bucket=%s)", GCP_PROJECT, RAW_BUCKET)
    ingest_run_id = generate_ingest_run_id()
    stats = {"files_written": 0, "rows_ingested": 0, "quarantined": 0, "errors": 0}

    events = calendar_check.get_recent_events(LOOKBACK_DAYS)
    if not events:
        logger.info("No recent events found in last %d days", LOOKBACK_DAYS)
        manifest.log_ingest_run(ingest_run_id, "all", "success", 0)
        return

    if SAMPLE_MODE:
        events = events[:1]
        logger.info("Sample mode: processing only first event")

    for event in events:
        logger.info("Processing %s (%d R%02d)", event.event_name, event.year, event.round_number)

        for session_type in event.session_types:
            _ingest_fastf1_session(event.year, event.round_number, session_type, ingest_run_id, stats)

        _ingest_jolpica_round(event.year, event.round_number, ingest_run_id, stats)

    status = "success" if stats["errors"] == 0 else "partial_success"
    manifest.log_ingest_run(ingest_run_id, "all", status, stats["files_written"])

    logger.info("Ingestion complete: %s", json.dumps(stats))


if __name__ == "__main__":
    run()
