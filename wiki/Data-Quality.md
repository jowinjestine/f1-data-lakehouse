# Data Quality

## Schema Contracts

YAML-based schema definitions in `contracts/` directory validate data before writing to GCS.

### Contract Structure

Each contract file defines:
- **Required columns** with expected data types
- **Optional columns** that may be present
- **Validation rules** applied before Parquet write

### Available Contracts

| Contract | Source | Datasets |
|---|---|---|
| `fastf1_laps.yml` | FastF1 | Lap timing data |
| `fastf1_results.yml` | FastF1 | Session results |
| `fastf1_weather.yml` | FastF1 | Weather conditions |
| `jolpica_results.yml` | Jolpica | Race results |
| `jolpica_qualifying.yml` | Jolpica | Qualifying times |
| `jolpica_pitstops.yml` | Jolpica | Pit stop data |
| `jolpica_standings.yml` | Jolpica | Championship standings |
| `jolpica_drivers.yml` | Jolpica | Driver metadata |
| `jolpica_constructors.yml` | Jolpica | Constructor metadata |
| `jolpica_circuits.yml` | Jolpica | Circuit metadata |

### Validation Flow

```
DataFrame from source
    |
    v
schema_contracts.validate(df, source, dataset)
    |
    +--> Valid: write Parquet to GCS
    |
    +--> Invalid: write error.json to _quarantine path
                  log to f1_ops.ingest_objects with status="quarantined"
```

## Quarantine

Invalid payloads are written to a separate GCS path:
```
raw/_quarantine/source=fastf1/dataset=laps/year=2024/round=08/ingest_run_id=.../error.json
```

The error JSON includes:
- Source and dataset identifiers
- List of validation errors
- Timestamp of quarantine

## Manifest Logging

Every ingestion operation is logged to BigQuery `f1_ops`:

### `ingest_runs` table
- `run_id`, `source`, `start_time`, `end_time`, `status`, `datasets_processed`, `error_message`

### `ingest_objects` table
- `run_id`, `source`, `dataset`, `year`, `round`, `session_type`
- `status` (success/quarantined/error), `row_count`, `gcs_uri`
- `checksum` (MD5 of GCS URI), `schema_version`, `error_message`

### `latest_successful_objects` table
- Tracks the most recent successful ingest per (source, dataset, year, round, session_type)
- Updated via MERGE after each successful write
- Used by dbt staging models for deduplication

## dbt Tests

### Schema Tests (all models)
- `unique` on surrogate keys
- `not_null` on required fields
- `relationships` between facts and dimensions
- `accepted_values` on categorical fields

### Custom Tests
- `assert_lap_times_positive` — No negative lap times in fct_lap_analysis
- `assert_no_orphan_laps` — All laps link to valid sessions
- `assert_standings_monotonic` — Points don't decrease within a season

### Source Freshness
- `loaded_at_field: ingestion_timestamp`
- Warn: 14 days stale
- Error: 30 days stale
