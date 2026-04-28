output "ingest_sa_email" {
  value = google_service_account.ingest.email
}

output "dbt_sa_email" {
  value = google_service_account.dbt.email
}

output "scheduler_sa_email" {
  value = google_service_account.scheduler.email
}

output "wif_provider_name" {
  value = google_iam_workload_identity_pool_provider.github.name
}
