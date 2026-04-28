# Uncomment after creating the state bucket:
#   gsutil mb -p <PROJECT_ID> -l us-central1 gs://<PROJECT_ID>-tf-state
#   gsutil versioning set on gs://<PROJECT_ID>-tf-state

# terraform {
#   backend "gcs" {
#     bucket = "<PROJECT_ID>-tf-state"
#     prefix = "f1-lakehouse"
#   }
# }
