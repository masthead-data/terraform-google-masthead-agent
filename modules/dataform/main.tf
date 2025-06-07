# Dataform module - handles logging and IAM for Dataform monitoring
# Note: Provider is configured at the root level

locals {
  resource_names = {
    topic        = "${var.resource_prefix}-dataform-topic"
    subscription = "${var.resource_prefix}-dataform-subscription"
    sink         = "${var.resource_prefix}-dataform-sink"
  }

  # Merge default labels with user-provided labels
  common_labels = merge(var.labels, {
    component = "dataform"
    service   = "masthead-agent"
  })
}

# Enable required Google Cloud APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "pubsub.googleapis.com",
    "logging.googleapis.com",
    "dataform.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy         = false
  disable_dependent_services = false
}

# Create Pub/Sub topic for Dataform audit logs
resource "google_pubsub_topic" "masthead_dataform_topic" {
  depends_on = [google_project_service.required_apis]

  project = var.project_id
  name    = local.resource_names.topic

  labels = local.common_labels
}

# Create Pub/Sub subscription for the agent to consume messages
resource "google_pubsub_subscription" "masthead_dataform_subscription" {
  project                    = var.project_id
  name                       = local.resource_names.subscription
  topic                      = google_pubsub_topic.masthead_dataform_topic.id
  message_retention_duration = "86400s" # 24 hours
  ack_deadline_seconds       = 60

  labels = local.common_labels

  # Prevent subscription from expiring
  expiration_policy {
    ttl = ""
  }
}

# Grant Masthead service account required permissions
resource "google_project_iam_member" "masthead_dataform_permissions" {
  for_each = toset([
    "roles/pubsub.subscriber",
    "roles/dataform.viewer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${var.masthead_service_accounts.dataform_sa}"
}

# Create logging sink to capture Dataform audit logs
resource "google_logging_project_sink" "masthead_dataform_sink" {
  depends_on = [google_project_service.required_apis]

  project     = var.project_id
  name        = local.resource_names.sink
  description = "Masthead Dataform log sink for audit logs"
  destination = "pubsub.googleapis.com/${google_pubsub_topic.masthead_dataform_topic.id}"

  # Enhanced filter for comprehensive Dataform monitoring
  filter = join(" OR ", [
    "protoPayload.serviceName=\"dataform.googleapis.com\"",
    "resource.type=\"dataform.googleapis.com/Repository\""
  ])

  unique_writer_identity = true
}

# Grant Cloud Logging service account permission to publish to Pub/Sub
resource "google_project_iam_member" "logging_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = google_logging_project_sink.masthead_dataform_sink.writer_identity
}
