resource "google_bigquery_dataset" "raw" {
  dataset_id = "f1_raw"
  project    = var.project_id
  location   = var.location

  description = "External tables over raw GCS Parquet files"
}

resource "google_bigquery_dataset" "staging" {
  dataset_id = "f1_staging"
  project    = var.project_id
  location   = var.location

  description = "Cleaned source-level dbt views"
}

resource "google_bigquery_dataset" "analytics" {
  dataset_id = "f1_analytics"
  project    = var.project_id
  location   = var.location

  description = "Dashboard-ready dimensional models and aggregates"
}

resource "google_bigquery_dataset" "ops" {
  dataset_id = "f1_ops"
  project    = var.project_id
  location   = var.location

  description = "Operational metadata: ingest runs, manifests, checkpoints, data quality"
}
