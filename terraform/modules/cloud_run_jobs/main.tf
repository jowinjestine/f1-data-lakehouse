locals {
  placeholder_image = "gcr.io/cloudrun/hello:latest"
  ar_base           = "${var.region}-docker.pkg.dev/${var.project_id}/${var.ar_repository_id}"
}

resource "google_cloud_run_v2_job" "ingest_recent" {
  name     = "f1-ingest-recent"
  location = var.region
  project  = var.project_id

  template {
    template {
      containers {
        image = var.use_placeholder_image ? local.placeholder_image : "${local.ar_base}/ingest-recent:latest"

        env {
          name  = "GCP_PROJECT"
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

      timeout         = "1800s"
      max_retries     = 1
      service_account = var.ingest_sa_email
    }

    task_count = 1
  }
}

resource "google_cloud_run_v2_job" "backfill_jolpica" {
  name     = "f1-backfill-jolpica"
  location = var.region
  project  = var.project_id

  template {
    template {
      containers {
        image = var.use_placeholder_image ? local.placeholder_image : "${local.ar_base}/backfill-jolpica:latest"

        env {
          name  = "GCP_PROJECT"
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

      timeout         = "21600s" # 6 hours
      max_retries     = 0
      service_account = var.ingest_sa_email
    }

    task_count = 1
  }
}

resource "google_cloud_run_v2_job" "backfill_fastf1" {
  name     = "f1-backfill-fastf1"
  location = var.region
  project  = var.project_id

  template {
    template {
      containers {
        image = var.use_placeholder_image ? local.placeholder_image : "${local.ar_base}/backfill-fastf1:latest"

        env {
          name  = "GCP_PROJECT"
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

      timeout         = "21600s" # 6 hours
      max_retries     = 0
      service_account = var.ingest_sa_email
    }

    task_count = 1
  }
}

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
