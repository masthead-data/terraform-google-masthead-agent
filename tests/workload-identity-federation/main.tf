# Temporary test: Carrefour-style deployment where the reader SA lives in the
# customer project and Masthead reaches it via Workload Identity Federation.
# Masthead SAs get no IAM role in the project. Not part of the module; see README.md.

terraform {
  required_version = ">= 1.5.7"

  backend "gcs" {
    bucket = "masthead-dev-tfstate"
    prefix = "terraform-google-masthead-agent/tests/workload-identity-federation"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

variable "project_id" {
  type    = string
  default = "masthead-test-client"
}

variable "pool_id" {
  type        = string
  description = "Deleted pools stay reserved for 30 days; change the suffix to re-create."
  default     = "masthead-wif-test-1"
}

variable "masthead_sa_unique_ids" {
  type        = list(string)
  description = "Unique IDs (OIDC sub claim) of Masthead SAs allowed to federate"
  default = [
    "110299410351654081203", # masthead-data@masthead-prod
    "113640520915211463906", # masthead-dataform@masthead-prod
    "117888223789069357263", # masthead-dataplex@masthead-prod
    "115289587456476335753", # retro-data@masthead-prod
  ]
}

provider "google" {
  project = var.project_id
}

resource "google_project_service" "apis" {
  for_each = toset(["iam.googleapis.com", "iamcredentials.googleapis.com", "sts.googleapis.com"])

  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "reader" {
  account_id   = "masthead-wif-test"
  display_name = "Masthead WIF test"

  depends_on = [google_project_service.apis]
}

resource "google_project_iam_member" "reader_metadata_viewer" {
  project = var.project_id
  role    = "roles/bigquery.metadataViewer"
  member  = google_service_account.reader.member
}

resource "google_iam_workload_identity_pool" "masthead" {
  workload_identity_pool_id = var.pool_id
  display_name              = "Masthead WIF test"

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "google" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.masthead.workload_identity_pool_id
  workload_identity_pool_provider_id = "masthead-google"
  display_name                       = "Masthead (Google OIDC)"

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  attribute_condition = "assertion.sub in ${jsonencode(var.masthead_sa_unique_ids)}"

  oidc {
    issuer_uri = "https://accounts.google.com"
  }
}

resource "google_service_account_iam_member" "masthead_workload_user" {
  for_each = toset(var.masthead_sa_unique_ids)

  service_account_id = google_service_account.reader.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.masthead.name}/subject/${each.value}"
}

output "reader_sa_email" {
  value = google_service_account.reader.email
}

output "provider_audience" {
  description = "STS audience; the ID token audience is the same value prefixed with https:"
  value       = "//iam.googleapis.com/${google_iam_workload_identity_pool_provider.google.name}"
}
