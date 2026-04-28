# F1 Data Lakehouse Wiki

Welcome to the **F1 Data Lakehouse** project wiki — a Human-in-the-Loop AI data engineering project building a production-style F1 data lakehouse on GCP.

## Quick Navigation

| Section | Description |
|---|---|
| [Architecture](Architecture) | System design, data flow, and technology stack |
| [Data Sources](Data-Sources) | FastF1 SDK and Jolpica F1 API details |
| [Pipeline Overview](Pipeline-Overview) | Ingestion, transformation, and serving layers |
| [dbt Models](dbt-Models) | Staging, marts, aggregates, and crosswalks |
| [Infrastructure](Infrastructure) | Terraform modules, IAM, and GCP resources |
| [CI/CD](CI-CD) | GitHub Actions workflows and deployment |
| [Data Quality](Data-Quality) | Schema contracts, validation, and monitoring |
| [Backfill Guide](Backfill-Guide) | Historical data backfill procedures |
| [Cost Management](Cost-Management) | Budget alerts, free tier targets, and optimization |
| [HITL AI Workflow](HITL-AI-Workflow) | Human-in-the-Loop AI development process |
| [Roadmap](Roadmap) | Project phases, Jira tasks, and delivery status |
| [Troubleshooting](Troubleshooting) | Common issues and solutions |

## Project Status

- **v1.0.0 Released** — All code phases complete, CI green, merged to main
- **15/16 Jira tasks Done** — SCRUM-35 (Dashboard) deferred until data flows
- **Next**: GCP infrastructure deployment, backfills, Looker Studio dashboard

## Repository

- **GitHub**: [jowinjestine/f1-data-lakehouse](https://github.com/jowinjestine/f1-data-lakehouse)
- **Jira Epic**: SCRUM-14
- **Tech Stack**: Python 3.12 | dbt-core 1.8+ | Terraform 1.12 | BigQuery | Cloud Run Jobs | GCS
