import logging
import sys

from google.cloud import bigquery

from config import (
    BQ_DATASET,
    COLLECTIONS_WITH_MEETING_KEY,
    COLLECTIONS_WITH_SESSION_KEY,
    GCP_PROJECT,
    LOOKBACK_HOURS,
    RAW_BUCKET,
)

logging.basicConfig(
    level=logging.INFO,
    format='{"time":"%(asctime)s","level":"%(levelname)s","message":"%(message)s"}',
    stream=sys.stdout,
)
logger = logging.getLogger(__name__)


def _gcs_path(collection: str, year: int, meeting_key: int, session_key: int | None = None) -> str:
    base = f"gs://{RAW_BUCKET}/raw/source=openf1/collection={collection}/year={year}/meeting={meeting_key}"
    if session_key is not None:
        base += f"/session={session_key}"
    return base + "/*.parquet"


def _export_sql(table: str, gcs_uri: str, where: str) -> str:
    return f"""
    EXPORT DATA OPTIONS(
        uri='{gcs_uri}',
        format='PARQUET',
        overwrite=true
    ) AS
    SELECT * FROM `{GCP_PROJECT}.{BQ_DATASET}.{table}`
    WHERE {where}
    """


def _get_recent_sessions(client: bigquery.Client) -> list[dict]:
    sql = f"""
    SELECT DISTINCT
        s.session_key,
        s.meeting_key,
        EXTRACT(YEAR FROM s.date_start) as year,
        s.date_start
    FROM `{GCP_PROJECT}.{BQ_DATASET}.sessions` s
    WHERE s.date_start >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {LOOKBACK_HOURS} HOUR)
    ORDER BY s.date_start DESC
    """
    rows = client.query(sql).result()
    return [dict(row) for row in rows]


def _export_collection(client: bigquery.Client, collection: str, session: dict) -> int:
    year = session["year"]
    meeting_key = session["meeting_key"]
    session_key = session["session_key"]

    gcs_uri = _gcs_path(collection, year, meeting_key, session_key)
    where = f"session_key = {session_key}"

    count_sql = f"""
    SELECT COUNT(*) as cnt
    FROM `{GCP_PROJECT}.{BQ_DATASET}.{collection}`
    WHERE {where}
    """
    count_result = list(client.query(count_sql).result())
    row_count = count_result[0]["cnt"]

    if row_count == 0:
        logger.info("Skipping %s for session %d (no rows)", collection, session_key)
        return 0

    client.query(_export_sql(collection, gcs_uri, where)).result()
    logger.info("Exported %s for session %d: %d rows → %s", collection, session_key, row_count, gcs_uri)
    return row_count


def _export_meeting_collection(client: bigquery.Client, collection: str, meeting_key: int, year: int) -> int:
    gcs_uri = _gcs_path(collection, year, meeting_key)
    where = f"meeting_key = {meeting_key}"

    count_sql = f"""
    SELECT COUNT(*) as cnt
    FROM `{GCP_PROJECT}.{BQ_DATASET}.{collection}`
    WHERE {where}
    """
    count_result = list(client.query(count_sql).result())
    row_count = count_result[0]["cnt"]

    if row_count == 0:
        logger.info("Skipping %s for meeting %d (no rows)", collection, meeting_key)
        return 0

    client.query(_export_sql(collection, gcs_uri, where)).result()
    logger.info("Exported %s for meeting %d: %d rows → %s", collection, meeting_key, row_count, gcs_uri)
    return row_count


def run() -> None:
    client = bigquery.Client(project=GCP_PROJECT)
    sessions = _get_recent_sessions(client)

    if not sessions:
        logger.info("No recent sessions found within %d-hour lookback", LOOKBACK_HOURS)
        return

    logger.info("Found %d recent sessions to export", len(sessions))

    total_exported = 0
    exported_meetings = set()

    for session in sessions:
        session_key = session["session_key"]
        meeting_key = session["meeting_key"]
        year = session["year"]
        logger.info("Exporting session %d (meeting %d, %d)", session_key, meeting_key, year)

        for collection in COLLECTIONS_WITH_SESSION_KEY:
            total_exported += _export_collection(client, collection, session)

        if meeting_key not in exported_meetings:
            exported_meetings.add(meeting_key)
            for collection in COLLECTIONS_WITH_MEETING_KEY:
                total_exported += _export_meeting_collection(client, collection, meeting_key, year)

    logger.info("Export complete: %d total rows across %d sessions", total_exported, len(sessions))


if __name__ == "__main__":
    run()
