# Architecture

## System Overview

```
FastF1 SDK                         Jolpica F1 API
   |                                  |
Cloud Run Job: ingest_recent       Cloud Run Job: backfill_jolpica
   |                                  |
Schema Validation + Source Contracts
   |
GCS Raw Immutable Parquet (with ingest_run_id)
   |
BigQuery f1_raw (external tables)
   |
dbt staging views (f1_staging)
   |
dbt marts + aggregates (f1_analytics)
   |
Looker Studio Dashboards

Supporting:
- f1_ops dataset (ingest_runs, ingest_objects, backfill_checkpoints, latest_successful_objects)
- Terraform for all infrastructure
- GitHub Actions CI/CD
```

## BigQuery Datasets

| Dataset | Purpose | Materialization |
|---|---|---|
| `f1_raw` | External tables over GCS Parquet | External |
| `f1_staging` | Cleaned source-level models | Views |
| `f1_analytics` | Dashboard-ready dimensional models + aggregates | Tables |
| `f1_ops` | Operational metadata and observability | Tables |

## GCS Path Format

Immutable writes with `ingest_run_id` for full traceability:

```
raw/source=fastf1/dataset=laps/year=2024/round=08/session=R/ingest_run_id=20260427T120000Z/part-000.parquet
raw/source=jolpica/dataset=results/year=2024/round=08/ingest_run_id=20260427T120000Z/part-000.parquet
raw/source=jolpica/dataset=drivers/year=2024/ingest_run_id=20260427T120000Z/part-000.parquet
raw/_quarantine/source=jolpica/dataset=results/year=2024/round=08/ingest_run_id=.../error.json
```

## Location Strategy

| Resource | Location | Reason |
|---|---|---|
| BigQuery datasets | `US` multi-region | Compatible with external tables, free tier eligible |
| GCS raw bucket | `us-central1` regional | Compatible with BigQuery US, GCS free tier eligible |

## Deduplication Strategy

Because raw GCS writes are immutable, multiple versions of the same race/dataset can exist. The `f1_ops.latest_successful_objects` table tracks the latest successful ingest per unique data slice:

```
source, dataset, year, round, session_type, latest_ingest_run_id, gcs_uri, row_count, checksum
```

All dbt staging models join/filter to `latest_successful_objects` to read only current-truth raw files and avoid duplicates.

## Cloud Run Job Configuration

| Job | Timeout | Memory | Concurrency | Notes |
|---|---|---|---|---|
| `ingest_recent` | 900-1800s | 1 GB | 1 | Weekly scheduled, one event at a time |
| `backfill_jolpica` | 2-6h | 1 GB | 1 | Checkpoint+resume, max_retries=0-1 |
| `backfill_fastf1` | 2-6h | 1 GB | 1 | Checkpoint+resume, max_retries=0-1 |
| `dbt_runner` | 1800-3600s | 1-2 GB | 1 | dbt deps+run+test+docs |

## Key Design Decisions

| Decision | Alternative Considered | Why This Choice |
|---|---|---|
| Cloud Run Jobs | Cloud Functions Gen2 | Longer runtime, better for backfill/dbt, local container testing |
| Immutable GCS writes | Idempotent overwrites | Traceability, debugging, replay capability |
| 4 BQ datasets (+ f1_ops) | 3 datasets | Operational metadata and observability separation |
| Entity crosswalk seeds | Direct UNION | Proper identity resolution across FastF1/Jolpica |
| Workload Identity Federation | SA JSON keys | No static credentials, modern GCP security |
| `dbt parse` in CI | `dbt compile` | BigQuery adapter requires credentials even for compile |
