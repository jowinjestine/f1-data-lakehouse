# Pipeline Overview

## Ingestion Layer

### Weekly Ingestion (`ingest_recent`)

Triggered weekly by Cloud Scheduler. Processes recent F1 race weekends.

**Flow:**
1. `calendar_check.py` — Find events in the last N days via `fastf1.get_event_schedule()`
2. For each event:
   - Load FastF1 session data (Race, Qualifying, Sprint)
   - Fetch Jolpica data (results, qualifying, pitstops)
3. `schema_contracts.py` — Validate each DataFrame against YAML contracts
4. Valid data: `gcs_writer.py` writes immutable Parquet to GCS
5. Invalid data: Written to `raw/_quarantine/` path as JSON
6. `manifest.py` — Log every operation to `f1_ops` BigQuery tables

**Entry point:** `jobs/ingest_recent/main.py`

### Historical Backfill

Two separate jobs for resumable backfill:

**Jolpica Backfill** (`jobs/backfill_jolpica/main.py`)
- Covers 1950 to present across 8 dataset types
- 8-10s between API calls (~27-56 hours for full backfill)
- Persistent checkpointing per dataset/year in `f1_ops.backfill_checkpoints`
- Dry-run mode for pre-flight validation

**FastF1 Backfill** (`jobs/backfill_fastf1/main.py`)
- Covers 2018 to present (Race + Qualifying sessions)
- Per-season checkpointing
- Reuses `ingest_recent` clients and writers

## Transformation Layer (dbt)

**Runner:** `jobs/dbt_runner/main.py` executes the full dbt pipeline:
1. `dbt deps` — Install packages
2. `dbt run-operation stage_external_sources` — Refresh external tables
3. `dbt source freshness` — Check data freshness
4. `dbt run --target prod` — Build all models
5. `dbt test --target prod` — Run all tests
6. `dbt docs generate` — Generate documentation

### Model Layers

```
Sources (GCS Parquet via external tables)
    |
Staging (f1_staging) — clean, rename, type-cast, filter to latest_successful_objects
    |
Marts (f1_analytics) — dimensions + facts joined via crosswalks
    |
Aggregates (f1_analytics) — pre-computed analytics for dashboards
```

## Serving Layer

- **BigQuery** — Direct query access to all layers
- **Looker Studio** — Connected to `f1_analytics` and `f1_ops` datasets
- **dbt Docs** — Generated lineage graph and model documentation

## Orchestration

| Schedule | Job | Cron | Notes |
|---|---|---|---|
| Weekly ingest | `ingest_recent` | `0 8 * * 1` (Monday 8 AM UTC) | Calendar-aware |
| Weekly dbt | `dbt_runner` | `0 9 * * 1` (Monday 9 AM UTC) | After ingest |
| Backfill | Manual | `workflow_dispatch` | One-time, resumable |
