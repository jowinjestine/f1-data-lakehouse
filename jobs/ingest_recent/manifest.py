import hashlib
import logging
from datetime import UTC, datetime

from google.cloud import bigquery

from .config import BQ_OPS_DATASET, GCP_PROJECT

logger = logging.getLogger(__name__)


def _get_client() -> bigquery.Client:
    return bigquery.Client(project=GCP_PROJECT)


def log_ingest_run(
    run_id: str,
    source: str,
    status: str,
    datasets_processed: int,
    error_message: str | None = None,
) -> None:
    client = _get_client()
    table_id = f"{GCP_PROJECT}.{BQ_OPS_DATASET}.ingest_runs"

    rows = [
        {
            "run_id": run_id,
            "source": source,
            "start_time": datetime.now(UTC).isoformat(),
            "end_time": datetime.now(UTC).isoformat(),
            "status": status,
            "datasets_processed": datasets_processed,
            "error_message": error_message,
        }
    ]

    errors = client.insert_rows_json(table_id, rows)
    if errors:
        logger.error("Failed to log ingest run: %s", errors)
    else:
        logger.info("Logged ingest run %s (%s)", run_id, status)


def log_ingest_object(
    run_id: str,
    source: str,
    dataset: str,
    year: int,
    round_number: int | None,
    session_type: str | None,
    status: str,
    row_count: int,
    gcs_uri: str,
    schema_version: str,
    error_message: str | None = None,
) -> None:
    client = _get_client()
    table_id = f"{GCP_PROJECT}.{BQ_OPS_DATASET}.ingest_objects"

    checksum = hashlib.md5(gcs_uri.encode()).hexdigest()

    rows = [
        {
            "run_id": run_id,
            "source": source,
            "dataset": dataset,
            "year": year,
            "round": round_number,
            "session_type": session_type,
            "status": status,
            "row_count": row_count,
            "gcs_uri": gcs_uri,
            "checksum": checksum,
            "schema_version": schema_version,
            "error_message": error_message,
            "logged_at": datetime.now(UTC).isoformat(),
        }
    ]

    errors = client.insert_rows_json(table_id, rows)
    if errors:
        logger.error("Failed to log ingest object: %s", errors)


def update_latest_successful_object(
    source: str,
    dataset: str,
    year: int,
    round_number: int | None,
    session_type: str | None,
    ingest_run_id: str,
    gcs_uri: str,
    row_count: int,
) -> None:
    client = _get_client()
    table_id = f"{GCP_PROJECT}.{BQ_OPS_DATASET}.latest_successful_objects"
    checksum = hashlib.md5(gcs_uri.encode()).hexdigest()

    query = f"""
    MERGE `{table_id}` t
    USING (SELECT @source AS source, @dataset AS dataset, @year AS year,
                  @round AS round, @session_type AS session_type) s
    ON t.source = s.source AND t.dataset = s.dataset AND t.year = s.year
       AND IFNULL(t.round, -1) = IFNULL(s.round, -1)
       AND IFNULL(t.session_type, '') = IFNULL(s.session_type, '')
    WHEN MATCHED THEN UPDATE SET
        latest_ingest_run_id = @ingest_run_id,
        gcs_uri = @gcs_uri,
        row_count = @row_count,
        checksum = @checksum,
        updated_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN INSERT
        (source, dataset, year, round, session_type, latest_ingest_run_id, gcs_uri, row_count, checksum, updated_at)
    VALUES
        (@source, @dataset, @year, @round, @session_type, @ingest_run_id,
         @gcs_uri, @row_count, @checksum, CURRENT_TIMESTAMP())
    """

    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("source", "STRING", source),
            bigquery.ScalarQueryParameter("dataset", "STRING", dataset),
            bigquery.ScalarQueryParameter("year", "INT64", year),
            bigquery.ScalarQueryParameter("round", "INT64", round_number),
            bigquery.ScalarQueryParameter("session_type", "STRING", session_type),
            bigquery.ScalarQueryParameter("ingest_run_id", "STRING", ingest_run_id),
            bigquery.ScalarQueryParameter("gcs_uri", "STRING", gcs_uri),
            bigquery.ScalarQueryParameter("row_count", "INT64", row_count),
            bigquery.ScalarQueryParameter("checksum", "STRING", checksum),
        ]
    )

    client.query(query, job_config=job_config).result()
    logger.info("Updated latest_successful_objects for %s/%s/%d", source, dataset, year)
