variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "raw_bucket" {
  type = string
}

variable "ingest_sa_email" {
  type = string
}

variable "dbt_sa_email" {
  type = string
}

variable "ar_repository_id" {
  type = string
}

variable "use_placeholder_image" {
  type    = bool
  default = true
}

variable "f1tv_email_secret_id" {
  type = string
}

variable "f1tv_password_secret_id" {
  type = string
}

variable "f1tv_token_secret_id" {
  type = string
}
