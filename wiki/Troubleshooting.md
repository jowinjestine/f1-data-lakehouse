# Troubleshooting

## CI Pipeline Issues

### `dbt compile` fails with "Failed to authenticate"
**Cause:** dbt-bigquery adapter requires GCP credentials even for `dbt compile`.
**Fix:** Use `dbt parse` instead in CI. Already fixed in ci.yml.

### Secrets check fails (self-match)
**Cause:** The grep pattern in ci.yml matches the ci.yml file itself.
**Fix:** Add `--exclude-dir=.github` to the grep command.

### Terraform "openpgp: key expired"
**Cause:** Older Terraform versions (< 1.10) have stale HashiCorp GPG key bundles.
**Fix:** Use Terraform >= 1.10. Currently pinned to 1.12.0.

### `pip install -e ".[dev]"` — "Multiple top-level packages discovered"
**Cause:** setuptools auto-discovers all top-level directories as packages.
**Fix:** Add `[tool.setuptools.packages.find] include = ["jobs*"]` to pyproject.toml.

### `dbt-external-tables` not found on pip
**Cause:** It's a dbt package (installed via `dbt deps`), not a pip package.
**Fix:** Only `pip install dbt-core dbt-bigquery`. dbt packages come from `packages.yml`.

## Deploy Workflow Issues

### "workload_identity_provider" not specified
**Cause:** GitHub repository variables not configured yet.
**Fix:** Set `GCP_PROJECT_ID`, `WIF_PROVIDER`, and `DEPLOY_SA_EMAIL` in repo Settings > Variables.

### Deploy runs on every push to main
**Cause:** Original deploy.yml triggered on `push` to main.
**Fix:** Changed to `workflow_dispatch` only until GCP is configured.

## Local Development Issues

### FastF1 cache errors
**Cause:** FastF1 caches data to disk. Corrupted cache causes failures.
**Fix:** Delete the cache directory (`~/.cache/fastf1` or `/tmp/fastf1_cache`).

### Jolpica rate limiting (429 errors)
**Cause:** Too many API requests in a short period.
**Fix:** Increase `JOLPICA_RATE_LIMIT_SECONDS` (default 8s, try 12-15s).

### Backfill interrupted / incomplete
**Cause:** Job timed out or was manually stopped.
**Fix:** Re-run the backfill — it will resume from the last checkpoint automatically.

## BigQuery Issues

### "Dataset not found" errors
**Cause:** Terraform hasn't been applied yet.
**Fix:** Run `terraform apply` to create the BQ datasets.

### External table reads show duplicates
**Cause:** Multiple ingest_run_ids exist for the same data slice.
**Fix:** Ensure dbt staging models filter via `latest_successful_objects` table.

### Query costs unexpectedly high
**Cause:** Full table scans on large external tables.
**Fix:** Use partition filters (year, round) and `max_bytes_billed` in dev profile.
