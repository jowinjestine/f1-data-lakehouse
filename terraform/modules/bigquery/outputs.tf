output "raw_dataset_id" {
  value = google_bigquery_dataset.raw.dataset_id
}

output "staging_dataset_id" {
  value = google_bigquery_dataset.staging.dataset_id
}

output "analytics_dataset_id" {
  value = google_bigquery_dataset.analytics.dataset_id
}

output "ops_dataset_id" {
  value = google_bigquery_dataset.ops.dataset_id
}

output "streaming_dataset_id" {
  value = google_bigquery_dataset.streaming.dataset_id
}
