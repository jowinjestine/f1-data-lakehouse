locals {
  placeholder_image = "gcr.io/cloudrun/hello:latest"
  ar_base           = "${var.region}-docker.pkg.dev/${var.project_id}/${var.ar_repository_id}"
}

# ── OpenF1 live ingestor ──────────────────────────────────────────────────────
# Streams live F1 timing data to BigQuery during sessions.
# Triggered by session-dispatcher before each session.

resource "google_cloud_run_v2_job" "openf1_live" {
  name     = "openf1-live"
  location = var.region
  project  = var.project_id

  template {
    template {
      containers {
        image = var.use_placeholder_image ? local.placeholder_image : "${local.ar_base}/openf1:latest"

        env {
          name  = "ROLE"
          value = "ingest-realtime"
        }
        env {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "OPENF1_BQ_DATASET"
          value = "f1_streaming"
        }
        env {
          name = "F1TV_EMAIL"
          value_source {
            secret_key_ref {
              secret  = var.f1tv_email_secret_id
              version = "latest"
            }
          }
        }
        env {
          name = "F1TV_PASSWORD"
          value_source {
            secret_key_ref {
              secret  = var.f1tv_password_secret_id
              version = "latest"
            }
          }
        }
        env {
          name = "F1_TOKEN"
          value_source {
            secret_key_ref {
              secret  = var.f1tv_token_secret_id
              version = "latest"
            }
          }
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "2Gi"
          }
        }
      }

      timeout         = "21600s" # 6 hours
      max_retries     = 1
      service_account = var.ingest_sa_email
    }

    task_count = 1
  }
}

# ── OpenF1 historical ingestor ────────────────────────────────────────────────
# Backfills past seasons from livetiming.formula1.com into BigQuery.
# Triggered manually or by session-dispatcher for catch-up.

resource "google_cloud_run_v2_job" "openf1_historical" {
  name     = "openf1-historical"
  location = var.region
  project  = var.project_id

  template {
    template {
      containers {
        image = var.use_placeholder_image ? local.placeholder_image : "${local.ar_base}/openf1:latest"

        env {
          name  = "ROLE"
          value = "ingest-historical"
        }
        env {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "OPENF1_BQ_DATASET"
          value = "f1_streaming"
        }

        resources {
          limits = {
            cpu    = "4"
            memory = "8Gi"
          }
        }
      }

      timeout         = "21600s" # 6 hours
      max_retries     = 0
      service_account = var.ingest_sa_email
    }

    task_count = 1
  }
}

# ── Parquet exporter ──────────────────────────────────────────────────────────
# Exports BigQuery streaming tables to GCS Parquet post-session via EXPORT DATA.

resource "google_cloud_run_v2_job" "parquet_exporter" {
  name     = "f1-parquet-exporter"
  location = var.region
  project  = var.project_id

  template {
    template {
      containers {
        image = var.use_placeholder_image ? local.placeholder_image : "${local.ar_base}/parquet-exporter:latest"

        env {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "RAW_BUCKET"
          value = var.raw_bucket
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }
      }

      timeout         = "1800s" # 30 minutes
      max_retries     = 1
      service_account = var.ingest_sa_email
    }

    task_count = 1
  }
}

# ── Session dispatcher ────────────────────────────────────────────────────────
# Runs daily via Cloud Scheduler. Checks F1 calendar, triggers live ingestor
# before sessions, triggers parquet-exporter + dbt after sessions.

resource "google_cloud_run_v2_job" "session_dispatcher" {
  name     = "f1-session-dispatcher"
  location = var.region
  project  = var.project_id

  template {
    template {
      containers {
        image = var.use_placeholder_image ? local.placeholder_image : "${local.ar_base}/session-dispatcher:latest"

        env {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "REGION"
          value = var.region
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
      }

      timeout         = "300s" # 5 minutes
      max_retries     = 1
      service_account = var.ingest_sa_email
    }

    task_count = 1
  }
}

# ── dbt runner (unchanged) ────────────────────────────────────────────────────

resource "google_cloud_run_v2_job" "dbt_runner" {
  name     = "f1-dbt-runner"
  location = var.region
  project  = var.project_id

  template {
    template {
      containers {
        image = var.use_placeholder_image ? local.placeholder_image : "${local.ar_base}/dbt-runner:latest"

        env {
          name  = "GCP_PROJECT"
          value = var.project_id
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "2Gi"
          }
        }
      }

      timeout         = "3600s"
      max_retries     = 1
      service_account = var.dbt_sa_email
    }

    task_count = 1
  }
}
