resource "google_cloud_scheduler_job" "session_dispatcher" {
  name      = "f1-session-dispatcher"
  schedule  = "*/30 * * * *"
  time_zone = "UTC"
  project   = var.project_id
  region    = var.region

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${var.dispatcher_job_name}:run"

    oauth_token {
      service_account_email = var.scheduler_sa_email
    }
  }
}

resource "google_cloud_scheduler_job" "weekly_dbt" {
  name      = "f1-weekly-dbt"
  schedule  = "0 9 * * 1"
  time_zone = "UTC"
  project   = var.project_id
  region    = var.region

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${var.dbt_runner_job_name}:run"

    oauth_token {
      service_account_email = var.scheduler_sa_email
    }
  }
}
