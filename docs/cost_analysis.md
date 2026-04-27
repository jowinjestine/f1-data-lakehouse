# Cost Analysis

## Free Tier Coverage

This project is designed to run within GCP free tier under normal portfolio and demo usage.

| Service | Expected Usage | Free Tier Limit | Expected Cost |
|---------|---------------|-----------------|---------------|
| Cloud Storage | ~200 MB (us-central1 regional) | 5 GB-months in selected US regions | $0.00 |
| Cloud Run Jobs | ~52 scheduled runs/year + manual backfills | 240K vCPU-sec + 450K GiB-sec/month | $0.00 |
| BigQuery Storage | ~500 MB | 10 GiB/month | $0.00 |
| BigQuery Queries | ~10 GB/month | 1 TiB/month | $0.00 |
| Cloud Scheduler | 2 jobs (ingest + dbt) | 3 jobs/month per billing account | $0.00 |
| Artifact Registry | Container images for 4 jobs | 500 MB free | $0.00 |
| Looker Studio | Unlimited | Always free | $0.00 |

## Budget Alerts

Terraform provisions budget alerts at three thresholds:

- **$0.50** — Early warning, investigate unexpected usage
- **$1.00** — Likely repeated backfill or heavy queries
- **$5.00** — Something is wrong, pause non-essential jobs

Alerts are sent to the configured email address.

## Cost Risks

### Historical Backfills

Large backfill jobs (Jolpica: ~12,000-20,000 API calls over 27-56 hours; FastF1: seasons 2018-present) consume Cloud Run CPU/memory. A full Jolpica backfill may use significant free-tier allocation in a single month.

**Mitigation**: Run backfills in batches (per-decade). Monitor Cloud Run usage during backfill. Use `DRY_RUN=true` to test without writing data.

### BigQuery Queries

Development queries and Looker Studio dashboard refreshes consume query quota. The 1 TiB/month free tier is generous, but wide `SELECT *` queries on large tables add up.

**Mitigation**: Set `max_bytes_billed` in development profiles (1 GB default in `profiles.yml.example`). Use column-level selects. Limit dashboard auto-refresh frequency.

### Artifact Registry

Each deployment builds and pushes container images. Without cleanup, images accumulate and may exceed the 500 MB free tier.

**Mitigation**: Terraform configures cleanup policies — keep last 5 tagged images per job, delete untagged images older than 14 days.

### Cloud Scheduler

The free tier is **3 jobs per billing account** (not per project). Adding scheduler jobs to other projects on the same billing account reduces availability.

**Mitigation**: Manual backfills use `workflow_dispatch` or direct `gcloud run jobs execute`, not scheduler jobs.

## Sample Mode

Set `SAMPLE_MODE=true` on ingest jobs to limit data fetched during local development and testing. This reduces Cloud Storage writes and BigQuery scan costs during iteration.
