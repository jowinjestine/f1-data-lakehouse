output "session_dispatcher_job_name" {
  value = google_cloud_run_v2_job.session_dispatcher.name
}

output "dbt_runner_job_name" {
  value = google_cloud_run_v2_job.dbt_runner.name
}

output "openf1_live_job_name" {
  value = google_cloud_run_v2_job.openf1_live.name
}

output "openf1_historical_job_name" {
  value = google_cloud_run_v2_job.openf1_historical.name
}

output "parquet_exporter_job_name" {
  value = google_cloud_run_v2_job.parquet_exporter.name
}
