output "raw_bucket_name" {
  description = "GCS bucket for raw immutable Parquet files"
  value       = module.storage.raw_bucket_name
}

output "ingest_sa_email" {
  description = "Service account for ingestion jobs"
  value       = module.iam.ingest_sa_email
}

output "dbt_sa_email" {
  description = "Service account for dbt runner"
  value       = module.iam.dbt_sa_email
}

output "artifact_registry_url" {
  description = "Artifact Registry URL for Docker images"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.f1_images.repository_id}"
}
