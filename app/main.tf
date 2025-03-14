variable "project_id" {
  type        = string
  description = "The project id where to create resources. IAM & Admin -> Settings -> Project ID"
}

variable "project_number" {
  type        = string
  description = "The project number where to create resources. IAM & Admin -> Settings -> Project number"
}

provider "google" {
  project = var.project_id
}

#1. Enable required services in the client GCP project.
resource "google_project_service" "enable_services" {
  for_each = toset(["iam.googleapis.com", "logging.googleapis.com"])

  project = var.project_id
  service = each.value

  disable_dependent_services = true
}

resource "time_sleep" "wait_30_seconds_to_enable_logging_service" {
  depends_on = [google_project_service.enable_services["logging.googleapis.com"]]

  create_duration = "30s"
}

#2. Create Log Sink.
resource "google_logging_project_sink" "masthead_sink" {
  depends_on = [google_pubsub_topic.masthead_topic,time_sleep.wait_30_seconds_to_enable_logging_service]
  name        = "masthead-agent-sink"
  description = "Masthead Agent log sink"
  destination = "logging.googleapis.com/projects/masthead-prod/locations/global/buckets/${var.project_id}"
  filter      = "protoPayload.methodName=\"google.cloud.bigquery.storage.v1.BigQueryWrite.AppendRows\" OR \"google.cloud.bigquery.v2.JobService.InsertJob\" OR \"google.cloud.bigquery.v2.TableService.InsertTable\" OR \"google.cloud.bigquery.v2.JobService.Query\" resource.type =\"bigquery_table\" OR resource.type =\"bigquery_dataset\" OR resource.type =\"bigquery_project\""
  project     = var.project_number
  unique_writer_identity = false
}

#3. Grant Masthead service account required roles: BigQuery Metadata Viewer, BigQuery Resource Viewer, Private Log Viewer.
resource "google_project_iam_member" "grant-masthead-pubsub-subscriber-role" {
  for_each = toset(["roles/bigquery.metadataViewer", "roles/bigquery.resourceViewer", "roles/logging.privateLogViewer"])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:masthead-data@masthead-prod.iam.gserviceaccount.com"
}
