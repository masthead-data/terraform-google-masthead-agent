# Dataplex Module - IAM and Logging for Masthead Agent
# Supports both folder-level (organization) and project-level (project) configurations

locals {
  resource_names = {
    topic        = "masthead-dataplex-topic"
    subscription = "masthead-dataplex-subscription"
    sink         = "masthead-dataplex-sink"
  }

  # Merge default labels with user-provided labels
  common_labels = merge(var.labels, {
    component = "dataplex"
  })

  # Log filter for Dataplex monitoring
  dataplex_log_filter = <<-EOT
(
  jsonPayload.@type="type.googleapis.com/google.cloud.dataplex.v1.DataScanEvent" OR
  protoPayload.methodName="google.cloud.dataplex.v1.DataScanService.CreateDataScan" OR
  protoPayload.methodName="google.cloud.dataplex.v1.DataScanService.UpdateDataScan" OR
  protoPayload.methodName="google.cloud.dataplex.v1.DataScanService.DeleteDataScan"
) AND (
  severity="INFO" OR
  severity="NOTICE"
)
EOT

  # Determine if we're operating at folder or project level
  has_folders = length(var.monitored_folder_ids) > 0

  # Projects where IAM bindings need to be applied (only when not using folders)
  iam_target_projects = local.has_folders ? [] : var.monitored_project_ids

# Grant Masthead service account required Dataplex roles
resource "google_project_iam_member" "masthead_dataplex_roles" {
  for_each = var.enable_datascan_editing ? toset([
    "roles/dataplex.dataProductsViewer",
    "roles/dataplex.dataScanEditor",
    "roles/bigquery.jobUser",
    "roles/dataplex.storageDataReader"
    ]) : toset([
    "roles/dataplex.dataProductsViewer",
    "roles/dataplex.dataScanDataViewer"
  ])
}

# Enable Dataplex and BigQuery APIs in monitored projects
resource "google_project_service" "dataplex_apis" {
  for_each = var.enable_apis ? toset(flatten([
    for project_id in var.monitored_project_ids : [
      "${project_id}:dataplex.googleapis.com",
      "${project_id}:bigquery.googleapis.com"
    ]
  ])) : toset([])

  project = split(":", each.value)[0]
  service = split(":", each.value)[1]

  disable_on_destroy         = false
  disable_dependent_services = false
}

# Shared Logging Infrastructure (Pub/Sub + Sinks)
module "logging_infrastructure" {
  source = "../logging-infrastructure"

  pubsub_project_id        = var.pubsub_project_id
  monitored_folder_ids     = var.monitored_folder_ids
  monitored_project_ids    = var.monitored_project_ids
  component_name           = "dataplex"
  topic_name               = local.resource_names.topic
  subscription_name        = local.resource_names.subscription
  sink_name                = local.resource_names.sink
  log_filter               = local.dataplex_log_filter
  masthead_service_account = var.masthead_service_accounts.dataplex_sa
  enable_apis              = var.enable_apis
  labels                   = local.common_labels
}

# IAM: Grant Masthead service account required Dataplex roles at folder level
resource "google_folder_iam_member" "masthead_dataplex_folder_roles" {
  for_each = {
    for pair in flatten([
      for folder_id in var.monitored_folder_ids : [
        for role in local.dataplex_roles : {
          folder_id = folder_id
          role      = role
          key       = "${folder_id}-${role}"
        }
      ]
    ]) : pair.key => pair
  }

  folder = each.value.folder_id
  role   = each.value.role
  member = "serviceAccount:${var.masthead_service_accounts.dataplex_sa}"
}

# IAM: Grant Masthead service account required Dataplex roles at project level
resource "google_project_iam_member" "masthead_dataplex_project_roles" {
  for_each = {
    for pair in flatten([
      for project_id in local.iam_target_projects : [
        for role in local.dataplex_roles : {
          project_id = project_id
          role       = role
          key        = "${project_id}-${role}"
        }
      ]
    ]) : pair.key => pair
  }

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${var.masthead_service_accounts.dataplex_sa}"
}
