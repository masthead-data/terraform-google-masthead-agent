# Dataform Module - IAM and Logging for Masthead Agent
# Supports both folder-level (organization) and project-level (project) configurations

locals {
  resource_names = {
    topic        = "masthead-dataform-topic"
    subscription = "masthead-dataform-subscription"
    sink         = "masthead-dataform-sink"
  }

  # Merge default labels with user-provided labels
  common_labels = merge(var.labels, {
    component = "dataform"
  })

  # Log filter for Dataform monitoring
  dataform_log_filter = <<-EOT
(
  protoPayload.serviceName="dataform.googleapis.com" OR
  resource.type="dataform.googleapis.com/Repository"
)
EOT

  # Determine if we're operating at folder or project level
  has_folders = length(var.monitored_folder_ids) > 0

  # Explicitly listed standalone projects always need project-level IAM bindings,
  # independent of whether folders are also monitored (they live outside the folders).
  iam_target_projects = var.monitored_project_ids
}

# Enable Dataform API in monitored projects
resource "google_project_service" "dataform_api" {
  for_each = var.enable_apis ? toset(var.monitored_project_ids) : toset([])

  project = each.value
  service = "dataform.googleapis.com"

  disable_on_destroy         = false
  disable_dependent_services = false
}

# Shared Logging Infrastructure (Pub/Sub + Sinks)
module "logging_infrastructure" {
  source = "../logging-infrastructure"

  pubsub_project_id        = var.pubsub_project_id
  monitored_folder_ids     = var.monitored_folder_ids
  monitored_project_ids    = var.monitored_project_ids
  component_name           = "dataform"
  topic_name               = local.resource_names.topic
  subscription_name        = local.resource_names.subscription
  sink_name                = local.resource_names.sink
  log_filter               = local.dataform_log_filter
  masthead_service_account = var.masthead_service_accounts.dataform_sa
  enable_apis              = var.enable_apis
  labels                   = local.common_labels
}

# IAM: Grant Masthead service account required Dataform roles at folder level
resource "google_folder_iam_member" "masthead_dataform_folder_roles" {
  for_each = {
    for pair in setproduct(var.monitored_folder_ids, ["roles/dataform.viewer"]) : "${pair[0]}-${pair[1]}" => {
      folder_id = pair[0]
      role      = pair[1]
    }
  }

  folder = each.value.folder_id
  role   = each.value.role
  member = "serviceAccount:${var.masthead_service_accounts.dataform_sa}"
}

# IAM: Grant Masthead service account required Dataform roles at project level
resource "google_project_iam_member" "masthead_dataform_project_roles" {
  for_each = {
    for pair in setproduct(local.iam_target_projects, ["roles/dataform.viewer"]) : "${pair[0]}-${pair[1]}" => {
      project_id = pair[0]
      role       = pair[1]
    }
  }

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${var.masthead_service_accounts.dataform_sa}"
}
