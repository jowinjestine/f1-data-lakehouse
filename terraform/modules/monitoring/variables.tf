variable "project_id" {
  type = string
}

variable "alert_email" {
  type = string
}

variable "budget_amounts" {
  type = list(number)
}

variable "billing_account" {
  type = string
}
