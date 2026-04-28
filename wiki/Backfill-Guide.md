# Backfill Guide

## Overview

Historical backfill loads data from 1950 (Jolpica) and 2018 (FastF1) to present. Both jobs are resumable via checkpoint persistence.

## Jolpica Historical Backfill

### Scope

| Dataset | Available From | Estimated Calls |
|---|---|---|
| results | 1950 | ~1,100 rounds |
| qualifying | 2003 | ~450 rounds |
| pitstops | 2011 | ~300 rounds |
| standings | 1950 | ~75 seasons |
| constructor_standings | 1958 | ~67 seasons |
| circuits | 1950 | ~75 seasons |
| drivers | 1950 | ~75 seasons |
| constructors | 1950 | ~75 seasons |

### Runtime Estimate

- ~12,000-20,000 API calls total
- At 8s/call: ~27-44 hours
- At 10s/call: ~33-56 hours
- Should be split into resumable batches

### Running

```bash
# Dry run first (always)
DRY_RUN=true BACKFILL_START_YEAR=1950 BACKFILL_END_YEAR=2024 python -m jobs.backfill_jolpica.main

# Single decade test
BACKFILL_START_YEAR=2020 BACKFILL_END_YEAR=2024 python -m jobs.backfill_jolpica.main

# Full backfill (after dry run approval)
BACKFILL_START_YEAR=1950 BACKFILL_END_YEAR=2024 python -m jobs.backfill_jolpica.main
```

### Checkpointing

Checkpoints are saved to `f1_ops.backfill_checkpoints` after each completed year/dataset. If the job is interrupted, it resumes from the last checkpoint.

Checkpoint fields:
- `source`, `dataset`, `last_completed_year`, `last_completed_round`, `updated_at`

## FastF1 Backfill

### Scope

- Years: 2018 to present
- Sessions: Race (R) and Qualifying (Q)
- Datasets: laps, results, weather per session

### Running

```bash
# Dry run
DRY_RUN=true BACKFILL_START_YEAR=2018 BACKFILL_END_YEAR=2024 python -m jobs.backfill_fastf1.main

# Single season test
BACKFILL_START_YEAR=2024 BACKFILL_END_YEAR=2024 python -m jobs.backfill_fastf1.main

# Full backfill
BACKFILL_START_YEAR=2018 BACKFILL_END_YEAR=2024 python -m jobs.backfill_fastf1.main
```

## Backfill Checklist

1. [ ] Verify GCP credentials are configured
2. [ ] Run dry run for target year range
3. [ ] Review dry run output (expected row counts, dataset coverage)
4. [ ] Get human approval for full backfill
5. [ ] Start backfill with monitoring
6. [ ] Verify checkpoints are being saved
7. [ ] After completion, run `dbt run` to rebuild staging/marts
8. [ ] Validate row counts in `f1_ops.ingest_objects`

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `GCP_PROJECT` | (required) | GCP project ID |
| `RAW_BUCKET` | (required) | GCS bucket name |
| `BQ_OPS_DATASET` | `f1_ops` | BigQuery ops dataset |
| `BACKFILL_START_YEAR` | `1950`/`2018` | Start year for backfill |
| `BACKFILL_END_YEAR` | `2024` | End year for backfill |
| `DRY_RUN` | `false` | Skip actual writes, log what would happen |
| `JOLPICA_RATE_LIMIT_SECONDS` | `8` | Seconds between Jolpica API calls |
