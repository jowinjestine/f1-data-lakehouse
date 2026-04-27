output "ingest_job_name" {
  value = google_cloud_run_v2_job.ingest_recent.name
}

output "dbt_runner_job_name" {
  value = google_cloud_run_v2_job.dbt_runner.name
}

output "backfill_jolpica_job_name" {
  value = google_cloud_run_v2_job.backfill_jolpica.name
}

output "backfill_fastf1_job_name" {
  value = google_cloud_run_v2_job.backfill_fastf1.name
}
