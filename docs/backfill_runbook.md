# Backfill Runbook

## Overview

Two backfill jobs load historical data into the lakehouse:

| Job | Source | Coverage | Estimated Runtime |
|-----|--------|----------|-------------------|
| `backfill_jolpica` | Jolpica F1 API | 1950-present, 8 datasets | 27-56 hours (full) |
| `backfill_fastf1` | FastF1 SDK | 2018-present, Race + Qualifying | 2-6 hours |

Both jobs are resumable via checkpoints stored in `f1_ops.backfill_checkpoints`.

## Before Running a Backfill

1. Verify the `f1_ops` dataset and `backfill_checkpoints` table exist in BigQuery
2. Confirm Cloud Run Job has sufficient timeout configured (6h for backfills)
3. Check current GCP free tier usage — backfills consume Cloud Run CPU/memory allocation
4. Run a dry run first to validate connectivity and rate limiting

## Running a Backfill

### Via GitHub Actions (Recommended)

Use the `workflow_dispatch` trigger on the Deploy workflow:

```
Job name: backfill_jolpica   or   backfill_fastf1
```

This authenticates via WIF and executes the Cloud Run Job with `--wait`.

### Via gcloud CLI

```bash
gcloud run jobs execute f1-backfill-jolpica \
  --region us-central1 \
  --project YOUR_PROJECT_ID \
  --wait
```

### Dry Run

Set `DRY_RUN=true` as an environment variable on the Cloud Run Job:

```bash
gcloud run jobs update f1-backfill-jolpica \
  --set-env-vars DRY_RUN=true \
  --region us-central1

gcloud run jobs execute f1-backfill-jolpica \
  --region us-central1 --wait

# Reset after testing
gcloud run jobs update f1-backfill-jolpica \
  --remove-env-vars DRY_RUN \
  --region us-central1
```

Dry run processes the first season only, validating API connectivity and schema contracts without writing the full dataset.

## Checkpointing and Resumption

Both backfill jobs save progress after each completed dataset/season/round:

```
source=jolpica, dataset=results, last_completed_year=1987, last_completed_round=NULL
source=fastf1, dataset=laps, last_completed_year=2021, last_completed_round=14
```

If a job fails or times out, re-executing it resumes from the last checkpoint. Checkpoints are stored in `f1_ops.backfill_checkpoints` using a BigQuery MERGE (upsert).

## Jolpica Rate Limiting

The Jolpica API (Ergast successor) has a sustained limit of ~500 requests/hour. The backfill job enforces **8-10 seconds** between requests.

- Full backfill: ~12,000-20,000 API calls
- At 8s/call: ~27-44 hours
- At 10s/call: ~33-56 hours

**Do not reduce the delay below 8 seconds.** Getting rate-limited or blocked will require manual recovery.

## Recommended Backfill Order

1. **Jolpica first** — Provides the historical backbone (1950-present)
2. **FastF1 second** — Enriches modern seasons (2018+) with lap times and weather
3. **dbt run** — After both backfills complete, run dbt to refresh all models

## Monitoring a Running Backfill

```bash
# Check job execution status
gcloud run jobs executions list --job f1-backfill-jolpica --region us-central1

# View logs
gcloud logging read "resource.type=cloud_run_job AND resource.labels.job_name=f1-backfill-jolpica" \
  --limit 50 --format json

# Check checkpoint progress in BigQuery
bq query --use_legacy_sql=false \
  'SELECT * FROM f1_ops.backfill_checkpoints ORDER BY updated_at DESC'
```

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Job times out | 6h timeout exceeded | Re-execute; it resumes from checkpoint |
| Rate limited (429) | Too many API requests | Wait 1 hour, then re-execute |
| Schema validation failure | API response format changed | Check contracts/*.yml, update if needed, quarantine data is saved |
| Checkpoint not advancing | Repeated failure on same season/round | Check logs for the specific error, may need to manually advance checkpoint |
| Memory exceeded | Large response payload | Reduce batch size or increase Cloud Run memory |
