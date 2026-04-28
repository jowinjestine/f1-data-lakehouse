resource "google_service_account" "ingest" {
  account_id   = "sa-f1-ingest"
  display_name = "F1 Lakehouse Ingestion SA"
  project      = var.project_id
}

resource "google_service_account" "dbt" {
  account_id   = "sa-f1-dbt"
  display_name = "F1 Lakehouse dbt Runner SA"
  project      = var.project_id
}

resource "google_service_account" "scheduler" {
  account_id   = "sa-f1-scheduler"
  display_name = "F1 Lakehouse Scheduler SA"
  project      = var.project_id
}

# Ingest SA: write to GCS raw bucket
resource "google_storage_bucket_iam_member" "ingest_raw_writer" {
  bucket = var.raw_bucket
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.ingest.email}"
}

# Ingest SA: read from GCS (for checkpointing)
resource "google_storage_bucket_iam_member" "ingest_raw_reader" {
  bucket = var.raw_bucket
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.ingest.email}"
}

# Ingest SA: write to f1_ops dataset
resource "google_project_iam_member" "ingest_bq_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.ingest.email}"
}

resource "google_project_iam_member" "ingest_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.ingest.email}"
}

# dbt SA: BigQuery access
resource "google_project_iam_member" "dbt_bq_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.dbt.email}"
}

resource "google_project_iam_member" "dbt_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dbt.email}"
}

# dbt SA: read GCS for external tables
resource "google_storage_bucket_iam_member" "dbt_raw_reader" {
  bucket = var.raw_bucket
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.dbt.email}"
}

# Scheduler SA: invoke Cloud Run Jobs
resource "google_project_iam_member" "scheduler_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.scheduler.email}"
}

# Workload Identity Federation for GitHub Actions
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-pool"
  project                   = var.project_id
  display_name              = "GitHub Actions Pool"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  project                            = var.project_id
  display_name                       = "GitHub Actions Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow GitHub Actions to impersonate the ingest SA
resource "google_service_account_iam_member" "github_ingest" {
  service_account_id = google_service_account.ingest.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

# Allow GitHub Actions to impersonate the dbt SA
resource "google_service_account_iam_member" "github_dbt" {
  service_account_id = google_service_account.dbt.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}
