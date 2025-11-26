# Shared logging infrastructure module
# Creates Pub/Sub topics, subscriptions, and logging sinks
# Supports both folder-level and project-level configurations

locals {
  # Normalize folder ID format - ensure all have "folders/" prefix
  normalized_folder_ids = [
    for folder_id in var.monitored_folder_ids :
    can(regex("^folders/", folder_id)) ? folder_id : "folders/${folder_id}"
  ]

  # Determine if we're operating at folder or project level
  is_folder_level  = length(var.monitored_folder_ids) > 0
  is_project_level = length(var.monitored_project_ids) > 0

  # Common labels
  common_labels = merge(var.labels, {
    component = var.component_name
  })
}

# Enable Pub/Sub API in the deployment project
resource "google_project_service" "pubsub_api" {
  count = var.enable_apis ? 1 : 0

  project = var.pubsub_project_id
  service = "pubsub.googleapis.com"

  disable_on_destroy         = false
  disable_dependent_services = false
}

# Enable IAM and Logging APIs in monitored projects (where sinks are created)
resource "google_project_service" "monitored_project_apis" {
  for_each = var.enable_apis ? toset(flatten([
    for project_id in var.monitored_project_ids : [
      "${project_id}:iam.googleapis.com",
      "${project_id}:logging.googleapis.com"
    ]
  ])) : toset([])

  project = split(":", each.value)[0]
  service = split(":", each.value)[1]

  disable_on_destroy         = false
  disable_dependent_services = false
}

# Create Pub/Sub topic in the deployment project
resource "google_pubsub_topic" "logs_topic" {
  depends_on = [google_project_service.pubsub_api]

  project = var.pubsub_project_id
  name    = var.topic_name

  labels = local.common_labels
}

# Create Pub/Sub subscription in the deployment project
resource "google_pubsub_subscription" "logs_subscription" {
  project                    = var.pubsub_project_id
  name                       = var.subscription_name
  topic                      = google_pubsub_topic.logs_topic.id
  message_retention_duration = "86400s" # 24 hours
  ack_deadline_seconds       = 60

  labels = local.common_labels

  # Prevent subscription from expiring
  expiration_policy {
    ttl = ""
  }
}

# Create folder-level logging sinks (for each monitored folder)
resource "google_logging_folder_sink" "folder_sinks" {
  for_each = toset(local.normalized_folder_ids)

  folder      = each.value
  name        = var.sink_name
  description = "Masthead Agent log sink for ${var.component_name} at folder level"
  destination = "pubsub.googleapis.com/${google_pubsub_topic.logs_topic.id}"

  filter = var.log_filter

  # Include children projects
  include_children = true
}

# Create project-level logging sinks (for each monitored project)
resource "google_logging_project_sink" "project_sinks" {
  for_each = toset(var.monitored_project_ids)

  project     = each.value
  name        = var.sink_name
  description = "Masthead Agent log sink for ${var.component_name} at project level"
  destination = "pubsub.googleapis.com/${google_pubsub_topic.logs_topic.id}"

  filter = var.log_filter

  unique_writer_identity = true
}

# Grant folder sink writer identities permission to publish to Pub/Sub topic
resource "google_pubsub_topic_iam_member" "folder_sinks_publisher" {
  for_each = google_logging_folder_sink.folder_sinks

  project = var.pubsub_project_id
  topic   = google_pubsub_topic.logs_topic.name
  role    = "roles/pubsub.publisher"
  member  = each.value.writer_identity
}

# Grant project sink writer identities permission to publish to Pub/Sub topic
resource "google_pubsub_topic_iam_member" "project_sinks_publisher" {
  for_each = google_logging_project_sink.project_sinks

  project = var.pubsub_project_id
  topic   = google_pubsub_topic.logs_topic.name
  role    = "roles/pubsub.publisher"
  member  = each.value.writer_identity
}

# Grant Masthead service account subscriber role on the subscription
resource "google_pubsub_subscription_iam_member" "masthead_subscription_subscriber" {
  project      = var.pubsub_project_id
  subscription = google_pubsub_subscription.logs_subscription.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${var.masthead_service_account}"
}
