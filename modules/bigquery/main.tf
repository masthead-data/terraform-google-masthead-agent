# BigQuery Module - IAM and Logging for Masthead Agent
# Supports both folder-level (organization) and project-level (project) configurations

locals {
  resource_names = {
    topic        = "masthead-topic"
    subscription = "masthead-agent-subscription"
    sink         = "masthead-agent-sink"
  }

  # Merge default labels with user-provided labels
  common_labels = merge(var.labels, {
    component = "bigquery"
  })

  # Log filter for BigQuery monitoring
  bigquery_log_filter = <<-EOT
(
  protoPayload.methodName="google.cloud.bigquery.storage.v1.BigQueryWrite.AppendRows" OR
  protoPayload.methodName="google.cloud.bigquery.storage.v1.BigQueryWrite.ReadRows" OR
  protoPayload.methodName="google.cloud.bigquery.v2.JobService.InsertJob" OR
  protoPayload.methodName="google.cloud.bigquery.v2.JobService.Query" OR
  protoPayload.methodName="google.cloud.bigquery.v2.TableDataService.List" OR
  protoPayload.methodName="google.cloud.bigquery.v2.TableService.InsertTable"
) AND (
  resource.type="bigquery_table" OR
  resource.type="bigquery_dataset" OR
  resource.type="bigquery_project"
)
EOT

  # Determine if we're operating at folder or project level
  has_folders = length(var.monitored_folder_ids) > 0

  # Projects where IAM bindings need to be applied (only when not using folders)
  iam_target_projects = local.has_folders ? [] : var.monitored_project_ids
}

# Enable BigQuery API in monitored projects
resource "google_project_service" "bigquery_api" {
  for_each = var.enable_apis ? toset(var.monitored_project_ids) : toset([])

  project = each.value
  service = "bigquery.googleapis.com"

  disable_on_destroy         = false
  disable_dependent_services = false
}

# Shared Logging Infrastructure (Pub/Sub + Sinks)
module "logging_infrastructure" {
  source = "../logging-infrastructure"

  pubsub_project_id        = var.pubsub_project_id
  monitored_folder_ids     = var.monitored_folder_ids
  monitored_project_ids    = var.monitored_project_ids
  component_name           = "bigquery"
  topic_name               = local.resource_names.topic
  subscription_name        = local.resource_names.subscription
  sink_name                = local.resource_names.sink
  log_filter               = local.bigquery_log_filter
  masthead_service_account = var.masthead_service_accounts.bigquery_sa
  enable_apis              = var.enable_apis
  labels                   = local.common_labels
}

# IAM: Grant Masthead service account required BigQuery roles at folder level
resource "google_folder_iam_member" "masthead_bigquery_folder_roles" {
  for_each = {
    for pair in flatten([
      for folder_id in var.monitored_folder_ids : [
        for role in ["roles/bigquery.metadataViewer", "roles/bigquery.resourceViewer"] : {
          folder_id = folder_id
          role      = role
          key       = "${folder_id}-${role}"
        }
      ]
    ]) : pair.key => pair
  }

  folder = each.value.folder_id
  role   = each.value.role
  member = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}

# IAM: Grant Masthead service account required BigQuery roles at project level
resource "google_project_iam_member" "masthead_bigquery_project_roles" {
  for_each = {
    for pair in flatten([
      for project_id in local.iam_target_projects : [
        for role in ["roles/bigquery.metadataViewer", "roles/bigquery.resourceViewer"] : {
          project_id = project_id
          role       = role
          key        = "${project_id}-${role}"
        }
      ]
    ]) : pair.key => pair
  }

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${var.masthead_service_accounts.bigquery_sa}"
}

# IAM: Grant Masthead retro service account Private Log Viewer role at folder level
resource "google_folder_iam_member" "masthead_privatelogviewer_folder_role" {
  for_each = var.enable_privatelogviewer_role ? toset(var.monitored_folder_ids) : toset([])

  folder = each.value
  role   = "roles/logging.privateLogViewer"
  member = "serviceAccount:${var.masthead_service_accounts.retro_sa}"
}

# IAM: Grant Masthead retro service account Private Log Viewer role at project level
resource "google_project_iam_member" "masthead_privatelogviewer_project_role" {
  for_each = var.enable_privatelogviewer_role && !local.has_folders ? toset(local.iam_target_projects) : toset([])

  project = each.value
  role    = "roles/logging.privateLogViewer"
  member  = "serviceAccount:${var.masthead_service_accounts.retro_sa}"
}
