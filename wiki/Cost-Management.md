# Cost Management

## Free Tier Target

The project is designed to run within GCP free tier under normal portfolio/demo usage.

| Service | Expected Usage | Free Tier | Expected Cost |
|---|---|---|---|
| Cloud Storage | ~200 MB (us-central1) | 5 GB-months regional | $0.00 |
| Cloud Run Jobs | ~52 runs/year + backfills | 240K vCPU-sec/month | $0.00 |
| BigQuery Storage | ~500 MB | 10 GiB/month | $0.00 |
| BigQuery Queries | ~10 GB/month | 1 TiB/month | $0.00 |
| Cloud Scheduler | 2 jobs | 3 jobs/month per billing account | $0.00 |
| Artifact Registry | Container images x4 | 500 MB free | $0.00 |
| Looker Studio | Unlimited | Always free | $0.00 |

## Budget Alerts

Terraform-managed alerts at three thresholds:
- **$0.50** — Early warning
- **$1.00** — Investigate usage
- **$5.00** — Immediate action required

Notifications sent to: `jjestine@myolaris.com`

## Cost Risks

| Risk | Mitigation |
|---|---|
| Large historical backfills | Monitor Cloud Run CPU/RAM during backfill, use dry-run first |
| Repeated backfills | Checkpointing prevents re-processing completed data |
| Heavy BigQuery queries | `max_bytes_billed` guardrail in dev profile (1 GB) |
| Artifact Registry bloat | Cleanup policy: keep 5 images, delete untagged >14 days |
| Extra scheduler jobs | Free tier is 3 jobs/month per billing account — don't add more |
| Looker Studio refreshes | Dashboard auto-refresh can trigger BigQuery queries — use scheduled refresh |

## Optimization Tips

- Use `--target dev` with `max_bytes_billed` for ad-hoc BigQuery queries
- Run backfills during off-peak hours
- Use `SAMPLE_MODE=true` for local development (processes only first event)
- Avoid creating additional Cloud Scheduler jobs beyond the 3 free tier limit
- Manual backfill should use `workflow_dispatch`, not permanent scheduler jobs
