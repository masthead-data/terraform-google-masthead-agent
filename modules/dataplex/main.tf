# Dataplex module - handles logging and IAM for Dataplex monitoring
# Note: Provider is configured at the root level

locals {
  resource_names = {
    topic          = "masthead-dataplex-topic"
    subscription   = "masthead-dataplex-subscription"
    sink           = "masthead-dataplex-sink"
    custom_role_id = "masthead_dataplex_locations"
  }

  # Merge default labels with user-provided labels
  common_labels = merge(var.labels, {
    component = "dataplex"
    service   = "masthead-agent"
  })
}

# Enable required Google Cloud APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "pubsub.googleapis.com",
    "logging.googleapis.com",
    "dataplex.googleapis.com",
    "bigquery.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy         = false
  disable_dependent_services = false
}

# Create Pub/Sub topic for Dataplex audit logs
resource "google_pubsub_topic" "masthead_dataplex_topic" {
  depends_on = [google_project_service.required_apis]

  project = var.project_id
  name    = local.resource_names.topic

  labels = local.common_labels
}

# Create Pub/Sub subscription for the agent to consume messages
resource "google_pubsub_subscription" "masthead_dataplex_subscription" {
  project                    = var.project_id
  name                       = local.resource_names.subscription
  topic                      = google_pubsub_topic.masthead_dataplex_topic.id
  message_retention_duration = "86400s" # 24 hours
  ack_deadline_seconds       = 60

  labels = local.common_labels

  # Prevent subscription from expiring
  expiration_policy {
    ttl = ""
  }
}

# Create logging sink to capture Dataplex audit logs
resource "google_logging_project_sink" "masthead_dataplex_sink" {
  depends_on = [google_project_service.required_apis]

  project     = var.project_id
  name        = local.resource_names.sink
  description = "Masthead Dataplex log sink for audit logs"
  destination = "pubsub.googleapis.com/${google_pubsub_topic.masthead_dataplex_topic.id}"

  # Enhanced filter for comprehensive Dataplex monitoring
  filter = <<-EOT
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

  unique_writer_identity = true
}

# Grant Cloud Logging service account permission to publish to Pub/Sub topic
resource "google_pubsub_topic_iam_member" "logging_pubsub_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.masthead_dataplex_topic.name
  role    = "roles/pubsub.publisher"
  member  = google_logging_project_sink.masthead_dataplex_sink.writer_identity
}

# Grant Masthead service account subscriber permission on the subscription
resource "google_pubsub_subscription_iam_member" "masthead_subscription_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.masthead_dataplex_subscription.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${var.masthead_service_accounts.dataplex_sa}"
}

# Create custom IAM role for Dataplex locations access
resource "google_project_iam_custom_role" "masthead_dataplex_locations" {
  depends_on = [google_project_service.required_apis]

  project     = var.project_id
  role_id     = local.resource_names.custom_role_id
  title       = "Dataplex Locations (Masthead Data)"
  description = "Custom role for Dataplex locations reader access for Masthead Data"
  stage       = "GA"

  permissions = [
    "dataplex.locations.get",
    "dataplex.locations.list"
  ]
}

# Grant Masthead service account required Dataplex permissions
resource "google_project_iam_member" "masthead_dataplex_permissions" {
  for_each = toset([
    "roles/dataplex.dataScanAdmin",
    "roles/dataplex.storageDataReader",
    "roles/bigquery.jobUser",
    google_project_iam_custom_role.masthead_dataplex_locations.id
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${var.masthead_service_accounts.dataplex_sa}"
}
