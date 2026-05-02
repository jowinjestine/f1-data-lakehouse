terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project                     = var.project_id
  region                      = var.region
  user_project_override       = true
  billing_project             = var.project_id
}

module "storage" {
  source     = "./modules/storage"
  project_id = var.project_id
  region     = var.region
}

module "bigquery" {
  source     = "./modules/bigquery"
  project_id = var.project_id
  location   = var.bq_location
}

module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id
  raw_bucket = module.storage.raw_bucket_name
}

module "cloud_run_jobs" {
  source           = "./modules/cloud_run_jobs"
  project_id       = var.project_id
  region           = var.region
  raw_bucket       = module.storage.raw_bucket_name
  ingest_sa_email  = module.iam.ingest_sa_email
  dbt_sa_email     = module.iam.dbt_sa_email
  ar_repository_id = google_artifact_registry_repository.f1_images.repository_id

  f1tv_email_secret_id    = google_secret_manager_secret.f1tv_email.secret_id
  f1tv_password_secret_id = google_secret_manager_secret.f1tv_password.secret_id
  f1tv_token_secret_id    = google_secret_manager_secret.f1tv_token.secret_id
  use_placeholder_image   = var.use_placeholder_image
}

module "scheduler" {
  source              = "./modules/scheduler"
  project_id          = var.project_id
  region              = var.region
  scheduler_sa_email  = module.iam.scheduler_sa_email
  dispatcher_job_name = module.cloud_run_jobs.session_dispatcher_job_name
  dbt_runner_job_name = module.cloud_run_jobs.dbt_runner_job_name
}

# ── Secret Manager: F1TV credentials (values set manually via gcloud) ────────

resource "google_secret_manager_secret" "f1tv_email" {
  secret_id = "f1tv-email"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "f1tv_password" {
  secret_id = "f1tv-password"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "f1tv_token" {
  secret_id = "f1tv-token"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_artifact_registry_repository" "f1_images" {
  location      = var.region
  repository_id = "f1-lakehouse"
  format        = "DOCKER"

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"

    most_recent_versions {
      keep_count = 5
    }
  }

  cleanup_policies {
    id     = "delete-old-untagged"
    action = "DELETE"

    condition {
      tag_state  = "UNTAGGED"
      older_than = "1209600s" # 14 days
    }
  }
}
