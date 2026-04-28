import logging

import pyarrow as pa
import pyarrow.parquet as pq
from google.cloud import storage

logger = logging.getLogger(__name__)


def _build_path(
    source: str,
    dataset: str,
    year: int,
    round_number: int | None,
    session_type: str | None,
    ingest_run_id: str,
) -> str:
    parts = [f"raw/source={source}", f"dataset={dataset}", f"year={year}"]
    if round_number is not None:
        parts.append(f"round={round_number:02d}")
    if session_type is not None:
        parts.append(f"session={session_type}")
    parts.append(f"ingest_run_id={ingest_run_id}")
    parts.append("part-000.parquet")
    return "/".join(parts)


def _build_quarantine_path(
    source: str,
    dataset: str,
    year: int,
    round_number: int | None,
    ingest_run_id: str,
) -> str:
    parts = [f"raw/_quarantine/source={source}", f"dataset={dataset}", f"year={year}"]
    if round_number is not None:
        parts.append(f"round={round_number:02d}")
    parts.append(f"ingest_run_id={ingest_run_id}")
    parts.append("error.json")
    return "/".join(parts)


def write_parquet(
    bucket_name: str,
    df,
    source: str,
    dataset: str,
    year: int,
    round_number: int | None,
    session_type: str | None,
    ingest_run_id: str,
) -> tuple[str, int]:
    gcs_path = _build_path(source, dataset, year, round_number, session_type, ingest_run_id)
    gcs_uri = f"gs://{bucket_name}/{gcs_path}"

    table = pa.Table.from_pandas(df)
    buf = pa.BufferOutputStream()
    pq.write_table(table, buf, compression="snappy")
    data = buf.getvalue().to_pybytes()

    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(gcs_path)
    blob.upload_from_string(data, content_type="application/octet-stream")

    row_count = len(df)
    logger.info("Wrote %d rows to %s", row_count, gcs_uri)
    return gcs_uri, row_count


def write_quarantine(
    bucket_name: str,
    error_json: str,
    source: str,
    dataset: str,
    year: int,
    round_number: int | None,
    ingest_run_id: str,
) -> str:
    gcs_path = _build_quarantine_path(source, dataset, year, round_number, ingest_run_id)
    gcs_uri = f"gs://{bucket_name}/{gcs_path}"

    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(gcs_path)
    blob.upload_from_string(error_json, content_type="application/json")

    logger.warning("Quarantined invalid data to %s", gcs_uri)
    return gcs_uri
