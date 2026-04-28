# CI/CD

## CI Pipeline (`.github/workflows/ci.yml`)

Runs on every pull request to `main`. All 3 jobs must pass before merge.

### Job: `lint-and-test`

| Step | Tool | What It Checks |
|---|---|---|
| Install dependencies | `pip install -e ".[dev]"` | Package installs cleanly |
| Lint | `ruff check .` | Code quality (E, F, I, N, W, UP, B, SIM rules) |
| Format | `ruff format --check .` | Consistent code formatting |
| Unit tests | `pytest tests/unit/ -v --tb=short` | 13 unit tests pass |
| Secrets check | `grep` for AKIA, RSA keys, passwords | No credentials committed |

### Job: `terraform-validate`

| Step | Tool | What It Checks |
|---|---|---|
| Terraform init | `terraform init -backend=false` | Provider resolution |
| Terraform validate | `terraform validate` | HCL syntax and config validity |

Uses Terraform 1.12.0 (upgraded from 1.6.0 due to expired HashiCorp GPG key).

### Job: `dbt-compile`

| Step | Tool | What It Checks |
|---|---|---|
| Install dbt | `pip install dbt-core dbt-bigquery` | dbt installs cleanly |
| Create profiles | printf to `~/.dbt/profiles.yml` | CI-only profile with placeholder project |
| dbt deps | `dbt deps` | dbt packages resolve (dbt_utils, dbt_external_tables) |
| dbt parse | `dbt parse --target dev` | SQL/YAML syntax valid, no broken refs |

**Note:** Uses `dbt parse` instead of `dbt compile` because dbt-bigquery adapter requires GCP credentials even for compilation.

## CD Pipeline (`.github/workflows/deploy.yml`)

Triggered via `workflow_dispatch` only (manual). Requires GCP infrastructure to be configured first.

### Full Deploy Flow

1. Authenticate via Workload Identity Federation
2. `terraform apply -auto-approve`
3. Build and push Docker images for each job:
   - `ingest-recent`
   - `backfill-jolpica`
   - `dbt-runner`

### Manual Job Trigger

Can trigger individual Cloud Run Jobs via `workflow_dispatch` with `job_to_run` input:
- `backfill_jolpica`
- `backfill_fastf1`

## Required Repository Configuration

### Variables (Settings > Secrets and variables > Variables)

| Variable | Example | Purpose |
|---|---|---|
| `GCP_PROJECT_ID` | `my-f1-project` | GCP project ID |
| `WIF_PROVIDER` | `projects/123/locations/global/...` | Workload Identity Federation provider |
| `DEPLOY_SA_EMAIL` | `sa-deploy@project.iam.gserviceaccount.com` | Deploy service account |

### Environment

Create a `production` environment with deployment protection rules for manual approval.
