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

variable "github_repo" {
  description = "GitHub repository for Workload Identity Federation (owner/repo)"
  type        = string
  default     = "jowinjestine/f1-data-lakehouse"
}

variable "use_placeholder_image" {
  description = "Use placeholder Cloud Run images (true for initial deploy before images are built)"
  type        = bool
  default     = false
}
