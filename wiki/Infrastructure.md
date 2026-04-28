# Infrastructure

## Terraform Modules

All infrastructure is defined as code in `terraform/` with 6 modules:

### `modules/storage`
- GCS bucket `f1-lakehouse-raw-{project_id}` in `us-central1`
- Standard storage class, uniform bucket-level access
- Lifecycle rules for cost management

### `modules/bigquery`
- 4 datasets: `f1_raw`, `f1_staging`, `f1_analytics`, `f1_ops`
- All in `US` multi-region
- Default table expiration and access controls

### `modules/iam`
- Runtime service accounts with least-privilege:
  - `sa-f1-ingest` — GCS write + BigQuery insert (ingest jobs)
  - `sa-f1-dbt` — BigQuery read/write (dbt runner)
  - `sa-f1-scheduler` — Cloud Run Job invoke (Cloud Scheduler)
- No JSON keys — Workload Identity Federation for GitHub Actions

### `modules/cloud_run_jobs`
- 4 Cloud Run Jobs with job-specific configurations
- Python 3.12 base images from Artifact Registry
- Environment variables for GCP_PROJECT, RAW_BUCKET, etc.

### `modules/scheduler`
- `f1-weekly-ingest`: Monday 8 AM UTC
- `f1-weekly-dbt`: Monday 9 AM UTC
- Uses scheduler SA for authentication

### `modules/monitoring`
- Budget alerts at $0.50, $1, $5
- Notification channel to `jjestine@myolaris.com`
- Cloud Monitoring log-based metrics for job failures

## Artifact Registry

- Repository: `f1-lakehouse` in `us-central1`
- Format: Docker
- Cleanup policies:
  - Keep last 5 images per job
  - Delete untagged images older than 14 days

## Security Model

| Principle | Implementation |
|---|---|
| No static credentials | Workload Identity Federation for CI/CD |
| Least-privilege SAs | Role-specific service accounts |
| No JSON key files | SAs attached directly to Cloud Run Jobs |
| Budget guards | Alerts at $0.50, $1, $5 |
| Query limits | `max_bytes_billed` guidance for dev queries |

## Deployment

Deploy workflow (`workflow_dispatch` only):
1. GCP auth via Workload Identity Federation
2. `terraform apply` (infrastructure changes)
3. `gcloud builds submit` (container images for each job)

Required GitHub repository variables:
- `GCP_PROJECT_ID`
- `WIF_PROVIDER` (Workload Identity Federation provider)
- `DEPLOY_SA_EMAIL`
