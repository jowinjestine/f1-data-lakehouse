# Roadmap

## Jira Epic: SCRUM-14

**F1 Data Lakehouse — Human-in-the-Loop AI Data Engineering Project**

## Phase Delivery

| Phase | Branch | Status | PR |
|---|---|---|---|
| 0. HITL Setup | `phase-0/hitl-setup` | Done | #1 |
| 1. Foundation | `phase-1/foundation` | Done | #2 |
| 2. Thin Slice | `phase-2/thin-slice` | Done | #3 |
| 3. Full Ingestion | `phase-3/full-ingestion` | Done | #4 |
| 4. Full dbt | `phase-4/full-dbt` | Done | #5 |
| 5. Dashboard | — | To Do | — |
| 6. CI/CD + Ops | `phase-6/cicd-ops` | Done | #6 |
| 7. Polish | `phase-7/polish` | Done | #7 |
| CI Fixes | `fix/lint-and-ci-compliance` | Done | #8 |

## Jira Tasks — Original (SCRUM-31 to SCRUM-37)

| Key | Summary | Phase | Status | Priority |
|---|---|---|---|---|
| SCRUM-31 | Architecture Design and GCS Setup | 1 | Done | Must-ship |
| SCRUM-32 | Ingestion Layer | 2 | Done | Must-ship |
| SCRUM-33 | dbt Transformation Layer | 4 | Done | Must-ship |
| SCRUM-34 | Data Quality and Monitoring | 6 | Done | Nice-to-have |
| SCRUM-35 | Dashboard and Visualization | 5 | To Do | Nice-to-have |
| SCRUM-36 | Orchestration and CI/CD | 6 | Done | Must-ship |
| SCRUM-37 | Documentation and Site Integration | 7 | Done | Must-ship |

## Jira Tasks — New (SCRUM-96 to SCRUM-104)

| Key | Summary | Phase | Status | Priority |
|---|---|---|---|---|
| SCRUM-96 | Terraform State, IAM, and Secret Strategy | 1 | Done | Must-ship |
| SCRUM-97 | Testing Strategy | 3 | Done | Must-ship |
| SCRUM-98 | Jolpica Historical Backfill | 3 | Done | Must-ship |
| SCRUM-99 | Cost Optimization and Budget Guards | 1 | Done | Must-ship |
| SCRUM-100 | Ingestion Manifest and Run Logging | 2 | Done | Must-ship |
| SCRUM-101 | Source Contracts and Schema Drift | 2 | Done | Must-ship |
| SCRUM-102 | Entity Crosswalks | 4 | Done | Must-ship |
| SCRUM-103 | Data Availability and Metric Definitions | 7 | Done | Must-ship |
| SCRUM-104 | Human-in-the-Loop AI Governance | 0 | Done | Must-ship |

## Remaining Work

### Requires GCP Project Setup
1. **Terraform Deploy** — Configure WIF, set GitHub repo variables, run `terraform apply`
2. **Backfill Jolpica** — Historical data 1950-present (~30-50 hours)
3. **Backfill FastF1** — Telemetry data 2018-present
4. **dbt Full Run** — Build all staging/marts/aggregates in BigQuery

### Post-Infrastructure
5. **Looker Studio Dashboard** (SCRUM-35) — 6 dashboard pages
6. **Portfolio Site Integration** — Project card, tech badges, screenshots

### Knowledge Graph & Documentation
7. **Understand-Anything Dashboard** — Architecture analysis
8. **v1.0.0 Release** — Done (tagged 2026-04-28)

## Critical Path

```
GCP Project Setup --> Terraform Deploy --> Sample Ingest Test
    --> Jolpica Backfill --> FastF1 Backfill --> dbt Full Run
    --> Dashboard --> Portfolio Integration
```
