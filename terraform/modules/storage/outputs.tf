output "raw_bucket_name" {
  value = google_storage_bucket.raw.name
}

output "functions_bucket_name" {
  value = google_storage_bucket.functions.name
}
