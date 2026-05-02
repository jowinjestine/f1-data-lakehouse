import os

GCP_PROJECT = os.environ["GCP_PROJECT_ID"]
GCP_REGION = os.environ.get("GCP_REGION", "us-central1")
BQ_DATASET = os.environ.get("OPENF1_BQ_DATASET", "f1_streaming")

LIVE_JOB_NAME = os.environ.get("OPENF1_LIVE_JOB_NAME", "openf1-live")
PARQUET_EXPORTER_JOB_NAME = os.environ.get("PARQUET_EXPORTER_JOB_NAME", "f1-parquet-exporter")
DBT_RUNNER_JOB_NAME = os.environ.get("DBT_RUNNER_JOB_NAME", "f1-dbt-runner")

SESSION_BUFFER_MINUTES = int(os.environ.get("SESSION_BUFFER_MINUTES", "35"))
POST_SESSION_DELAY_MINUTES = int(os.environ.get("POST_SESSION_DELAY_MINUTES", "30"))
