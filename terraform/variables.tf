variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Run, GCS, and Artifact Registry"
  type        = string
  default     = "us-central1"
}

variable "bq_location" {
  description = "BigQuery dataset location (multi-region)"
  type        = string
  default     = "US"
}

variable "alert_email" {
  description = "Email address for budget and monitoring alerts"
  type        = string
  default     = "jjestine@myolaris.com"
}

variable "billing_account" {
  description = "GCP billing account ID"
  type        = string
}

variable "budget_amounts" {
  description = "Budget alert thresholds in USD"
  type        = list(number)
  default     = [0.50, 1.00, 5.00]
}

variable "github_repo" {
  description = "GitHub repository for Workload Identity Federation (owner/repo)"
  type        = string
  default     = "jowinjestine/f1-data-lakehouse"
}
