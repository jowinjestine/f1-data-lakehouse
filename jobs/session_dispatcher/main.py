import logging
import sys
from datetime import datetime, timedelta, timezone

import requests
from google.cloud import bigquery, run_v2

from config import (
    BQ_DATASET,
    DBT_RUNNER_JOB_NAME,
    GCP_PROJECT,
    GCP_REGION,
    LIVE_JOB_NAME,
    PARQUET_EXPORTER_JOB_NAME,
    POST_SESSION_DELAY_MINUTES,
    SESSION_BUFFER_MINUTES,
)

F1_API_BASE = "http://api.formula1.com/v1"
F1_API_HEADERS = {
    "apiKey": "v1JVGPgXlahatAqwhakbrGtFdxW5rQBz",
    "locale": "en",
}

logging.basicConfig(
    level=logging.INFO,
    format='{"time":"%(asctime)s","level":"%(levelname)s","message":"%(message)s"}',
    stream=sys.stdout,
)
logger = logging.getLogger(__name__)


def _get_todays_sessions(bq_client: bigquery.Client) -> list[dict]:
    now = datetime.now(timezone.utc)
    day_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    day_end = day_start + timedelta(days=1)

    sql = f"""
    SELECT session_key, meeting_key, session_name, session_type, date_start, date_end
    FROM `{GCP_PROJECT}.{BQ_DATASET}.sessions`
    WHERE date_start >= @day_start
      AND date_start < @day_end
    ORDER BY date_start
    """
    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("day_start", "TIMESTAMP", day_start),
            bigquery.ScalarQueryParameter("day_end", "TIMESTAMP", day_end),
        ]
    )
    rows = bq_client.query(sql, job_config=job_config).result()
    return [dict(row) for row in rows]


def _is_job_running(run_client: run_v2.JobsClient, job_name: str) -> bool:
    full_name = f"projects/{GCP_PROJECT}/locations/{GCP_REGION}/jobs/{job_name}"
    try:
        job = run_client.get_job(name=full_name)
        if job.latest_created_execution and not job.latest_created_execution.completion_time:
            logger.info("Job %s already has a running execution", job_name)
            return True
    except Exception:
        pass
    return False


def _trigger_job(run_client: run_v2.JobsClient, job_name: str) -> str | None:
    if _is_job_running(run_client, job_name):
        return None
    full_name = f"projects/{GCP_PROJECT}/locations/{GCP_REGION}/jobs/{job_name}"
    logger.info("Triggering Cloud Run job: %s", job_name)
    operation = run_client.run_job(name=full_name)
    logger.info("Job %s triggered, execution: %s", job_name, operation.metadata.name)
    return operation.metadata.name


def _should_start_live(session: dict) -> bool:
    now = datetime.now(timezone.utc)
    session_start = session["date_start"]
    if session_start.tzinfo is None:
        session_start = session_start.replace(tzinfo=timezone.utc)
    buffer = timedelta(minutes=SESSION_BUFFER_MINUTES)
    return now >= (session_start - buffer) and now <= session_start + timedelta(hours=4)


def _is_session_finished(session: dict) -> bool:
    now = datetime.now(timezone.utc)
    date_end = session.get("date_end")
    if date_end is None:
        return False
    if date_end.tzinfo is None:
        date_end = date_end.replace(tzinfo=timezone.utc)
    post_delay = timedelta(minutes=POST_SESSION_DELAY_MINUTES)
    return now >= (date_end + post_delay)


def _to_utc(date_str: str, offset_str: str) -> datetime:
    local_dt = datetime.fromisoformat(date_str)
    is_negative = offset_str.startswith("-")
    clean = offset_str.lstrip("-")
    h, m, s = map(int, clean.split(":"))
    delta = timedelta(hours=h, minutes=m, seconds=s)
    if is_negative:
        delta = -delta
    return (local_dt - delta).replace(tzinfo=timezone.utc)


def _fetch_sessions_from_f1_api() -> list[dict]:
    """Fetches current-year session schedule directly from the F1 API."""
    resp = requests.get(
        f"{F1_API_BASE}/editorial-eventlisting/events",
        headers=F1_API_HEADERS,
        timeout=30,
    )
    resp.raise_for_status()
    data = resp.json()

    sessions = []
    for event in data["events"]:
        offset = event["gmtOffset"].lstrip("+") + ":00"
        meeting_key = int(event["meetingKey"])

        try:
            tt_resp = requests.get(
                f"{F1_API_BASE}/event-tracker/meeting/{meeting_key}",
                headers=F1_API_HEADERS,
                timeout=30,
            )
            tt_resp.raise_for_status()
            timetable = tt_resp.json()["meetingContext"]["timetables"]
        except Exception:
            logger.warning("Failed to fetch timetable for meeting %d", meeting_key)
            continue

        for sess in timetable:
            sessions.append({
                "session_key": sess["meetingSessionKey"],
                "session_type": sess["sessionType"],
                "session_name": sess["description"],
                "date_start": _to_utc(sess["startTime"], offset),
                "date_end": _to_utc(sess["endTime"], offset),
                "meeting_key": meeting_key,
                "year": int(data["year"]),
                "_key": sess["meetingSessionKey"],
                "_id": sess["meetingSessionKey"],
            })
    return sessions


def _ensure_sessions_populated(bq_client: bigquery.Client) -> None:
    sql = f"SELECT COUNT(*) as cnt FROM `{GCP_PROJECT}.{BQ_DATASET}.sessions`"
    cnt = list(bq_client.query(sql).result())[0].cnt
    if cnt > 0:
        return

    logger.info("Sessions table empty — fetching from F1 API")
    rows = _fetch_sessions_from_f1_api()
    if not rows:
        logger.warning("F1 API returned no sessions")
        return

    table_id = f"{GCP_PROJECT}.{BQ_DATASET}.sessions"
    serialized = []
    for r in rows:
        row = {}
        for k, v in r.items():
            row[k] = v.isoformat() if isinstance(v, datetime) else v
        serialized.append(row)

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
    )
    job = bq_client.load_table_from_json(serialized, table_id, job_config=job_config)
    job.result()
    logger.info("Loaded %d sessions into BQ", len(serialized))


def run() -> None:
    bq_client = bigquery.Client(project=GCP_PROJECT)
    run_client = run_v2.JobsClient()

    _ensure_sessions_populated(bq_client)

    sessions = _get_todays_sessions(bq_client)
    if not sessions:
        logger.info("No F1 sessions scheduled today")
        return

    logger.info("Found %d sessions today: %s",
                len(sessions),
                [s["session_type"] for s in sessions])

    for session in sessions:
        session_type = session["session_type"]
        session_key = session["session_key"]

        if _should_start_live(session):
            logger.info("Session %s (%d) is starting soon — triggering live ingestor",
                        session_type, session_key)
            _trigger_job(run_client, LIVE_JOB_NAME)

        if _is_session_finished(session):
            logger.info("Session %s (%d) finished — triggering post-session pipeline",
                        session_type, session_key)
            _trigger_job(run_client, PARQUET_EXPORTER_JOB_NAME)
            _trigger_job(run_client, DBT_RUNNER_JOB_NAME)

    logger.info("Dispatcher complete")


if __name__ == "__main__":
    run()
