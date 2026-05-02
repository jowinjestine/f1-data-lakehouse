resource "google_billing_budget" "f1_lakehouse" {
  billing_account = var.billing_account
  display_name    = "F1 Data Lakehouse Budget"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(max(var.budget_amounts...))
    }
  }

  dynamic "threshold_rules" {
    for_each = var.budget_amounts
    content {
      threshold_percent = threshold_rules.value / max(var.budget_amounts...)
      spend_basis       = "CURRENT_SPEND"
    }
  }

  all_updates_rule {
    monitoring_notification_channels = [
      google_monitoring_notification_channel.email.name
    ]
  }
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "F1 Lakehouse Alert Email"
  type         = "email"
  project      = var.project_id

  labels = {
    email_address = var.alert_email
  }
}

resource "google_logging_metric" "cloud_run_job_failures" {
  name    = "f1-cloud-run-job-failures"
  project = var.project_id
  filter  = "resource.type=\"cloud_run_job\" AND severity>=ERROR"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "time_sleep" "wait_for_metric" {
  depends_on      = [google_logging_metric.cloud_run_job_failures]
  create_duration = "60s"
}

resource "google_monitoring_alert_policy" "job_failure" {
  depends_on   = [time_sleep.wait_for_metric]
  display_name = "F1 Cloud Run Job Failure"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run Job Error Logs"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.cloud_run_job_failures.name}\" AND resource.type=\"cloud_run_job\""
      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.name
  ]
}
