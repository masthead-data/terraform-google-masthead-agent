# Temporary test of docs/workload-identity-federation.md step 1 in masthead-test-client.
# Below the backend config, the code matches the doc except for the service
# account and pool IDs. Step 2 (module with masthead_service_accounts) is
# sandbox/terraform/masthead.tf. See README.md.

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

provider "google" {
  project = var.project_id
}

locals {
  # OIDC subjects (unique IDs) of Masthead service accounts.
  # Keys match the module's `masthead_service_accounts` input.
  masthead_subjects = {
    bigquery_sa = "110299410351654081203" # masthead-data@masthead-prod
    dataform_sa = "113640520915211463906" # masthead-dataform@masthead-prod
    dataplex_sa = "117888223789069357263" # masthead-dataplex@masthead-prod
    retro_sa    = "115289587456476335753" # retro-data@masthead-prod
  }
}

resource "google_project_service" "apis" {
  for_each = toset(["iam.googleapis.com", "iamcredentials.googleapis.com", "sts.googleapis.com"])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "masthead" {
  project      = var.project_id
  account_id   = "masthead-wif-test"
  display_name = "Masthead Data"

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool" "masthead" {
  project                   = var.project_id
  workload_identity_pool_id = "masthead-wif-test-1"
  display_name              = "Masthead Data"

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "masthead" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.masthead.workload_identity_pool_id
  workload_identity_pool_provider_id = "masthead-google"
  display_name                       = "Masthead Data (Google)"

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  attribute_condition = "assertion.sub in ${jsonencode(values(local.masthead_subjects))}"

  oidc {
    issuer_uri = "https://accounts.google.com"
  }
}

resource "google_service_account_iam_member" "masthead_workload_user" {
  for_each = local.masthead_subjects

  service_account_id = google_service_account.masthead.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.masthead.name}/subject/${each.value}"
}

locals {
  masthead_service_accounts = { for k in keys(local.masthead_subjects) : k => google_service_account.masthead.email }
}

output "masthead_federation" {
  description = "Federation details to share with Masthead"
  value = {
    provider         = "//iam.googleapis.com/${google_iam_workload_identity_pool_provider.masthead.name}"
    service_accounts = local.masthead_service_accounts
  }
}
