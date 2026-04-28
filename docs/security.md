# Security

## Authentication and Authorization

### No Static Credentials

This project uses **Workload Identity Federation (WIF)** exclusively. No service account JSON keys are created, stored, or rotated.

| Context | Auth Method |
|---------|-------------|
| GitHub Actions → GCP | WIF with OIDC (GitHub token → GCP access token) |
| Cloud Run Jobs → GCS/BQ | Attached service account (runtime SA) |
| Cloud Scheduler → Cloud Run | Service account with `run.jobs.run` permission |
| Local development | `gcloud auth application-default login` (user credentials) |

### Workload Identity Federation

Terraform provisions a WIF pool and provider scoped to:

- **Pool**: `github-actions-pool`
- **Provider**: `github-provider`
- **Attribute condition**: `assertion.repository == 'jowinjestine/f1-data-lakehouse'`

Only GitHub Actions workflows running from this specific repository can impersonate the deploy service account.

### Service Accounts

| Service Account | Purpose | Key Roles |
|----------------|---------|-----------|
| `sa-f1-ingest` | Ingest + backfill Cloud Run Jobs | `storage.objectCreator`, `bigquery.dataEditor` on f1_ops |
| `sa-f1-dbt` | dbt runner Cloud Run Job | `bigquery.dataEditor`, `bigquery.jobUser`, `storage.objectViewer` |
| `sa-f1-scheduler` | Cloud Scheduler | `run.invoker` on Cloud Run Jobs |

All service accounts follow **least-privilege**: each SA has only the permissions required for its specific job.

## Data Protection

### GCS Bucket Security

- **Uniform bucket-level access**: No per-object ACLs, simplifies permission management
- **No public access**: All buckets are private by default
- **Lifecycle policy**: Raw data transitions to Nearline storage after 365 days

### BigQuery Security

- **Dataset-level access**: Controlled via IAM, not shared publicly
- **`max_bytes_billed`**: Development profiles limit query cost (1 GB default)
- **No row-level security**: Not needed for this project (no PII beyond driver names, which are public)

### Secrets

- No secrets are stored in code, environment variables, or Secret Manager
- All authentication uses WIF or attached service accounts
- CI pipeline includes a secrets check: `grep -rn "AKIA|BEGIN RSA|BEGIN PRIVATE|password=" ...`

## CI/CD Security

### Branch Protection

- PRs required for all changes to `main`
- CI checks must pass before merge (lint, test, terraform validate, dbt compile)
- Human review required (HITL AI workflow)

### Deployment Pipeline

- Terraform changes are applied only on push to `main` (after PR merge)
- Container images are built via Cloud Build (server-side, not local)
- Manual job triggers require explicit `workflow_dispatch` input

### Artifact Registry

- Cleanup policies prevent image accumulation (keep 5 tagged, delete untagged >14 days)
- Images are private to the project

## HITL AI Security Controls

AI agents in this project are **not permitted to**:

- Apply Terraform without human approval
- Trigger full historical backfill without human approval
- Change IAM/security settings without review
- Create or rotate secrets/credentials
- Merge PRs without CI passing
- Push directly to `main`

See [HITL AI Workflow](hitl_ai_workflow.md) for the complete governance framework.
