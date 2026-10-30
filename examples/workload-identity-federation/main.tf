locals {
  pool_project_id = coalesce(var.pool_project_id, var.project_id)

  # OIDC subjects (unique IDs) of Masthead service accounts.
  # Keys match the module's `masthead_service_accounts` input.
  masthead_subjects = {
    bigquery_sa = "110299410351654081203" # masthead-data@masthead-prod
    dataform_sa = "113640520915211463906" # masthead-dataform@masthead-prod
    dataplex_sa = "117888223789069357263" # masthead-dataplex@masthead-prod
    retro_sa    = "115289587456476335753" # retro-data@masthead-prod
  }

  # Service account per key of `google_service_account.masthead`: one shared, or one per Masthead identity.
  service_account_ids = var.separate_service_accounts ? {
    for k in keys(local.masthead_subjects) : k => "${var.service_account_id}-${replace(trimsuffix(k, "_sa"), "_", "-")}"
  } : { shared = var.service_account_id }

  service_account_key = { for k in keys(local.masthead_subjects) : k => var.separate_service_accounts ? k : "shared" }
}

resource "google_project_service" "apis" {
  for_each = var.enable_apis ? toset(["iam.googleapis.com", "iamcredentials.googleapis.com", "sts.googleapis.com"]) : toset([])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "masthead" {
  for_each = local.service_account_ids

  project      = var.project_id
  account_id   = each.value
  display_name = var.separate_service_accounts ? "Masthead Data (${each.key})" : "Masthead Data"

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool" "masthead" {
  count = var.create_pool ? 1 : 0

  project                   = local.pool_project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "Masthead Data"

  depends_on = [google_project_service.apis]
}

data "google_iam_workload_identity_pool" "masthead" {
  count = var.create_pool ? 0 : 1

  project                   = local.pool_project_id
  workload_identity_pool_id = var.pool_id
}

moved {
  from = google_iam_workload_identity_pool.masthead
  to   = google_iam_workload_identity_pool.masthead[0]
}

locals {
  pool = var.create_pool ? google_iam_workload_identity_pool.masthead[0] : data.google_iam_workload_identity_pool.masthead[0]
}

resource "google_iam_workload_identity_pool_provider" "masthead" {
  project                            = local.pool_project_id
  workload_identity_pool_id          = local.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
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

  service_account_id = google_service_account.masthead[local.service_account_key[each.key]].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${local.pool.name}/subject/${each.value}"
}

locals {
  masthead_service_accounts = { for k, sa_key in local.service_account_key : k => google_service_account.masthead[sa_key].email }
}
