# Dataform module - handles logging and IAM for Dataform monitoring
# Note: Provider is configured at the root level

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
}

# Enable required Google Cloud APIs (optional)
resource "google_project_service" "required_apis" {
  for_each = var.enable_apis ? toset([
    "pubsub.googleapis.com",
    "logging.googleapis.com",
    "dataform.googleapis.com"
  ]) : toset([])

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

# Create logging sink to capture Dataform audit logs
resource "google_logging_project_sink" "masthead_dataform_sink" {
  depends_on = [google_project_service.required_apis]

  project     = var.project_id
  name        = local.resource_names.sink
  description = "Masthead Dataform log sink for audit logs"
  destination = "pubsub.googleapis.com/${google_pubsub_topic.masthead_dataform_topic.id}"

  # Enhanced filter for comprehensive Dataform monitoring
  filter = <<-EOT
(
  protoPayload.serviceName="dataform.googleapis.com" OR
  resource.type="dataform.googleapis.com/Repository"
)
EOT

  unique_writer_identity = true
}

# Grant Cloud Logging service account permission to publish to Pub/Sub topic
resource "google_pubsub_topic_iam_member" "logging_pubsub_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.masthead_dataform_topic.name
  role    = "roles/pubsub.publisher"
  member  = google_logging_project_sink.masthead_dataform_sink.writer_identity
}

# Grant Masthead service account subscriber role on the subscription
resource "google_pubsub_subscription_iam_member" "masthead_subscription_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.masthead_dataform_subscription.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${var.masthead_service_accounts.dataform_sa}"
}

# Grant Masthead service account required Dataform roles
resource "google_project_iam_member" "masthead_dataform_roles" {
  for_each = toset([
    "roles/dataform.viewer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${var.masthead_service_accounts.dataform_sa}"
}
