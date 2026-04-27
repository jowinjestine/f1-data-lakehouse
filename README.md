# F1 Data Lakehouse

A production-grade F1 data lakehouse on GCP, built as a **Human-in-the-Loop AI** project. AI agents generate code, Terraform, dbt models, tests, and documentation. A human reviewer controls architecture decisions, security, quality gates, and deployment approval.

## Architecture

```
FastF1 SDK (2018+)              Jolpica F1 API (1950+)
       │                                │
Cloud Run Job: ingest_recent    Cloud Run Job: backfill_jolpica
       │                                │
       └──── Schema Validation ─────────┘
                     │
         GCS Raw Immutable Parquet
          (Hive-partitioned, Snappy)
                     │
         BigQuery f1_raw (external tables)
                     │
         dbt staging views (f1_staging)
                     │
         dbt marts + aggregates (f1_analytics)
                     │
           Looker Studio Dashboards
```

**Supporting infrastructure**: f1_ops dataset (ingest runs, checkpoints, data quality), Terraform IaC, GitHub Actions CI/CD, Workload Identity Federation (no JSON keys).

## Data Sources

| Source | Coverage | Data Types |
|--------|----------|------------|
| **FastF1** (Python SDK) | 2018-present | Lap times, telemetry, weather, session results |
| **Jolpica F1 API** (Ergast successor) | 1950-present | Race results, standings, qualifying, pit stops, circuits, drivers, constructors |

Entity resolution across sources uses crosswalk seed files (`dbt/seeds/`) for drivers, constructors, and circuits.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Compute | Cloud Run Jobs (Python 3.12) |
| Storage | Cloud Storage (us-central1, Parquet) |
| Warehouse | BigQuery (US multi-region) |
| Transform | dbt-core 1.8+ with dbt-external-tables |
| IaC | Terraform 1.6 |
| CI/CD | GitHub Actions + Workload Identity Federation |
| Orchestration | Cloud Scheduler (2 weekly jobs) |
| Visualization | Looker Studio |
| Auth | Workload Identity Federation (no static keys) |

## Project Structure

```
├── terraform/          # GCP infrastructure (6 modules)
├── jobs/
│   ├── ingest_recent/  # Weekly ingestion (FastF1 + Jolpica)
│   ├── backfill_jolpica/  # Historical backfill 1950-present
│   ├── backfill_fastf1/   # FastF1 backfill 2018-present
│   └── dbt_runner/     # dbt pipeline runner
├── dbt/
│   ├── models/
│   │   ├── staging/    # Source-level cleaning (FastF1 + Jolpica)
│   │   ├── marts/      # Dimensions, facts, aggregates
│   │   └── ops/        # Operational metadata models
│   ├── seeds/          # Crosswalk CSVs for entity resolution
│   └── tests/          # Custom data quality tests
├── contracts/          # YAML schema definitions per dataset
├── tests/              # Python unit + integration tests
├── docs/               # Architecture, runbooks, metric definitions
└── .github/workflows/  # CI + CD pipelines
```

## Quickstart

### Prerequisites

- Python 3.12+
- GCP project with billing enabled
- Terraform 1.6+
- dbt-core 1.8+

### Local Development

```bash
# Install dependencies
make install

# Lint and format
make lint
make fmt

# Run unit tests
make test-unit

# Validate Terraform
make validate

# Compile dbt (requires GCP_PROJECT and RAW_BUCKET env vars)
make dbt-compile
```

### Deployment

1. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and fill in values
2. Run `terraform init && terraform apply` from `terraform/`
3. Push to `main` to trigger the GitHub Actions CD pipeline
4. Use `workflow_dispatch` to manually trigger backfill jobs

## BigQuery Datasets

| Dataset | Purpose | Materialization |
|---------|---------|-----------------|
| `f1_raw` | External tables over GCS Parquet | External |
| `f1_staging` | Cleaned source-level models | Views |
| `f1_analytics` | Dashboard-ready dimensional models | Tables |
| `f1_ops` | Ingest runs, checkpoints, data quality | Tables |

## Data Quality

- **Schema contracts**: YAML definitions validate data before Parquet writes; invalid payloads go to quarantine
- **dbt tests**: not_null, unique, relationships, accepted_values on all models
- **Custom tests**: lap times positive, no orphan laps, standings monotonic
- **Source freshness**: warn at 14 days, error at 30 days
- **Deduplication**: `latest_successful_objects` view filters to current-truth raw files

## Cost

Designed to run within GCP free tier under normal portfolio/demo usage. Budget alerts at $0.50, $1, and $5. See [docs/cost_analysis.md](docs/cost_analysis.md) for details.

## Documentation

- [Architecture](docs/architecture.md) — System design, data flow, location decisions
- [HITL AI Workflow](docs/hitl_ai_workflow.md) — Human/AI roles, review gates, checklists
- [Cost Analysis](docs/cost_analysis.md) — Free tier breakdown, budget guards
- [Data Availability](docs/data_availability.md) — What data exists by year and source
- [Metric Definitions](docs/metric_definitions.md) — Calculated metrics and their formulas
- [Era Normalization](docs/era_normalization.md) — Cross-era comparison methodology
- [Backfill Runbook](docs/backfill_runbook.md) — How to run and resume historical backfills
- [Security](docs/security.md) — IAM, WIF, least-privilege design
- [Troubleshooting](docs/troubleshooting.md) — Common issues and fixes

## Human-in-the-Loop AI

This project was built using a HITL AI delivery model across 7 phases, each with human review gates. AI agents generated all code, infrastructure, and documentation. Human reviewers controlled architecture decisions, security, quality gates, and deployment. See [docs/hitl_ai_workflow.md](docs/hitl_ai_workflow.md) for the full governance framework.

## License

Private project. All rights reserved.
