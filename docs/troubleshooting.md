# Troubleshooting

## Ingestion Issues

### FastF1 session data not loading

**Symptom**: `fastf1_client.load_session_data()` returns empty or raises an error.

**Causes**:
- Event hasn't happened yet (calendar_check should filter this)
- FastF1 cache is corrupted
- FastF1 API is temporarily unavailable

**Fix**: Clear the FastF1 cache (`/tmp/fastf1_cache/`) and retry. Check the FastF1 status page or GitHub issues.

### Jolpica API returning 429

**Symptom**: HTTP 429 Too Many Requests during backfill.

**Fix**: Wait at least 1 hour before retrying. The backfill will resume from its last checkpoint. Do not reduce `JOLPICA_DELAY_SECONDS` below 8.

### Schema validation failures

**Symptom**: Data written to quarantine path instead of raw path.

**Fix**: Check the quarantine error JSON at `raw/_quarantine/source=.../`. Compare the actual columns/types against the contract YAML in `contracts/`. If the upstream API changed its response format, update the contract and re-run.

### Ingest run logged but no objects

**Symptom**: `f1_ops.ingest_runs` has a row but `f1_ops.ingest_objects` is empty.

**Fix**: Check logs for errors between run start and object writes. Likely a schema validation failure or GCS write error.

## dbt Issues

### `dbt compile` fails with missing sources

**Symptom**: `Compilation Error: Node ... depends on source ... which was not found`.

**Fix**: Run `dbt deps` first to install packages (dbt-external-tables). Then run `dbt run-operation stage_external_sources` to create external tables before compiling.

### `dbt run` fails with "table not found" for `latest_successful_objects`

**Symptom**: Staging models fail because `f1_ops.latest_successful_objects` doesn't exist.

**Fix**: The `latest_successful_objects` table is created by the ingest manifest logger. Run at least one ingestion before running dbt. Alternatively, create the table manually:

```sql
CREATE TABLE IF NOT EXISTS f1_ops.latest_successful_objects (
  source STRING,
  dataset STRING,
  year INT64,
  round INT64,
  session_type STRING,
  latest_ingest_run_id STRING,
  gcs_uri STRING,
  row_count INT64,
  checksum STRING
);
```

### dbt tests failing

**Symptom**: `dbt test` reports failures.

**Fix**: Check which test failed. Common causes:
- `assert_standings_monotonic`: Negative points — check source data for scoring anomalies
- `assert_lap_times_positive`: Zero or negative lap times — usually in/out laps that weren't filtered
- `assert_no_orphan_laps`: Laps without matching results — check if results were ingested for that round

## Terraform Issues

### `terraform init` fails with backend errors

**Symptom**: Backend configuration errors when initializing.

**Fix**: For first-time setup, the GCS backend bucket must exist before `terraform init`. Either create it manually or use `-backend=false` for validation only.

### WIF impersonation denied

**Symptom**: GitHub Actions fails with "Permission denied" on WIF authentication.

**Fix**: Verify:
1. The WIF pool and provider are created (`terraform apply`)
2. The GitHub repo matches the attribute condition exactly (`jowinjestine/f1-data-lakehouse`)
3. The IAM binding for `roles/iam.workloadIdentityUser` exists on the deploy SA
4. The `WIF_PROVIDER` and `DEPLOY_SA_EMAIL` GitHub vars are set correctly

## Cloud Run Issues

### Job execution times out

**Symptom**: Job killed after reaching timeout limit.

**Fix**: For backfill jobs, this is expected — re-execute and it resumes from checkpoint. For weekly ingest, check if FastF1 is slow to respond and consider increasing the timeout.

### Job fails with OOM (Out of Memory)

**Symptom**: Job killed with memory limit exceeded.

**Fix**: The dbt runner is configured for 2 GB; other jobs for 1 GB. If a job needs more memory, update the `memory` parameter in `terraform/modules/cloud_run_jobs/main.tf`.

## CI/CD Issues

### Secrets check false positive

**Symptom**: CI fails on "Check for secrets" step.

**Fix**: The check greps for patterns like `AKIA`, `BEGIN RSA`, `password=`. If your code legitimately contains these strings (e.g., in documentation or test fixtures), adjust the grep pattern in `.github/workflows/ci.yml`.

### dbt compile fails in CI

**Symptom**: dbt compile step fails with placeholder credentials.

**Fix**: The CI workflow uses placeholder values for `GCP_PROJECT` and `RAW_BUCKET`. If dbt models reference actual GCP resources at compile time (not just ref/source), they need to be restructured to defer resource access to runtime.
