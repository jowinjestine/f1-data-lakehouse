import os
from datetime import UTC, datetime

GCP_PROJECT = os.environ.get("GCP_PROJECT", "")
RAW_BUCKET = os.environ.get("RAW_BUCKET", "")
BQ_OPS_DATASET = os.environ.get("BQ_OPS_DATASET", "f1_ops")
LOOKBACK_DAYS = int(os.environ.get("LOOKBACK_DAYS", "7"))
SCHEMA_VERSION = "1.0"
JOLPICA_DELAY_SECONDS = float(os.environ.get("JOLPICA_DELAY_SECONDS", "8"))
SAMPLE_MODE = os.environ.get("SAMPLE_MODE", "false").lower() == "true"


def generate_ingest_run_id() -> str:
    return datetime.now(UTC).strftime("%Y%m%dT%H%M%SZ")
